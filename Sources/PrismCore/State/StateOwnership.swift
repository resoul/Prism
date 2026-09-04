import Foundation

/// Defines the four distinct state ownership tiers in Prism, each with its own lifecycle,
/// storage scope, and reordering/recycling policies.
public enum StateOwnershipTier: String, Sendable, CaseIterable, CustomStringConvertible {
    /// Global application store / services. Persists for the lifetime of the application process.
    case appStore

    /// Scoped to an active navigation screen or modal route. Disposed upon screen pop.
    case screenState

    /// Scoped to a mounted component instance identified by `ElementID`.
    /// Survives parent re-renders, but is destroyed upon node unmount or explicit key/type change.
    case componentState

    /// Scoped to an individual entity in a collection (`LazyList`, `ForEach`).
    /// Keyed strictly by explicit entity identifier, preserving state across scroll virtualization and reordering.
    case keyedListItemState

    public var description: String { rawValue }

    /// Explains the lifecycle guarantee for this tier.
    public var lifecyclePolicy: String {
        switch self {
        case .appStore:
            return "Application-wide singleton; never destroyed during normal execution."
        case .screenState:
            return "Route-scoped; initialized when screen mounts, released when route is popped."
        case .componentState:
            return "ElementID-scoped; survives parent re-renders, cleared on unmount or type replacement."
        case .keyedListItemState:
            return "Explicit entity key-scoped; preserved across virtualization, recycling, and reordering."
        }
    }
}
