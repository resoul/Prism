import Foundation
@_exported import PrismCore

/// Demonstration screen displaying user profile details loaded from route parameters.
public struct DemoProfileScreen: Screen {
    public let profileID: String
    public let initialTab: String?

    public init(profileID: String, initialTab: String? = nil) {
        self.profileID = profileID
        self.initialTab = initialTab
    }

    public var title: String? { "User \(profileID)" }
    public var navigationTransition: NavigationTransition { .push }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 12) {
            Text("Profile: \(profileID)")

            if let initialTab {
                Text("Selected Tab: \(initialTab)")
            }
        }
        .padding(24)
    }
}

/// Demonstration screen representing app settings.
public struct DemoSettingsScreen: Screen {
    public init() {}

    public var title: String? { "Settings" }
    public var navigationTransition: NavigationTransition { .modal }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 16) {
            Text("App Settings")
            Text("Theme and notification options")
        }
        .padding(20)
    }
}

/// Adaptive navigation container switching between mobile bottom bar and desktop sidebar.
public struct AdaptiveAppScaffold: Component {
    public let breakpoint: Breakpoint
    public let currentRoute: String
    public let onNavigate: @Sendable (String) -> Void
    public let content: any ComponentConvertible

    public init(
        breakpoint: Breakpoint,
        currentRoute: String,
        onNavigate: @escaping @Sendable (String) -> Void,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.breakpoint = breakpoint
        self.currentRoute = currentRoute
        self.onNavigate = onNavigate
        self.content = content()
    }

    public init(
        breakpoint: Breakpoint,
        currentRoute: String,
        onNavigate: @escaping @Sendable (String) -> Void,
        content: any ComponentConvertible
    ) {
        self.breakpoint = breakpoint
        self.currentRoute = currentRoute
        self.onNavigate = onNavigate
        self.content = content
    }

    public func body(context: ComponentContext) -> RenderElement {
        if breakpoint.isCompact {
            // Mobile: TopBar + Content + BottomBar
            return Scaffold(
                topBar: HStack {
                    Text("Prism Mobile")
                },
                bottomBar: HStack(spacing: 24) {
                    Text("Home")
                    Text("Profile")
                    Text("Settings")
                },
                content: content
            )
            .render(in: context)
        } else {
            // Desktop/Tablet: Sidebar + Content
            return Scaffold(
                sidebar: VStack(spacing: 16) {
                    Text("Prism Desktop")
                    Text("Overview")
                    Text("Profiles")
                    Text("Settings")
                },
                content: content
            )
            .render(in: context)
        }
    }
}
