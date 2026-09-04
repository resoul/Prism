import Foundation
import CoreGraphics
import PrismCore

/// Visual styling variants for interactive buttons.
public enum ButtonVariant: String, Hashable, Sendable {
    case primary
    case secondary
    case destructive
    case outline
    case ghost
}

/// Sizing scale for interactive buttons.
public enum ButtonSize: String, Hashable, Sendable {
    case sm
    case md
    case lg

    public var height: Double {
        switch self {
        case .sm: return 28.0
        case .md: return 36.0
        case .lg: return 44.0
        }
    }

    public var horizontalPadding: Double {
        switch self {
        case .sm: return 10.0
        case .md: return 16.0
        case .lg: return 20.0
        }
    }
}

/// Accessible interactive button primitive with semantic styling variants and visual states.
public struct Button: Component {
    public let title: String
    public var variant: ButtonVariant = .primary
    public var size: ButtonSize = .md
    public var isDisabled: Bool = false
    public var isLoading: Bool = false
    public let action: @Sendable @MainActor () -> Void

    public init(
        _ title: String,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .md,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.action = action
    }

    // MARK: - Modifiers

    public func variant(_ variant: ButtonVariant) -> Button {
        var copy = self
        copy.variant = variant
        return copy
    }

    public func size(_ size: ButtonSize) -> Button {
        var copy = self
        copy.size = size
        return copy
    }

    public func disabled(_ disabled: Bool = true) -> Button {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func loading(_ loading: Bool = true) -> Button {
        var copy = self
        copy.isLoading = loading
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let bgColor: Color = {
            switch variant {
            case .primary:
                return Color.hex("#2563EB") // Blue primary
            case .secondary:
                return Color.hex("#F1F5F9") // Light gray secondary
            case .destructive:
                return Color.hex("#DC2626") // Red destructive
            case .outline, .ghost:
                return Color.clear
            }
        }()

        let fgColor: Color = {
            switch variant {
            case .primary, .destructive:
                return Color.white
            case .secondary:
                return Color.hex("#0F172A")
            case .outline, .ghost:
                return Color.hex("#2563EB")
            }
        }()

        var props = ElementProps()
        props.custom["title"] = title
        props.custom["variant"] = variant.rawValue
        props.custom["size"] = size.rawValue
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        props.custom["isLoading"] = isLoading ? "true" : "false"

        var element = HStack(spacing: 8) {
            Text(title)
                .foregroundColor(fgColor)
        }
        .height(size.height)
        .padding(DirectionalEdgeInsets(top: 0, leading: size.horizontalPadding, bottom: 0, trailing: size.horizontalPadding))
        .background(bgColor)
        .opacity(isDisabled ? 0.5 : 1.0)

        element.props.custom.merge(props.custom) { _, new in new }
        return element
    }
}
