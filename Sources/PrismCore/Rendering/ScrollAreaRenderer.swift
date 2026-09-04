import Foundation
import QuartzCore
import CoreGraphics

/// Renderer for scroll area viewports managing content clipping, translation transform,
/// and responsive scroll indicator indicators.
@MainActor
public final class ScrollAreaRenderer: LayerRenderer {
    public let elementID: ElementID
    public let containerLayer: CALayer
    public let contentLayer: CALayer
    public let verticalIndicatorLayer: CALayer
    public let horizontalIndicatorLayer: CALayer

    public var rootLayer: CALayer { containerLayer }

    public init(elementID: ElementID) {
        self.elementID = elementID

        let container = CALayer()
        container.name = "ScrollArea[\(elementID)]"
        container.masksToBounds = true
        self.containerLayer = container

        let content = CALayer()
        content.name = "ScrollContent[\(elementID)]"
        container.addSublayer(content)
        self.contentLayer = content

        let vIndicator = CALayer()
        vIndicator.name = "VScrollIndicator"
        vIndicator.backgroundColor = CGColor(gray: 0.5, alpha: 0.5)
        vIndicator.cornerRadius = 2.0
        vIndicator.opacity = 0.0
        container.addSublayer(vIndicator)
        self.verticalIndicatorLayer = vIndicator

        let hIndicator = CALayer()
        hIndicator.name = "HScrollIndicator"
        hIndicator.backgroundColor = CGColor(gray: 0.5, alpha: 0.5)
        hIndicator.cornerRadius = 2.0
        hIndicator.opacity = 0.0
        container.addSublayer(hIndicator)
        self.horizontalIndicatorLayer = hIndicator
    }

    public func update(element: RenderElement, frame: LayoutFrame, context: RenderContext) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            containerLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            containerLayer.position = CGPoint(
                x: frame.origin.x + frame.width / 2.0,
                y: frame.origin.y + frame.height / 2.0
            )

            // Parse scroll offsets
            let offsetX = Double(element.props.custom["scrollOffsetX"] ?? "0") ?? 0.0
            let offsetY = Double(element.props.custom["scrollOffsetY"] ?? "0") ?? 0.0
            let contentW = Double(element.props.custom["contentWidth"] ?? "\(frame.width)") ?? frame.width
            let contentH = Double(element.props.custom["contentHeight"] ?? "\(frame.height)") ?? frame.height

            // Translate content layer
            contentLayer.bounds = CGRect(x: 0, y: 0, width: contentW, height: contentH)
            contentLayer.position = CGPoint(x: contentW / 2.0, y: contentH / 2.0)
            contentLayer.transform = CATransform3DMakeTranslation(CGFloat(-offsetX), CGFloat(-offsetY), 0)

            // Update vertical scrollbar indicator
            if contentH > frame.height && frame.height > 0 {
                let indicatorHeight = max(20.0, frame.height * (frame.height / contentH))
                let maxScrollY = contentH - frame.height
                let scrollProgress = maxScrollY > 0 ? min(1.0, max(0.0, offsetY / maxScrollY)) : 0.0
                let indicatorY = scrollProgress * (frame.height - indicatorHeight)

                verticalIndicatorLayer.bounds = CGRect(x: 0, y: 0, width: 4.0, height: indicatorHeight)
                verticalIndicatorLayer.position = CGPoint(
                    x: frame.width - 4.0,
                    y: indicatorY + indicatorHeight / 2.0
                )
                verticalIndicatorLayer.opacity = 0.8
            } else {
                verticalIndicatorLayer.opacity = 0.0
            }

            // Update horizontal scrollbar indicator
            if contentW > frame.width && frame.width > 0 {
                let indicatorWidth = max(20.0, frame.width * (frame.width / contentW))
                let maxScrollX = contentW - frame.width
                let scrollProgress = maxScrollX > 0 ? min(1.0, max(0.0, offsetX / maxScrollX)) : 0.0
                let indicatorX = scrollProgress * (frame.width - indicatorWidth)

                horizontalIndicatorLayer.bounds = CGRect(x: 0, y: 0, width: indicatorWidth, height: 4.0)
                horizontalIndicatorLayer.position = CGPoint(
                    x: indicatorX + indicatorWidth / 2.0,
                    y: frame.height - 4.0
                )
                horizontalIndicatorLayer.opacity = 0.8
            } else {
                horizontalIndicatorLayer.opacity = 0.0
            }
        }
    }

    public func destroy() {
        containerLayer.removeFromSuperlayer()
    }
}
