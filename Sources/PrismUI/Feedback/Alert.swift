import Foundation
import CoreGraphics
import PrismCore

/// Semantic feedback alert variant.
public enum AlertVariant: String, Sendable, Equatable {
    case info
    case warning
    case success
    case destructive

    public var defaultIconName: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .success: return "checkmark.circle"
        case .destructive: return "xmark.octagon"
        }
    }
}

/// Callout feedback banner communicating status, warnings, or error notifications.
public struct Alert: Component {
    public let title: String
    public let description: String?
    public let variant: AlertVariant
    public let customIcon: IconSource?

    public init(
        title: String,
        description: String? = nil,
        variant: AlertVariant = .info,
        icon: IconSource? = nil
    ) {
        self.title = title
        self.description = description
        self.variant = variant
        self.customIcon = icon
    }

    public func body(context: ComponentContext) -> RenderElement {
        let iconSource = customIcon ?? .sf(name: variant.defaultIconName)
        let iconElement = RenderElement(
            id: ElementID(typeName: "Icon", key: "alert_icon"),
            kind: .icon(source: iconSource),
            modifiers: [
                .width(18.0),
                .height(18.0)
            ]
        )

        let titleElement = RenderElement(
            id: ElementID(typeName: "Text", key: "alert_title"),
            kind: .text(title)
        )

        var textChildren: [RenderElement] = [titleElement]

        if let description {
            let descElement = RenderElement(
                id: ElementID(typeName: "Text", key: "alert_desc"),
                kind: .text(description),
                modifiers: [.opacity(0.8)]
            )
            textChildren.append(descElement)
        }

        let contentStack = RenderElement(
            id: ElementID(typeName: "Stack", key: "text_content"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 4.0),
            children: textChildren
        )

        let alertID = ElementID(typeName: "Alert")
        let surfaceColor = context.theme?.colors.secondary ?? Color.hex("#F1F5F9")
        return RenderElement(
            id: alertID,
            kind: .stack(axis: .horizontal, alignment: .start, spacing: 12.0),
            props: ElementProps(
                accessibilityLabel: description != nil ? "\(title): \(description!)" : title,
                custom: ["alertVariant": variant.rawValue]
            ),
            modifiers: [
                .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 16)),
                .background(surfaceColor)
            ],
            children: [iconElement, contentStack]
        )
    }
}
