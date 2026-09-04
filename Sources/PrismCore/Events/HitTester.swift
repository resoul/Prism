import Foundation
import CoreGraphics

/// Reverse-z hit testing engine traversing the MountedNode hierarchy.
///
/// Respects overlay tier precedence (debug -> toast -> modal -> floating -> content),
/// zIndex ordering, sibling drawing order, clipping boundaries, and opacity.
@MainActor
public enum HitTester {

    /// Performs hit testing on the mounted tree given a point in root host coordinates.
    ///
    /// - Parameters:
    ///   - point: The query point in host window coordinates.
    ///   - root: The root mounted node of the hierarchy.
    ///   - overlayHost: Optional overlay host managing overlay tiers, modal backdrop, and portals.
    /// - Returns: The deepest leaf mounted node hit by the point, or nil if no node contains the point.
    public static func hitTest(
        point: CGPoint,
        root: MountedNode,
        overlayHost: OverlayHost? = nil
    ) -> MountedNode? {
        let host = overlayHost ?? root.overlayHost
        if let host = host {
            // Test overlay tiers in reverse z-order
            let overlayTiers: [OverlayLayer] = [.debug, .toast, .modal, .floating]
            for tier in overlayTiers {
                // 1. Test active overlay entries in this tier
                let entriesInTier = host.activeEntries.values.filter { $0.layer == tier }
                for entry in entriesInTier.reversed() {
                    if let hit = hitTestSubtree(point: point, root: entry.node) {
                        return hit
                    }
                }

                // 2. Test registered portals in this tier
                let portalsInTier = host.activePortals.values.filter { $0.layer == tier }
                for portal in portalsInTier {
                    if let hit = hitTestSubtree(point: point, root: portal.node) {
                        return hit
                    }
                }

                // 3. Modal backdrop blocking
                if tier == .modal {
                    let blockingModals = entriesInTier.filter { $0.blocksBackgroundPointer }
                    if !blockingModals.isEmpty && host.backdropLayer.frame.contains(point) {
                        // Pointer absorbed by modal backdrop
                        return nil
                    }
                }
            }
        }

        // Test base content tree
        return hitTestSubtree(point: point, root: root, isRootContentTree: true)
    }

    private static func hitTestSubtree(
        point: CGPoint,
        root: MountedNode,
        isRootContentTree: Bool = false
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
            // Portals are projected into overlay layers; don't hit-test them in the content tree pass
            if isRootContentTree, case .portal = child.element.kind {
                continue
            }
            if let hit = hitTestSubtree(point: point, root: child, isRootContentTree: isRootContentTree) {
                return hit
            }
        }

        // 5. Portals themselves are transparent projection wrappers unless explicitly given bounds/kind
        if case .portal = root.element.kind {
            return nil
        }

        // 6. If no child hit, test self
        if globalFrame.contains(point) {
            return root
        }

        return nil
    }
}
