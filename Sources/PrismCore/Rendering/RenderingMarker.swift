import Foundation

// MARK: - Rendering Foundation
// Invariant: CALayer ownership belongs strictly to MountedNode / Renderer hierarchy.
// CALayer, host views, and render updates are strictly confined to @MainActor.

public enum RenderingFoundationMarker {
    public static let layerDescription = "CALayer and Metal renderers"
}
