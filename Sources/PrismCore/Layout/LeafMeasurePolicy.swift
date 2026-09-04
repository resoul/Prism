import Foundation
import CoreText
import CoreGraphics

/// Contract for calculating intrinsic content dimensions of leaf nodes during the layout measure pass.
public protocol MeasurePolicy: Sendable {
    func measure(style: LayoutStyle, constraint: SizeConstraint) -> MeasuredSize
}

// MARK: - Text Measurement

/// Leaf measure policy for text nodes leveraging CoreText font metrics.
public struct TextMeasurePolicy: MeasurePolicy {
    public let text: String
    public let fontSize: Double
    public let fontName: String
    public let lineLimit: Int?
    public let customLineHeight: Double?

    public init(
        text: String,
        fontSize: Double = 16,
        fontName: String = "System",
        lineLimit: Int? = nil,
        customLineHeight: Double? = nil
    ) {
        self.text = text
        self.fontSize = max(1.0, fontSize)
        self.fontName = fontName
        self.lineLimit = lineLimit.map { max(1, $0) }
        self.customLineHeight = customLineHeight.map { max(1.0, $0) }
    }

    public func measure(style: LayoutStyle, constraint: SizeConstraint) -> MeasuredSize {
        if text.isEmpty {
            return .zero
        }

        // Resolve font
        let ctFont: CTFont
        if fontName == "System" || fontName.isEmpty {
            ctFont = CTFontCreateUIFontForLanguage(.system, CGFloat(fontSize), nil)
                ?? CTFontCreateWithName("Helvetica" as CFString, CGFloat(fontSize), nil)
        } else {
            ctFont = CTFontCreateWithName(fontName as CFString, CGFloat(fontSize), nil)
        }

        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): ctFont
        ]

        if let customLineHeight {
            var minLineHeight = CGFloat(customLineHeight)
            var maxLineHeight = CGFloat(customLineHeight)
            withUnsafePointer(to: &minLineHeight) { minPtr in
                withUnsafePointer(to: &maxLineHeight) { maxPtr in
                    let settings: [CTParagraphStyleSetting] = [
                        CTParagraphStyleSetting(
                            spec: .minimumLineHeight,
                            valueSize: MemoryLayout<CGFloat>.size,
                            value: minPtr
                        ),
                        CTParagraphStyleSetting(
                            spec: .maximumLineHeight,
                            valueSize: MemoryLayout<CGFloat>.size,
                            value: maxPtr
                        )
                    ]
                    let paragraphStyle = CTParagraphStyleCreate(settings, settings.count)
                    attributes[NSAttributedString.Key(kCTParagraphStyleAttributeName as String)] = paragraphStyle
                }
            }
        }

        let attrString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)

        let maxAvailableWidth = constraint.width.maxAvailable ?? Double.greatestFiniteMagnitude
        let boundingWidth = CGFloat(max(1.0, maxAvailableWidth))

        // Measure suggested size using CoreText
        let targetSize = CGSize(width: boundingWidth, height: CGFloat.greatestFiniteMagnitude)
        var fitRange = CFRangeMake(0, 0)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attrString.length),
            nil,
            targetSize,
            &fitRange
        )

        let resolvedWidth = ceil(Double(suggestedSize.width))
        var resolvedHeight = ceil(Double(suggestedSize.height))

        // Apply line limit if specified
        if let lineLimit {
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: boundingWidth, height: CGFloat.greatestFiniteMagnitude))
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
            let lines = CTFrameGetLines(frame) as? [CTLine] ?? []

            if lines.count > lineLimit {
                // Calculate height for limited number of lines
                let lineSpacing = customLineHeight ?? Double(CTFontGetAscent(ctFont) + CTFontGetDescent(ctFont) + CTFontGetLeading(ctFont))
                resolvedHeight = ceil(Double(lineLimit) * lineSpacing)
            }
        }

        let intrinsic = MeasuredSize(width: resolvedWidth, height: resolvedHeight)
        return ConstraintResolver.resolveSize(style: style, constraint: constraint, intrinsic: intrinsic)
    }
}

// MARK: - Shape Measurement

/// Leaf measure policy for vector shape primitives (Rectangle, Circle).
public struct ShapeMeasurePolicy: MeasurePolicy {
    public enum ShapeType: Sendable {
        case rectangle
        case circle
    }

    public let shapeType: ShapeType
    public let defaultDiameter: Double

    public init(shapeType: ShapeType, defaultDiameter: Double = 0) {
        self.shapeType = shapeType
        self.defaultDiameter = max(0, defaultDiameter)
    }

    public func measure(style: LayoutStyle, constraint: SizeConstraint) -> MeasuredSize {
        let intrinsic = MeasuredSize(width: defaultDiameter, height: defaultDiameter)
        return ConstraintResolver.resolveSize(style: style, constraint: constraint, intrinsic: intrinsic)
    }
}

// MARK: - Spacer Measurement

/// Leaf measure policy for flexible spacing elements.
public struct SpacerMeasurePolicy: MeasurePolicy {
    public let minLength: Double
    public let axis: LayoutAxis

    public init(minLength: Double = 0, axis: LayoutAxis = .vertical) {
        self.minLength = max(0, minLength)
        self.axis = axis
    }

    public func measure(style: LayoutStyle, constraint: SizeConstraint) -> MeasuredSize {
        switch axis {
        case .vertical:
            let resolvedH = ConstraintResolver.resolve(
                sizeValue: .fill,
                constraint: constraint.height,
                intrinsic: minLength,
                minBound: minLength
            )
            return MeasuredSize(width: 0, height: resolvedH)

        case .horizontal:
            let resolvedW = ConstraintResolver.resolve(
                sizeValue: .fill,
                constraint: constraint.width,
                intrinsic: minLength,
                minBound: minLength
            )
            return MeasuredSize(width: resolvedW, height: 0)
        }
    }
}
