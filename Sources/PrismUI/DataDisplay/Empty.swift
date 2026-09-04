import Foundation
@_exported import PrismCore

/// A placeholder component representing empty lists, search queries with no results, or uninitialized state.
public struct Empty: Component {
    public let title: String
    public let description: String?
    public let iconName: String?
    public let actionTitle: String?
    public let onAction: (@Sendable @MainActor () -> Void)?

    public init(
        title: String,
        description: String? = nil,
        iconName: String? = "tray",
        actionTitle: String? = nil,
        onAction: (@Sendable @MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight

        return VStack(alignment: .center, spacing: 12) {
            if let iconName {
                Icon(iconName)
                    .frame(width: 48, height: 48)
            }

            Text(title)
                .font(.heading)
                .foregroundColor(colors.foreground)

            if let description {
                Text(description)
                    .font(.body)
                    .foregroundColor(colors.mutedForeground)
                    .alignment(.center)
            }

            if let actionTitle, let onAction {
                Spacer()
                    .height(8)

                Button(actionTitle, variant: .primary, action: onAction)
            }
        }
        .padding(32)
        .accessibilityElement(
            label: "Empty state: \(title)\(description != nil ? ". " + description! : "")",
            role: "group"
        )
        .render(in: context)
    }
}
