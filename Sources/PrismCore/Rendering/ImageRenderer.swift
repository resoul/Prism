import Foundation
import QuartzCore
import CoreGraphics

/// Renderer for raster and vector-decoded bitmap images using GPU-accelerated CALayer.contents.
@MainActor
public final class ImageRenderer: LayerRenderer {
    public let elementID: ElementID
    public let imageLayer: CALayer

    public var rootLayer: CALayer { imageLayer }

    private var activeRequestGeneration: UInt64 = 0

    public init(elementID: ElementID) {
        self.elementID = elementID
        let layer = CALayer()
        layer.name = "ImageLayer[\(elementID)]"
        layer.masksToBounds = true
        self.imageLayer = layer
    }

    public func update(element: RenderElement, frame: LayoutFrame, context: RenderContext) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            imageLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            imageLayer.position = CGPoint(
                x: frame.origin.x + frame.width / 2.0,
                y: frame.origin.y + frame.height / 2.0
            )
            imageLayer.contentsScale = CGFloat(context.scaleFactor)

            // Content mode gravity mapping
            let contentModeStr = element.props.custom["contentMode"] ?? "fit"
            switch contentModeStr {
            case "fill":
                imageLayer.contentsGravity = .resizeAspectFill
            case "stretch":
                imageLayer.contentsGravity = .resize
            case "center":
                imageLayer.contentsGravity = .center
            default:
                imageLayer.contentsGravity = .resizeAspect
            }

            // Optional corner radius
            if let radiusStr = element.props.custom["cornerRadius"], let radius = Double(radiusStr) {
                imageLayer.cornerRadius = CGFloat(radius)
            } else {
                imageLayer.cornerRadius = 0
            }

            // Check if direct pre-decoded CGImage is supplied
            if case .custom("image") = element.kind {
                // If direct bitmap is assigned via props or asynchronously
                activeRequestGeneration &+= 1
            }
        }
    }

    /// Sets the decoded image bitmap directly onto the CALayer on MainActor.
    public func setImage(_ image: CGImage?, animated: Bool = false) {
        if animated && image != nil {
            let transition = CATransition()
            transition.duration = 0.2
            transition.type = .fade
            imageLayer.add(transition, forKey: "imageFade")
        }
        imageLayer.contents = image
    }

    public func destroy() {
        activeRequestGeneration &+= 1
        imageLayer.removeFromSuperlayer()
        imageLayer.contents = nil
    }
}
