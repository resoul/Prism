import Foundation
import CoreGraphics
import PrismCore

/// Declarative wrapper defining the collapsible header region above a tab pager.
public struct CollapsingHeader: Component {
    public let expandedHeight: Double
    public let collapsedHeight: Double
    private let content: [RenderElement]

    public init(
        expandedHeight: Double,
        collapsedHeight: Double = 0.0,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.expandedHeight = max(0.0, expandedHeight)
        self.collapsedHeight = max(0.0, min(collapsedHeight, expandedHeight))
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        let containerID = ElementID(typeName: "CollapsingHeader", key: "container")
        return RenderElement(
            id: containerID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            modifiers: [.height(expandedHeight)],
            children: content
        )
    }
}
