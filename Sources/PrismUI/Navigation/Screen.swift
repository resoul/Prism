import Foundation
@_exported import PrismCore

/// Visual transition style applied when a screen is pushed or popped.
public enum NavigationTransition: String, Sendable, Equatable, Codable {
    case none
    case push
    case modal
    case sheet
    case fade
}

/// The base protocol for top-level navigation destination screens in Prism.
public protocol Screen: Component {
    /// The localized display title of the screen shown in navigation bars and window titles.
    var title: String? { get }

    /// The transition animation applied when navigating to this screen.
    var navigationTransition: NavigationTransition { get }
}

public extension Screen {
    var title: String? { nil }
    var navigationTransition: NavigationTransition { .push }
}

/// Abstract storage contract for persisting and restoring navigation state.
///
/// Decouples `PrismUI` from storage implementations (`UserDefaults`, `PrismStorage`, or files).
public protocol NavigationStateStore: Sendable {
    /// Loads the persisted navigation state, returning `nil` if none exists or if migration fails.
    func loadNavigationState() async -> NavigationState?

    /// Persists the active navigation state.
    func saveNavigationState(_ state: NavigationState) async

    /// Clears any saved navigation state.
    func clearNavigationState() async
}

/// Default fallback screen rendered when an invalid or unknown route is requested.
public struct DefaultNotFoundScreen: Screen {
    public let requestedPath: String

    public init(requestedPath: String) {
        self.requestedPath = requestedPath
    }

    public var title: String? { "Page Not Found" }
    public var navigationTransition: NavigationTransition { .fade }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 16) {
            Text("404")
            Text("The requested route '\(requestedPath)' could not be found.")
        }
        .frame(width: 200, height: 150)
        .padding(24)
    }
}
