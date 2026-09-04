import Foundation
import QuartzCore

/// Renderer for vector shapes: Rectangle and Circle.
@MainActor
public final class ShapeRenderer: LayerRenderer {
    public let elementID: ElementID
    public let rootLayer: CALayer

    public init(elementID: ElementID) {
        self.elementID = elementID
        let layer = CALayer()
        layer.name = "ShapeLayer[\(elementID)]"
        self.rootLayer = layer
    }

    public func update(element: RenderElement, frame: LayoutFrame, context: RenderContext) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            rootLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            rootLayer.position = CGPoint(
                x: frame.origin.x + frame.width / 2.0,
                y: frame.origin.y + frame.height / 2.0
            )

            let style = element.resolvedStyle

            // Shape-specific geometry
            switch element.kind {
            case .shape(let shapeKind):
                switch shapeKind {
                case .rectangle(let cornerRadius):
                    rootLayer.cornerRadius = CGFloat(cornerRadius)
                case .circle:
                    rootLayer.cornerRadius = CGFloat(min(frame.width, frame.height) / 2.0)
                }
            default:
                break
            }

            // Background & visual styling
            if let bg = style.background {
                rootLayer.backgroundColor = bg.cgColor
            } else {
                rootLayer.backgroundColor = nil
            }

            rootLayer.opacity = Float(style.opacity)
            rootLayer.zPosition = CGFloat(style.zIndex)
        }
    }

    public func destroy() {
        rootLayer.removeFromSuperlayer()
    }
}
