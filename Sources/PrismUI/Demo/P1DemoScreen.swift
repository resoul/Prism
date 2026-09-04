import Foundation
import CoreGraphics
import PrismCore

/// Navigation tabs for the P1 component catalog demo screen.
public enum P1DemoTab: String, CaseIterable, TabItem {
    case forms
    case components
    case profile

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .forms: return "Forms"
        case .components: return "Components"
        case .profile: return "Profile"
        }
    }
}

/// End-to-end integration screen showcasing all P1 components working cohesively.
public struct P1DemoScreen: Component {
    public var selectedTab: P1DemoTab
    public var isDialogOpen: Bool
    public var isTooltipVisible: Bool
    public var isButtonLoading: Bool
    public let onTabChanged: @Sendable (P1DemoTab) -> Void
    public let onDialogToggled: @Sendable (Bool) -> Void

    public init(
        selectedTab: P1DemoTab = .forms,
        isDialogOpen: Bool = false,
        isTooltipVisible: Bool = false,
        isButtonLoading: Bool = false,
        onTabChanged: @escaping @Sendable (P1DemoTab) -> Void = { _ in },
        onDialogToggled: @escaping @Sendable (Bool) -> Void = { _ in }
    ) {
        self.selectedTab = selectedTab
        self.isDialogOpen = isDialogOpen
        self.isTooltipVisible = isTooltipVisible
        self.isButtonLoading = isButtonLoading
        self.onTabChanged = onTabChanged
        self.onDialogToggled = onDialogToggled
    }

    public func body(context: ComponentContext) -> RenderElement {
        let headerTitle = RenderElement(
            id: ElementID(typeName: "Text", key: "demo_header"),
            kind: .text("Prism P1 Component Showcase")
        )

        let tabs = Tabs(P1DemoTab.allCases, selection: selectedTab, onSelect: onTabChanged) { tab in
            switch tab {
            case .forms:
                return renderFormsTab(context: context)
            case .components:
                return renderComponentsTab(context: context)
            case .profile:
                return renderProfileTab(context: context)
            }
        }

        // Modal Dialog overlay when active
        let dialog = Dialog(
            isPresented: isDialogOpen,
            title: "Confirm Action",
            onDismiss: { onDialogToggled(false) }
        ) {
            RenderElement(
                id: ElementID(typeName: "Text", key: "dialog_msg"),
                kind: .text("Are you sure you want to execute this operation?")
            )
        } actions: {
            Button("Cancel", variant: .outline) {
                onDialogToggled(false)
            }
            Button("Confirm", variant: .primary) {
                onDialogToggled(false)
            }
        }

        let rootID = ElementID(typeName: "P1DemoScreen")
        return RenderElement(
            id: rootID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 16.0),
            modifiers: [
                .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20)),
                .testID("p1_demo_screen")
            ],
            children: [headerTitle, tabs.body(context: context), dialog.body(context: context)]
        )
    }

    private func renderFormsTab(context: ComponentContext) -> [RenderElement] {
        let emailInput = Input("Email address", text: .constant("user@example.com"))
        let emailField = Field("Email Address", error: nil) {
            emailInput
        }

        let passwordInput = Input("Password", text: .constant("••••••••"))
        let passwordField = Field("Password", error: nil) {
            passwordInput
        }

        let rememberToggle = Toggle("Remember me", isOn: .constant(true))

        let submitButton = Button("Sign In", variant: .primary) {
            // Action trigger
        }

        let card = Card {
            CardHeader {
                CardTitle("Account Login")
                CardDescription("Enter your credentials to access your account")
            }
            CardContent {
                emailField
                passwordField
                rememberToggle
            }
            CardFooter {
                submitButton
            }
        }

        return [card.body(context: context)]
    }

    private func renderComponentsTab(context: ComponentContext) -> [RenderElement] {
        // Badges
        let badgeRow = RenderElement(
            id: ElementID(typeName: "Stack", key: "badge_row"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8.0),
            children: [
                Badge("Default", variant: .default).body(context: context),
                Badge("Secondary", variant: .secondary).body(context: context),
                Badge("Destructive", variant: .destructive).body(context: context),
                Badge("Outline", variant: .outline).body(context: context)
            ]
        )

        // Labels
        let label1 = Label("Starred Item", systemImage: "star.fill").body(context: context)
        let label2 = Label("Secure Cloud", systemImage: "lock.shield").body(context: context)

        // Alerts
        let infoAlert = Alert(title: "New Update", description: "Prism 1.2 is now available.", variant: .info).body(context: context)
        let errorAlert = Alert(title: "Connection Failed", description: "Unable to reach server.", variant: .destructive).body(context: context)

        // Spinners
        let spinnerRow = RenderElement(
            id: ElementID(typeName: "Stack", key: "spinner_row"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 12.0),
            children: [
                Spinner(size: .sm).body(context: context),
                Spinner(size: .md).body(context: context),
                Spinner(size: .lg).body(context: context)
            ]
        )

        // Dialog Trigger Button
        let dialogTrigger = Button("Open Modal Dialog", variant: .secondary) {
            onDialogToggled(true)
        }.body(context: context)

        // Tooltip
        let tooltip = Tooltip("Helpful contextual information", placement: .top, isVisible: isTooltipVisible) {
            Label("Hover for info", systemImage: "questionmark.circle")
        }.body(context: context)

        let divider = Divider().body(context: context)

        return [badgeRow, label1, label2, divider, infoAlert, errorAlert, spinnerRow, dialogTrigger, tooltip]
    }

    private func renderProfileTab(context: ComponentContext) -> [RenderElement] {
        let avatar1 = Avatar(initials: "TC", size: .lg).body(context: context)
        let avatar2 = Avatar(initials: "AK", size: .md).body(context: context)
        let avatar3 = Avatar(initials: "SL", size: .sm).body(context: context)

        let avatarRow = RenderElement(
            id: ElementID(typeName: "Stack", key: "avatar_row"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 12.0),
            children: [avatar1, avatar2, avatar3]
        )

        let tile = IconTile(systemImage: "bell.fill", badgeCount: 3).body(context: context)

        return [avatarRow, tile]
    }
}
