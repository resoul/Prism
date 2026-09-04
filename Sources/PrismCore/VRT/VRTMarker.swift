import Foundation

// MARK: - Virtual Render Tree (VRT) Foundation
// Invariant: RenderElement is an immutable value type. MountedNode is the persistent node owning CALayer.
// Reconciler performs diff(RenderElement) -> patch(MountedNode) using ElementID.

public enum VRTFoundationMarker {
    public static let layerDescription = "Immutable RenderElement tree, MountedNode state, Reconciler diff/patch"
}
