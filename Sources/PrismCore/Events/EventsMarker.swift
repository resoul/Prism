import Foundation

// MARK: - Unified Events & Focus Foundation
// Invariant: Unified Event and Focus model operates across iOS (touch), macOS (mouse/keyboard),
// and tvOS (remote/focus engine). Focus and Accessibility trees are built synchronously with VRT.

public enum EventsFoundationMarker {
    public static let layerDescription = "Cross-platform unified input events and focus management"
}
