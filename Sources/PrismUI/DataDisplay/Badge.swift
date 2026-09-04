import Foundation
import CoreGraphics
import PrismCore

/// Visual style variant for a Badge.
public enum BadgeVariant: String, Sendable, Equatable {
    case `default`
    case secondary
    case destructive
    case outline
}

/// Size tier for a Badge.
public enum BadgeSize: String, Sendable, Equatable {
    case sm
    case md

    public var fontSize: Double {
        switch self {
        case .sm: return 11.0
        case .md: return 12.0
        }
    }

    public var padding: DirectionalEdgeInsets {
        switch self {
        case .sm: return .init(top: 2, leading: 6, bottom: 2, trailing: 6)
        case .md: return .init(top: 3, leading: 8, bottom: 3, trailing: 8)
        }
    }
}

/// Compact status descriptor or count indicator.
public struct Badge: Component {
    public let text: String
    public let variant: BadgeVariant
    public let size: BadgeSize

    public init(
        _ text: String,
        variant: BadgeVariant = .default,
        size: BadgeSize = .md
    ) {
        self.text = text
        self.variant = variant
        self.size = size
    }

    public func body(context: ComponentContext) -> RenderElement {
        let textElement = RenderElement(
            id: ElementID(typeName: "Text", key: "label"),
            kind: .text(text),
            props: ElementProps(accessibilityLabel: text)
        )

        let badgeID = ElementID(typeName: "Badge")
        var modifiers: [ElementModifier] = [
            .padding(size.padding)
        ]

        // Semantic variant color styling
        switch variant {
        case .default:
            modifiers.append(.background(context.theme?.colors.primary ?? Color.hex("#2563EB")))
        case .secondary:
            modifiers.append(.background(context.theme?.colors.secondary ?? Color.hex("#F1F5F9")))
        case .destructive:
            modifiers.append(.background(context.theme?.colors.destructive ?? Color.hex("#DC2626")))
        case .outline:
            modifiers.append(.background(context.theme?.colors.background ?? Color.hex("#FFFFFF")))
        }

        return RenderElement(
            id: badgeID,
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 0),
            props: ElementProps(custom: ["badgeVariant": variant.rawValue, "badgeSize": size.rawValue]),
            modifiers: modifiers,
            children: [textElement]
        )
    }
}
