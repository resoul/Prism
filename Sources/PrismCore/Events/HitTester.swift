import Foundation
import CoreGraphics

/// Reverse-z hit testing engine traversing the MountedNode hierarchy.
///
/// Respects zIndex ordering, sibling drawing order, clipping boundaries, and opacity.
@MainActor
public enum HitTester {

    /// Performs hit testing on the mounted tree given a point in root host coordinates.
    ///
    /// - Parameters:
    ///   - point: The query point in host window coordinates.
    ///   - root: The root mounted node of the hierarchy.
    /// - Returns: The deepest leaf mounted node hit by the point, or nil if no node contains the point.
    public static func hitTest(
        point: CGPoint,
        root: MountedNode
    ) -> MountedNode? {
        // 1. Invisibility check
        guard root.isMounted, root.element.resolvedStyle.opacity > 0.001 else {
            return nil
        }

        let globalFrame = root.globalFrame

        // 2. Clipping check: if clipped and point is outside global frame, prune subtree
        let isClipped = root.element.props.custom["clip"] == "true"
        if isClipped && !globalFrame.contains(point) {
            return nil
        }

        // 3. Sort children by reverse-z:
        // Primary: zIndex descending (higher zIndex on top)
        // Secondary: sibling array index descending (later siblings drawn on top)
        let sortedChildren = root.children.enumerated().sorted { a, b in
            let zA = a.element.element.resolvedStyle.zIndex
            let zB = b.element.element.resolvedStyle.zIndex
            if zA != zB {
                return zA > zB
            }
            return a.offset > b.offset
        }.map { $0.element }

        // 4. Test children first (top-to-bottom in display stack)
        for child in sortedChildren {
            if let hit = hitTest(point: point, root: child) {
                return hit
            }
        }

        // 5. If no child hit, test self
        if globalFrame.contains(point) {
            return root
        }

        return nil
    }
}
