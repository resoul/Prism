import Foundation

/// A structural component that renders its visual subtree into a designated overlay layer
/// while maintaining logical tree parentage for state, event bubbling, and environment.
public struct Portal: Component {
    public let targetLayer: OverlayLayer
    public let content: [RenderElement]

    public init(layer: OverlayLayer = .floating, @ComponentBuilder content: () -> [RenderElement]) {
        self.targetLayer = layer
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Portal"),
            kind: .portal(targetLayer: targetLayer),
            children: content
        )
    }
}

extension RenderElement {
    /// Projects this element into a target overlay layer while retaining logical parentage.
    public func portal(layer: OverlayLayer = .floating) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Portal"),
            kind: .portal(targetLayer: layer),
            children: [self]
        )
    }
}

extension Component {
    /// Projects this component into a target overlay layer while retaining logical parentage.
    public func portal(layer: OverlayLayer = .floating) -> RenderElement {
        render().portal(layer: layer)
    }
}
