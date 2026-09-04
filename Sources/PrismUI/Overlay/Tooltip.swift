import Foundation
import CoreGraphics
import PrismCore

/// Preferred placement relative to the target anchor.
public enum TooltipPlacement: String, Sendable, Equatable {
    case top
    case bottom
    case leading
    case trailing
}

/// Floating contextual hint anchored to a trigger element in the floating overlay tier.
public struct Tooltip: Component {
    public let text: String
    public let placement: TooltipPlacement
    public let delay: Double
    public let isVisible: Bool
    public let content: [RenderElement]

    public init(
        _ text: String,
        placement: TooltipPlacement = .top,
        delay: Double = 0.4,
        isVisible: Bool = false,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.text = text
        self.placement = placement
        self.delay = delay
        self.isVisible = isVisible
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        var children = content

        if isVisible {
            let tooltipBubbleID = ElementID(typeName: "TooltipBubble")
            var props = ElementProps(accessibilityLabel: text)
            props.custom["role"] = "tooltip"
            props.custom["placement"] = placement.rawValue

            let textElement = RenderElement(
                id: ElementID(typeName: "Text", key: "tooltip_text"),
                kind: .text(text)
            )

            let bubbleColor = context.theme?.colors.foreground ?? Color.hex("#0F172A")
            let bubble = RenderElement(
                id: tooltipBubbleID,
                kind: .stack(axis: .horizontal, alignment: .center, spacing: 0),
                props: props,
                modifiers: [
                    .padding(.init(top: 4, leading: 8, bottom: 4, trailing: 8)),
                    .background(bubbleColor),
                    .testID("tooltip_bubble")
                ],
                children: [textElement]
            ).portal(layer: .floating)

            children.append(bubble)
        }

        let containerID = ElementID(typeName: "TooltipContainer")
        return RenderElement(
            id: containerID,
            kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
            children: children
        )
    }
}
