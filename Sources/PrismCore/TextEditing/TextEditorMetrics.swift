import Foundation
import CoreText
import CoreGraphics

/// Helper computing typographic layout metrics, character rects, line fragments,
/// and hit-testing (point to index, index to caret rect) using CoreText.
@MainActor
public final class TextEditorMetrics {

    public struct LineFragment {
        public let lineIndex: Int
        public let stringRange: NSRange
        public let origin: CGPoint
        public let ascent: CGFloat
        public let descent: CGFloat
        public let leading: CGFloat
        public let width: CGFloat

        public var height: CGFloat {
            ascent + descent + leading
        }

        public var bounds: CGRect {
            CGRect(x: origin.x, y: origin.y - descent, width: width, height: height)
        }
    }

    public let text: String
    public let font: CTFont
    public let bounds: CGRect
    public let isMultiline: Bool

    private var framesetter: CTFramesetter?
    private var ctFrame: CTFrame?
    private var lineFragments: [LineFragment] = []

    public init(text: String, font: CTFont, bounds: CGRect, isMultiline: Bool = false) {
        self.text = text
        self.font = font
        self.bounds = bounds
        self.isMultiline = isMultiline
        computeLayout()
    }

    private func computeLayout() {
        let attrString = NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font
            ]
        )

        let fs = CTFramesetterCreateWithAttributedString(attrString)
        self.framesetter = fs

        let path = CGMutablePath()
        let maxDim: CGFloat = isMultiline ? bounds.width : 100000.0
        let maxHeight: CGFloat = isMultiline ? 100000.0 : bounds.height
        path.addRect(CGRect(x: 0, y: 0, width: maxDim, height: maxHeight))

        let frame = CTFramesetterCreateFrame(fs, CFRangeMake(0, attrString.length), path, nil)
        self.ctFrame = frame

        guard let lines = CTFrameGetLines(frame) as? [CTLine] else { return }
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, lines.count), &origins)

        var fragments: [LineFragment] = []
        for (idx, line) in lines.enumerated() {
            let lineRange = CTLineGetStringRange(line)
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let lineWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

            let origin = origins[idx]
            fragments.append(LineFragment(
                lineIndex: idx,
                stringRange: NSRange(location: lineRange.location, length: lineRange.length),
                origin: origin,
                ascent: ascent,
                descent: descent,
                leading: leading,
                width: lineWidth
            ))
        }

        self.lineFragments = fragments
    }

    /// Computes the caret rectangle for a character index (UTF-16 offset).
    public func caretRect(for utf16Offset: Int) -> CGRect {
        let fontSize = CTFontGetSize(font)
        let caretWidth: CGFloat = 2.0
        let defaultHeight = fontSize * 1.2

        if lineFragments.isEmpty || text.isEmpty {
            return CGRect(x: 0, y: (bounds.height - defaultHeight) / 2.0, width: caretWidth, height: defaultHeight)
        }

        guard let frame = ctFrame, let lines = CTFrameGetLines(frame) as? [CTLine] else {
            return CGRect(x: 0, y: 0, width: caretWidth, height: defaultHeight)
        }

        // Find line containing or ending at this offset
        var targetLineIdx = lineFragments.count - 1
        for (idx, frag) in lineFragments.enumerated() {
            if utf16Offset <= (frag.stringRange.location + frag.stringRange.length) {
                targetLineIdx = idx
                break
            }
        }

        let frag = lineFragments[targetLineIdx]
        let line = lines[targetLineIdx]

        var primaryOffset: CGFloat = 0
        CTLineGetOffsetForStringIndex(line, utf16Offset, &primaryOffset)

        let x = frag.origin.x + primaryOffset
        let y = isMultiline ? frag.origin.y - frag.descent : (bounds.height - frag.height) / 2.0

        return CGRect(x: x, y: y, width: caretWidth, height: frag.height)
    }

    /// Computes highlight rectangles covering the specified UTF-16 character range.
    public func selectionRects(for nsRange: NSRange) -> [CGRect] {
        guard nsRange.length > 0, let frame = ctFrame, let lines = CTFrameGetLines(frame) as? [CTLine] else {
            return []
        }

        var rects: [CGRect] = []
        let rangeEnd = nsRange.location + nsRange.length

        for (idx, frag) in lineFragments.enumerated() {
            let fragEnd = frag.stringRange.location + frag.stringRange.length
            let overlapStart = max(nsRange.location, frag.stringRange.location)
            let overlapEnd = min(rangeEnd, fragEnd)

            if overlapStart < overlapEnd {
                let line = lines[idx]
                var startOffset: CGFloat = 0
                var endOffset: CGFloat = 0
                CTLineGetOffsetForStringIndex(line, overlapStart, &startOffset)
                CTLineGetOffsetForStringIndex(line, overlapEnd, &endOffset)

                let minX = min(startOffset, endOffset)
                let maxX = max(startOffset, endOffset)

                let y = isMultiline ? frag.origin.y - frag.descent : (bounds.height - frag.height) / 2.0
                rects.append(CGRect(
                    x: frag.origin.x + minX,
                    y: y,
                    width: maxX - minX,
                    height: frag.height
                ))
            }
        }

        return rects
    }

    /// Converts a local coordinate point to the nearest UTF-16 character index.
    public func characterIndex(at point: CGPoint) -> Int {
        if lineFragments.isEmpty || text.isEmpty { return 0 }
        guard let frame = ctFrame, let lines = CTFrameGetLines(frame) as? [CTLine] else { return 0 }

        // Find matching line fragment vertically
        var targetIdx = 0
        for (idx, frag) in lineFragments.enumerated() {
            if point.y >= (frag.origin.y - frag.descent) {
                targetIdx = idx
            }
        }

        let frag = lineFragments[targetIdx]
        let line = lines[targetIdx]
        let lineRelativePoint = CGPoint(x: point.x - frag.origin.x, y: 0)

        let index = CTLineGetStringIndexForPosition(line, lineRelativePoint)
        if index == kCFNotFound {
            return frag.stringRange.location
        }
        return index
    }

    /// Total content size required for the rendered text.
    public var contentSize: CGSize {
        if lineFragments.isEmpty {
            let fontSize = CTFontGetSize(font)
            return CGSize(width: 0, height: fontSize * 1.2)
        }
        let maxWidth = lineFragments.map(\.width).max() ?? 0
        let totalHeight = lineFragments.map(\.height).reduce(0, +)
        return CGSize(width: maxWidth, height: totalHeight)
    }
}
