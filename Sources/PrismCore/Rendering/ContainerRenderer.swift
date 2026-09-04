import Foundation
import QuartzCore

/// Renderer for container nodes (Stack, Layout containers) managing child renderers and z-index ordering.
@MainActor
public final class ContainerRenderer: LayerRenderer {
    public let elementID: ElementID
    public let rootLayer: CALayer

    public private(set) var childRenderers: [ElementID: LayerRenderer] = [:]
    public private(set) var orderedChildIDs: [ElementID] = []

    public init(elementID: ElementID) {
        self.elementID = elementID
        let layer = CALayer()
        layer.name = "ContainerLayer[\(elementID)]"
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

            if let bg = style.background {
                rootLayer.backgroundColor = bg.cgColor
            } else {
                rootLayer.backgroundColor = nil
            }

            rootLayer.opacity = Float(style.opacity)
            rootLayer.zPosition = CGFloat(style.zIndex)
        }
    }

    /// Synchronizes child renderers with child VRT elements and layout frames.
    /// Invariant: Idempotent re-renders reuse existing renderers and avoid duplicate layers.
    public func updateChildren(
        children: [(element: RenderElement, frame: LayoutFrame)],
        context: RenderContext
    ) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            var updatedRenderers: [ElementID: LayerRenderer] = [:]
            var newOrderedIDs: [ElementID] = []

            for (childElement, childFrame) in children {
                let id = childElement.id
                newOrderedIDs.append(id)

                let renderer: LayerRenderer
                if let existing = childRenderers[id] {
                    renderer = existing
                } else {
                    renderer = RendererFactory.create(for: childElement)
                    if case .portal = childElement.kind {
                        // Portals project their layers into OverlayHost containers, not parent container layer
                    } else {
                        rootLayer.addSublayer(renderer.rootLayer)
                    }
                }

                renderer.update(element: childElement, frame: childFrame, context: context)
                updatedRenderers[id] = renderer
            }

            // Remove unused renderers
            for (id, renderer) in childRenderers where updatedRenderers[id] == nil {
                renderer.destroy()
            }

            childRenderers = updatedRenderers
            orderedChildIDs = newOrderedIDs

            // Sort sublayers deterministically by zPosition
            rootLayer.sublayers?.sort { $0.zPosition < $1.zPosition }
        }
    }

    public func destroy() {
        for renderer in childRenderers.values {
            renderer.destroy()
        }
        childRenderers.removeAll()
        orderedChildIDs.removeAll()
        rootLayer.removeFromSuperlayer()
    }
}
