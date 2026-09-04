import Foundation

// MARK: - Layout Engine Foundation
// Invariant: Layout engine operates in two passes (measure -> layout).
// Layout computation is pure and immutable preparation occurs off the main thread where applicable.

public enum LayoutFoundationMarker {
    public static let layerDescription = "Two-pass flexbox-inspired layout engine"
}
