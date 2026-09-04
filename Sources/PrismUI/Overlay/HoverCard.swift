import Foundation
@_exported import PrismCore

/// Preferred placement of a `HoverCard` relative to its anchor target.
public enum HoverCardPlacement: String, Sendable, Equatable {
    case top
    case bottom
    case leading
    case trailing
}

/// A floating contextual card providing preview content when hovering or focusing an anchor element.
///
/// Projects its rich content into the `.floating` overlay tier via `Portal`.
public struct HoverCard: Component {
    public let placement: HoverCardPlacement
    public let isOpen: Bool
    public let anchor: [RenderElement]
    public let cardContent: [RenderElement]

    public init(
        placement: HoverCardPlacement = .bottom,
        isOpen: Bool = false,
        @ComponentBuilder anchor: () -> [RenderElement],
        @ComponentBuilder card: () -> [RenderElement]
    ) {
        self.placement = placement
        self.isOpen = isOpen
        self.anchor = anchor()
        self.cardContent = card()
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight
        var children = anchor

        if isOpen {
            var props = ElementProps(accessibilityLabel: "Contextual Preview")
            props.custom["role"] = "dialog"
            props.custom["placement"] = placement.rawValue

            let cardBubble = RenderElement(
                id: ElementID(typeName: "HoverCardBubble"),
                kind: .stack(axis: .vertical, alignment: .stretch, spacing: 8),
                props: props,
                modifiers: [
                    .padding(DirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)),
                    .background(colors.background),
                    .sdfRoundedRect(
                        cornerRadius: 8,
                        borderWidth: 1,
                        borderColor: colors.border,
                        fill: colors.background
                    ),
                    .testID("hover_card_bubble")
                ],
                children: cardContent
            ).portal(layer: .floating)

            children.append(cardBubble)
        }

        return RenderElement(
            id: ElementID(typeName: "HoverCardContainer"),
            kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
            children: children
        )
    }
}
