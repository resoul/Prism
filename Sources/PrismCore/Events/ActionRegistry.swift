import Foundation

/// Central thread-safe registry mapping ElementIDs or testIDs to interactive actions.
public final class ActionRegistry: @unchecked Sendable {
    public static let shared = ActionRegistry()

    public typealias ActionHandler = @Sendable @MainActor () -> Void

    private let lock = NSLock()
    private var actions: [ElementID: ActionHandler] = [:]
    private var testIDActions: [String: ActionHandler] = [:]

    public init() {}

    /// Registers an action for a specific `ElementID`.
    public func register(action: @escaping ActionHandler, for elementID: ElementID) {
        lock.lock()
        defer { lock.unlock() }
        actions[elementID] = action
    }

    /// Registers an action for a stable `testID`.
    public func register(action: @escaping ActionHandler, forTestID testID: String) {
        lock.lock()
        defer { lock.unlock() }
        testIDActions[testID] = action
    }

    /// Retrieves an action for the given `ElementID`.
    public func action(for elementID: ElementID) -> ActionHandler? {
        lock.lock()
        defer { lock.unlock() }
        return actions[elementID]
    }

    /// Retrieves an action for the given `testID`.
    public func action(forTestID testID: String) -> ActionHandler? {
        lock.lock()
        defer { lock.unlock() }
        return testIDActions[testID]
    }

    /// Removes an action for the given `ElementID`.
    public func unregister(for elementID: ElementID) {
        lock.lock()
        defer { lock.unlock() }
        actions.removeValue(forKey: elementID)
    }

    /// Removes an action for the given `testID`.
    public func unregister(forTestID testID: String) {
        lock.lock()
        defer { lock.unlock() }
        testIDActions.removeValue(forKey: testID)
    }

    /// Resets all registered actions.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        actions.removeAll()
        testIDActions.removeAll()
    }
}
