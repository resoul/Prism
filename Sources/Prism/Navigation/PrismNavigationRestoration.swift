import Foundation
import PrismUI
import PrismStorage

/// Turnkey navigation state restoration store backed by `PrismStorage.Preferences`.
public final class PrismStorageNavigationStore: NavigationStateStore, Sendable {
    private let preferences: Preferences
    private let key: PrefKey<NavigationState>

    public init(
        preferences: Preferences = .standard,
        keyName: String = "prism.navigation.state"
    ) {
        self.preferences = preferences
        self.key = PrefKey<NavigationState>(name: keyName, defaultValue: NavigationState())
    }

    public func loadNavigationState() async -> NavigationState? {
        let state = preferences.get(key)
        guard !state.isEmpty else { return nil }
        return state
    }

    public func saveNavigationState(_ state: NavigationState) async {
        preferences.set(state, for: key)
    }

    public func clearNavigationState() async {
        preferences.remove(key)
    }
}
