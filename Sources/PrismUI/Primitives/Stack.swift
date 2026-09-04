import Foundation
import PrismCore

/// Declarative layout container arranging children along a primary axis.
public struct Stack: Component {
    public let axis: LayoutAxis
    public let alignment: StackAlignment
    public let spacing: Double
    public let children: [RenderElement]

    public init(
        _ axis: LayoutAxis = .vertical,
        alignment: StackAlignment = .start,
        spacing: Double = 0,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        self.children = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Stack"),
            kind: .stack(axis: axis, alignment: alignment, spacing: spacing),
            children: children
        ).normalized()
    }
}

/// Convenience builder for horizontal stack layouts.
public func HStack(
    alignment: StackAlignment = .center,
    spacing: Double = 0,
    @ComponentBuilder content: () -> [RenderElement]
) -> Stack {
    Stack(.horizontal, alignment: alignment, spacing: spacing, content: content)
}

/// Convenience builder for vertical stack layouts.
public func VStack(
    alignment: StackAlignment = .start,
    spacing: Double = 0,
    @ComponentBuilder content: () -> [RenderElement]
) -> Stack {
    Stack(.vertical, alignment: alignment, spacing: spacing, content: content)
}
