import Foundation
@_exported import PrismCore
import PrismLogging
import struct Flux.Flux
import class Flux.Pipe

/// Pure data record representing an active entry on the navigation stack.
public struct RouteEntry: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let path: String
    public let parameters: [String: String]
    public var state: [String: String]

    public init(
        id: UUID = UUID(),
        path: String,
        parameters: [String: String] = [:],
        state: [String: String] = [:]
    ) {
        self.id = id
        self.path = path
        self.parameters = parameters
        self.state = state
    }
}

/// Versioned, serializable snapshot of the navigation stack.
public struct NavigationState: Codable, Sendable, Equatable {
    public static let currentVersion = 1

    public let version: Int
    public var entries: [RouteEntry]

    public init(version: Int = NavigationState.currentVersion, entries: [RouteEntry] = []) {
        self.version = version
        self.entries = entries
    }

    /// True if the stack has at least one entry.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    /// The topmost route entry.
    public var current: RouteEntry? {
        entries.last
    }
}

/// Stateful navigation stack manager driving push, pop, replace, and reset operations.
public final class Navigator: @unchecked Sendable {
    private let lock = NSLock()
    private var _state: NavigationState
    private let pipe = Pipe<NavigationState>(bufferingPolicy: .bufferingNewest(16))
    private let router: Router?

    public var state: NavigationState {
        lock.withLock { _state }
    }

    public var stateFlux: Flux<NavigationState> {
        pipe.flux
    }

    public var currentEntry: RouteEntry? {
        lock.withLock { _state.current }
    }

    public var canPop: Bool {
        lock.withLock { _state.entries.count > 1 }
    }

    public var depth: Int {
        lock.withLock { _state.entries.count }
    }

    public init(
        initialPath: String = "/",
        parameters: [String: String] = [:],
        router: Router? = nil
    ) {
        self.router = router
        let initialEntry = RouteEntry(path: initialPath, parameters: parameters)
        self._state = NavigationState(entries: [initialEntry])
    }

    public init(state: NavigationState, router: Router? = nil) {
        self.router = router
        self._state = state
    }

    // MARK: - Stack Operations

    /// Pushes a new route onto the stack.
    public func push(_ path: String, parameters: [String: String] = [:]) {
        let entry = RouteEntry(path: DeepLinkResolver.normalizePath(path), parameters: parameters)
        lock.lock()
        _state.entries.append(entry)
        let updated = _state
        lock.unlock()

        pipe.send(updated)
    }

    /// Pops the topmost screen from the stack.
    ///
    /// Returns `true` if popped, or `false` (no-op) if already at the root.
    @discardableResult
    public func pop() -> Bool {
        lock.lock()
        guard _state.entries.count > 1 else {
            lock.unlock()
            return false
        }
        _ = _state.entries.removeLast()
        let updated = _state
        lock.unlock()

        pipe.send(updated)
        return true
    }

    /// Replaces the topmost route with a new route.
    public func replace(_ path: String, parameters: [String: String] = [:]) {
        let entry = RouteEntry(path: DeepLinkResolver.normalizePath(path), parameters: parameters)
        lock.lock()
        if !_state.entries.isEmpty {
            _state.entries.removeLast()
        }
        _state.entries.append(entry)
        let updated = _state
        lock.unlock()

        pipe.send(updated)
    }

    /// Clears the entire navigation stack and sets a new root route.
    public func reset(to path: String, parameters: [String: String] = [:]) {
        let entry = RouteEntry(path: DeepLinkResolver.normalizePath(path), parameters: parameters)
        lock.lock()
        _state.entries = [entry]
        let updated = _state
        lock.unlock()

        pipe.send(updated)
    }

    // MARK: - State Restoration

    /// Restores stack from a saved navigation state, validating entries against the router.
    ///
    /// If the saved version is obsolete or an entry cannot be resolved, drops unmigratable
    /// routes gracefully and falls back to the root route.
    public func restore(from saved: NavigationState, router: Router, fallbackPath: String = "/") {
        guard saved.version == NavigationState.currentVersion else {
            // Version mismatch - reset to fallback root
            reset(to: fallbackPath)
            return
        }

        var validEntries: [RouteEntry] = []
        for entry in saved.entries {
            if router.resolve(path: entry.path) != nil {
                validEntries.append(entry)
            }
        }

        if validEntries.isEmpty {
            reset(to: fallbackPath)
        } else {
            lock.lock()
            _state = NavigationState(version: saved.version, entries: validEntries)
            let updated = _state
            lock.unlock()
            pipe.send(updated)
        }
    }
}

/// Declarative component rendering the active screen from a Navigator's stack.
public struct NavigatorView: Component {
    public let router: Router
    public let navigator: Navigator

    public init(router: Router, navigator: Navigator) {
        self.router = router
        self.navigator = navigator
    }

    public func body(context: ComponentContext) -> RenderElement {
        let currentEntry = navigator.currentEntry ?? RouteEntry(path: "/")
        let resolved = router.resolve(path: currentEntry.path)

        let targetScreen: any Screen
        if let resolved {
            targetScreen = resolved.screen
        } else {
            targetScreen = DefaultNotFoundScreen(requestedPath: currentEntry.path)
        }

        return targetScreen
            .render(in: context)
            .key("screen_\(currentEntry.id)")
    }
}
