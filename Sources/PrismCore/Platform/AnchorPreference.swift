import Foundation
import CoreGraphics

/// Registry tracking active geometric anchor nodes within the host view hierarchy.
@MainActor
public final class AnchorRegistry {
    public private(set) var registeredAnchors: [String: MountedNode] = [:]

    public init() {}

    /// Registers a mounted node under a unique anchor ID.
    public func register(id: String, node: MountedNode) {
        registeredAnchors[id] = node
    }

    /// Unregisters an anchor by ID.
    public func unregister(id: String) {
        registeredAnchors.removeValue(forKey: id)
    }

    /// Returns the live mounted node for a given anchor ID if still mounted.
    public func node(for id: String) -> MountedNode? {
        guard let node = registeredAnchors[id], node.isMounted else {
            registeredAnchors.removeValue(forKey: id)
            return nil
        }
        return node
    }

    /// Returns the current global frame in host coordinates for a given anchor ID.
    public func frame(for id: String) -> CGRect? {
        node(for: id)?.globalFrame
    }

    /// Scans the entire mounted hierarchy and synchronizes registered anchors.
    public func update(from root: MountedNode) {
        registeredAnchors.removeAll()
        collectAnchors(in: root)
    }

    private func collectAnchors(in node: MountedNode) {
        guard node.isMounted else { return }
        if let anchorID = node.element.props.custom["anchorID"] {
            registeredAnchors[anchorID] = node
        }
        for child in node.children {
            collectAnchors(in: child)
        }
    }
}

// MARK: - Modifiers

extension RenderElement {
    /// Identifies this element as a named geometry anchor for positioning overlays and tooltips.
    public func anchor(id: String) -> RenderElement {
        var copy = self
        copy.props.custom["anchorID"] = id
        return copy
    }
}

extension Component {
    /// Identifies this component as a named geometry anchor for positioning overlays and tooltips.
    public func anchor(id: String) -> RenderElement {
        render().anchor(id: id)
    }
}
