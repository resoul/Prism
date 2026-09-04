import Foundation
import Flux

/// Thread-safe and MainActor-isolated persistent storage for local component states.
/// Storage keys are uniquely built from `(ElementID, explicitStateKey)`.
///
/// Invariant: State persists across parent re-renders when `ElementID` is preserved,
/// but resets upon type replacement or changed explicit key.
@MainActor
public final class ComponentStateStore {
    public static let shared = ComponentStateStore()

    public struct StateKey: Hashable, Sendable, CustomStringConvertible {
        public let elementID: ElementID
        public let name: String

        public init(elementID: ElementID, name: String) {
            self.elementID = elementID
            self.name = name
        }

        public var description: String {
            "\(elementID):\(name)"
        }
    }

    private var states: [StateKey: Any] = [:]

    public init() {}

    /// Retrieves an existing state or evaluates the initial value closure once on first access.
    public func state<T: Sendable & Equatable>(
        for elementID: ElementID,
        name: String = "default",
        initial: () -> T
    ) -> CurrentValueDistinct<T> {
        let key = StateKey(elementID: elementID, name: name)
        if let existing = states[key] as? CurrentValueDistinct<T> {
            return existing
        }
        let fresh = CurrentValueDistinct(initial())
        states[key] = fresh
        return fresh
    }

    /// Accesses all registered state keys for diagnostic inspection.
    public var registeredKeys: [StateKey] {
        Array(states.keys)
    }

    /// Removes all state instances associated with a given element identity upon unmount or replacement.
    public func purge(for elementID: ElementID) {
        states = states.filter { $0.key.elementID != elementID }
    }

    /// Clears all stored component states.
    public func reset() {
        states.removeAll()
    }
}
