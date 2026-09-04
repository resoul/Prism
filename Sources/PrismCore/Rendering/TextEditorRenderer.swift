import Foundation
import QuartzCore
import CoreText
import CoreGraphics

/// Dedicated `LayerRenderer` visualizing an interactive text editor (Input / Textarea).
/// Manages CoreText typography, selection highlight, animated blinking caret,
/// placeholder text, and horizontal/vertical scroll offsets.
@MainActor
public final class TextEditorRenderer: LayerRenderer {
    public let elementID: ElementID
    public let rootLayer: CALayer

    private let contentLayer = CALayer()
    private let textLayer = CATextLayer()
    private let placeholderLayer = CATextLayer()
    private let selectionLayer = CAShapeLayer()
    private let caretLayer = CALayer()

    private var isFocused: Bool = false
    private var isBlinking: Bool = false
    private var scrollOffset: CGPoint = .zero

    public init(elementID: ElementID) {
        self.elementID = elementID

        let root = CALayer()
        root.name = "TextEditorRoot[\(elementID)]"
        root.masksToBounds = true
        self.rootLayer = root

        contentLayer.name = "TextEditorContent[\(elementID)]"
        contentLayer.masksToBounds = false

        selectionLayer.name = "TextEditorSelection[\(elementID)]"
        selectionLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.15, 0.45, 0.95, 0.3])

        textLayer.name = "TextEditorText[\(elementID)]"
        textLayer.contentsScale = 2.0

        placeholderLayer.name = "TextEditorPlaceholder[\(elementID)]"
        placeholderLayer.contentsScale = 2.0

        caretLayer.name = "TextEditorCaret[\(elementID)]"
        caretLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.1, 0.1, 0.1, 1.0])
        caretLayer.opacity = 0.0

        contentLayer.addSublayer(selectionLayer)
        contentLayer.addSublayer(placeholderLayer)
        contentLayer.addSublayer(textLayer)
        contentLayer.addSublayer(caretLayer)

        root.addSublayer(contentLayer)
    }

    public func update(element: RenderElement, frame: LayoutFrame, context: RenderContext) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            rootLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            rootLayer.position = CGPoint(
                x: frame.origin.x + frame.width / 2.0,
                y: frame.origin.y + frame.height / 2.0
            )

            let style = element.resolvedStyle
            rootLayer.opacity = Float(style.opacity)
            rootLayer.zPosition = CGFloat(style.zIndex)

            let isMultiline: Bool = {
                if case .textEditor(_, let multi) = element.kind {
                    return multi
                }
                return false
            }()

            let mode: TextInputMode = {
                if case .textEditor(let m, _) = element.kind {
                    return m
                }
                return .text
            }()

            // Styling attributes
            let textValue = element.props.custom["text"] ?? ""
            let placeholderValue = element.props.custom["placeholder"] ?? ""
            let focusedStr = element.props.custom["isFocused"]
            let currentlyFocused = (focusedStr == "true")
            self.isFocused = currentlyFocused

            let paddingLeft: CGFloat = 8.0
            let paddingTop: CGFloat = isMultiline ? 8.0 : 0.0
            let contentWidth = max(0, frame.width - paddingLeft * 2)
            let contentHeight = max(0, frame.height - paddingTop * 2)

            let fontSize: CGFloat = 14.0
            let font = CTFontCreateWithName("HelveticaNeue" as CFString, fontSize, nil)

            // Password masking
            let displayText = mode.isSecure ? TextInputMode.mask(text: textValue) : textValue

            // Typography & Metrics
            let metrics = TextEditorMetrics(
                text: displayText,
                font: font,
                bounds: CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight),
                isMultiline: isMultiline
            )

            // Caret & Selection from props
            let caretPos = Int(element.props.custom["caretPosition"] ?? "") ?? displayText.count
            let selStart = Int(element.props.custom["selectionStart"] ?? "") ?? caretPos
            let selEnd = Int(element.props.custom["selectionEnd"] ?? "") ?? caretPos
            let selectionRange = NSRange(location: min(selStart, selEnd), length: abs(selEnd - selStart))

            // Compute Caret Rect
            let caretRect = metrics.caretRect(for: caretPos)

            // Scroll position tracking: keep caret visible
            updateScrollOffset(caretRect: caretRect, viewportSize: CGSize(width: contentWidth, height: contentHeight), isMultiline: isMultiline)

            contentLayer.frame = CGRect(
                x: paddingLeft - scrollOffset.x,
                y: paddingTop - scrollOffset.y,
                width: max(contentWidth, metrics.contentSize.width),
                height: max(contentHeight, metrics.contentSize.height)
            )

            // Setup Text Layer
            textLayer.frame = CGRect(origin: .zero, size: contentLayer.bounds.size)
            textLayer.contentsScale = CGFloat(context.scaleFactor)
            textLayer.font = font
            textLayer.fontSize = fontSize
            textLayer.string = displayText
            textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.1, 0.1, 0.1, 1.0])
            textLayer.alignmentMode = .left
            textLayer.isWrapped = isMultiline

            // Setup Placeholder Layer
            if displayText.isEmpty && !placeholderValue.isEmpty {
                placeholderLayer.isHidden = false
                placeholderLayer.frame = CGRect(origin: .zero, size: contentLayer.bounds.size)
                placeholderLayer.contentsScale = CGFloat(context.scaleFactor)
                placeholderLayer.font = font
                placeholderLayer.fontSize = fontSize
                placeholderLayer.string = placeholderValue
                placeholderLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.6, 0.6, 0.6, 1.0])
                placeholderLayer.alignmentMode = .left
                placeholderLayer.isWrapped = isMultiline
            } else {
                placeholderLayer.isHidden = true
            }

            // Setup Selection Layer
            if selectionRange.length > 0 {
                selectionLayer.isHidden = false
                let rects = metrics.selectionRects(for: selectionRange)
                let path = CGMutablePath()
                for r in rects {
                    path.addRect(r)
                }
                selectionLayer.path = path
            } else {
                selectionLayer.isHidden = true
                selectionLayer.path = nil
            }

            // Setup Caret Layer & Blinking
            caretLayer.frame = caretRect
            caretLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.15, 0.45, 0.95, 1.0])

            if currentlyFocused {
                caretLayer.isHidden = (selectionRange.length > 0)
                startBlinkingIfNeeded()
            } else {
                stopBlinking()
            }
        }
    }

    public func destroy() {
        stopBlinking()
        rootLayer.removeFromSuperlayer()
    }

    // MARK: - Caret Blinking Animation

    private func startBlinkingIfNeeded() {
        guard !isBlinking else { return }
        isBlinking = true

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [1.0, 1.0, 0.0, 0.0, 1.0]
        animation.keyTimes = [0.0, 0.45, 0.5, 0.95, 1.0]
        animation.duration = 1.0
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        caretLayer.add(animation, forKey: "caretBlink")
    }

    private func stopBlinking() {
        guard isBlinking || caretLayer.animation(forKey: "caretBlink") != nil else {
            caretLayer.opacity = 0.0
            caretLayer.isHidden = true
            return
        }
        isBlinking = false
        caretLayer.removeAnimation(forKey: "caretBlink")
        caretLayer.opacity = 0.0
        caretLayer.isHidden = true
    }

    // MARK: - Viewport Scrolling

    private func updateScrollOffset(caretRect: CGRect, viewportSize: CGSize, isMultiline: Bool) {
        if isMultiline {
            let caretBottom = caretRect.maxY
            let caretTop = caretRect.minY

            if caretBottom > (scrollOffset.y + viewportSize.height) {
                scrollOffset.y = caretBottom - viewportSize.height
            } else if caretTop < scrollOffset.y {
                scrollOffset.y = caretTop
            }
            scrollOffset.y = max(0, scrollOffset.y)
            scrollOffset.x = 0
        } else {
            let caretRight = caretRect.maxX
            let caretLeft = caretRect.minX

            if caretRight > (scrollOffset.x + viewportSize.width) {
                scrollOffset.x = caretRight - viewportSize.width + 16.0
            } else if caretLeft < scrollOffset.x {
                scrollOffset.x = max(0, caretLeft - 16.0)
            }
            scrollOffset.x = max(0, scrollOffset.x)
            scrollOffset.y = 0
        }
    }
}
