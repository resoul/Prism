import Foundation

/// Granular reconciliation operation computed during tree diffing.
@MainActor
public enum NodePatch {
    /// Update existing node in-place with a new element definition, reusing its CALayer.
    case update(node: MountedNode, newElement: RenderElement)

    /// Insert a newly created node at the specified index.
    case insert(element: RenderElement, atIndex: Int)

    /// Remove an existing node at the specified index.
    case remove(node: MountedNode, fromIndex: Int)

    /// Move an existing node from old index to new index.
    case move(node: MountedNode, fromIndex: Int, toIndex: Int)

    /// Replace an existing node with a different element type at the specified index.
    case replace(oldNode: MountedNode, newElement: RenderElement, atIndex: Int)
}

extension NodePatch: @preconcurrency CustomStringConvertible {
    public var description: String {
        MainActor.assumeIsolated {
            switch self {
            case .update(let node, let newElem):
                return "UPDATE[\(node.id)] -> \(newElem.kind)"
            case .insert(let elem, let index):
                return "INSERT[\(elem.id)] at index \(index)"
            case .remove(let node, let index):
                return "REMOVE[\(node.id)] from index \(index)"
            case .move(let node, let from, let to):
                return "MOVE[\(node.id)] from \(from) to \(to)"
            case .replace(let oldNode, let newElem, let index):
                return "REPLACE[\(oldNode.id) with \(newElem.id)] at index \(index)"
            }
        }
    }
}

/// Diagnostic metadata and patch set produced by a reconciliation pass.
@MainActor
public struct ReconcilerDiff {
    public var patches: [NodePatch]
    public var mounts: Int
    public var updates: Int
    public var unmounts: Int
    public var moves: Int
    public var reusedLayers: Int
    public var warnings: [String]

    public init(
        patches: [NodePatch] = [],
        mounts: Int = 0,
        updates: Int = 0,
        unmounts: Int = 0,
        moves: Int = 0,
        reusedLayers: Int = 0,
        warnings: [String] = []
    ) {
        self.patches = patches
        self.mounts = mounts
        self.updates = updates
        self.unmounts = unmounts
        self.moves = moves
        self.reusedLayers = reusedLayers
        self.warnings = warnings
    }
}

extension ReconcilerDiff: @preconcurrency CustomStringConvertible {
    public var description: String {
        MainActor.assumeIsolated {
            var lines: [String] = []
            lines.append("ReconcilerDiff(mounts: \(mounts), updates: \(updates), unmounts: \(unmounts), moves: \(moves), reusedLayers: \(reusedLayers)):")
            for patch in patches {
                lines.append("  - \(patch)")
            }
            for warning in warnings {
                lines.append("  ⚠️ Warning: \(warning)")
            }
            return lines.joined(separator: "\n")
        }
    }
}
