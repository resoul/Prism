import Foundation
import QuartzCore

/// Core reconciliation engine computing minimal diff sets between mounted nodes and VRT elements,
/// updating live layer hierarchies in-place, and preventing redundant destroys.
@MainActor
public enum Reconciler {

    // MARK: - 1. Type Compatibility

    /// Determines whether two `ElementKind` instances share the same structural rendering type.
    public static func isSameType(old: ElementKind, new: ElementKind) -> Bool {
        switch (old, new) {
        case (.text, .text): return true
        case (.shape, .shape): return true
        case (.stack, .stack): return true
        case (.spacer, .spacer): return true
        case (.icon, .icon): return true
        case (.group, .group): return true
        case (.empty, .empty): return true
        case (.custom(let a), .custom(let b)): return a == b
        default: return false
        }
    }

    // MARK: - 2. Diff Calculation

    /// Computes the minimal diff patch set between existing mounted children and target elements.
    public static func diff(
        current: [MountedNode],
        elements: [RenderElement]
    ) -> ReconcilerDiff {
        var patches: [NodePatch] = []
        var warnings: [String] = []
        var mounts = 0
        var updates = 0
        var unmounts = 0
        var moves = 0
        var reusedLayers = 0

        // 1. Check for duplicate keys among target elements
        var seenKeys: Set<String> = []
        var duplicateKeys: [String] = []
        for elem in elements {
            if let k = elem.id.key {
                if seenKeys.contains(k) {
                    duplicateKeys.append(k)
                } else {
                    seenKeys.insert(k)
                }
            }
        }
        if !duplicateKeys.isEmpty {
            warnings.append("Duplicate keys detected: [\(duplicateKeys.joined(separator: ", "))]. Sibling keys must be unique.")
        }

        // 2. Separate keyed and unkeyed items
        var currentKeyed: [String: (index: Int, node: MountedNode)] = [:]
        var currentUnkeyed: [(index: Int, node: MountedNode)] = []

        for (idx, node) in current.enumerated() {
            if let k = node.id.key {
                currentKeyed[k] = (idx, node)
            } else {
                currentUnkeyed.append((idx, node))
            }
        }

        var matchedCurrentNodeIDs: Set<ElementID> = []

        var targetKeyedCount = 0
        var targetUnkeyedIndex = 0

        for (targetIndex, elem) in elements.enumerated() {
            if let key = elem.id.key {
                targetKeyedCount += 1
                if let match = currentKeyed[key] {
                    matchedCurrentNodeIDs.insert(match.node.id)
                    if isSameType(old: match.node.element.kind, new: elem.kind) {
                        patches.append(.update(node: match.node, newElement: elem))
                        updates += 1
                        reusedLayers += 1
                        if match.index != targetIndex {
                            patches.append(.move(node: match.node, fromIndex: match.index, toIndex: targetIndex))
                            moves += 1
                        }
                    } else {
                        patches.append(.replace(oldNode: match.node, newElement: elem, atIndex: targetIndex))
                        unmounts += 1
                        mounts += 1
                    }
                } else {
                    patches.append(.insert(element: elem, atIndex: targetIndex))
                    mounts += 1
                }
            } else {
                // Unkeyed matching by sequential unkeyed slot
                if targetUnkeyedIndex < currentUnkeyed.count {
                    let oldUnkeyed = currentUnkeyed[targetUnkeyedIndex]
                    matchedCurrentNodeIDs.insert(oldUnkeyed.node.id)
                    if isSameType(old: oldUnkeyed.node.element.kind, new: elem.kind) {
                        patches.append(.update(node: oldUnkeyed.node, newElement: elem))
                        updates += 1
                        reusedLayers += 1
                        if oldUnkeyed.node.element != elem {
                            warnings.append("Unkeyed sibling mutation detected at index \(targetIndex). Provide explicit .key(...) for stable reconciliation.")
                        }
                    } else {
                        patches.append(.replace(oldNode: oldUnkeyed.node, newElement: elem, atIndex: targetIndex))
                        unmounts += 1
                        mounts += 1
                    }
                    targetUnkeyedIndex += 1
                } else {
                    patches.append(.insert(element: elem, atIndex: targetIndex))
                    mounts += 1
                }
            }
        }

        // 3. Mark unmatched current nodes for removal
        for (idx, node) in current.enumerated() {
            if !matchedCurrentNodeIDs.contains(node.id) {
                patches.append(.remove(node: node, fromIndex: idx))
                unmounts += 1
            }
        }

        return ReconcilerDiff(
            patches: patches,
            mounts: mounts,
            updates: updates,
            unmounts: unmounts,
            moves: moves,
            reusedLayers: reusedLayers,
            warnings: warnings
        )
    }

    // MARK: - 3. Patch Application

    /// Reconciles a parent MountedNode's children against new elements.
    @discardableResult
    public static func reconcileChildren(
        parent: MountedNode,
        newElements: [RenderElement]
    ) -> ReconcilerDiff {
        let diffResult = diff(current: parent.children, elements: newElements)

        // 1. Process removals
        var nodesToRemove: Set<ElementID> = []
        for patch in diffResult.patches {
            switch patch {
            case .remove(let node, _):
                nodesToRemove.insert(node.id)
                node.unmount()
            case .replace(let oldNode, _, _):
                nodesToRemove.insert(oldNode.id)
                oldNode.unmount()
            default:
                break
            }
        }

        // 2. Map surviving nodes by ID
        var nodeRegistry: [ElementID: MountedNode] = [:]
        for node in parent.children where !nodesToRemove.contains(node.id) {
            nodeRegistry[node.id] = node
        }

        // 3. Construct new children array in exact target order
        var reconciledChildren: [MountedNode] = []
        for elem in newElements {
            if let existing = nodeRegistry[elem.id], isSameType(old: existing.element.kind, new: elem.kind) {
                existing.element = elem
                reconciledChildren.append(existing)
            } else {
                let newNode = MountedNode(element: elem)
                newNode.mount(in: parent)
                reconciledChildren.append(newNode)
            }
        }

        parent.children = reconciledChildren

        // 4. Recursively reconcile child subtrees
        for childNode in parent.children {
            if !childNode.element.children.isEmpty {
                reconcileChildren(parent: childNode, newElements: childNode.element.children)
            }
        }

        return diffResult
    }

    // MARK: - 4. Full Tree Reconciliation & Layout Sync

    /// Synchronizes a full tree: diffs children, computes two-pass layout, and updates CALayer renderers.
    @discardableResult
    public static func reconcileTree(
        rootNode: MountedNode,
        newRootElement: RenderElement,
        bounds: CGRect,
        safeArea: DirectionalEdgeInsets = .zero,
        context: RenderContext
    ) -> ReconcilerDiff {
        let normalized = newRootElement.normalized()
        rootNode.element = normalized

        let diff = reconcileChildren(parent: rootNode, newElements: normalized.children)

        // Two-pass layout computation
        let layoutTree = LayoutTreeBuilder.build(from: normalized)
        let contentWidth = max(0, bounds.width - safeArea.leading - safeArea.trailing)
        let contentHeight = max(0, bounds.height - safeArea.top - safeArea.bottom)

        let constraint = SizeConstraint(
            width: .exactly(contentWidth),
            height: .atMost(contentHeight)
        )
        layoutTree.measure(constraint: constraint)

        let rootFrame = LayoutFrame(
            x: safeArea.leading,
            y: safeArea.top,
            width: contentWidth,
            height: contentHeight
        )
        let roundingPolicy = PixelRoundingPolicy(scaleFactor: context.scaleFactor)
        layoutTree.layout(frame: rootFrame, roundingPolicy: roundingPolicy)

        // Synchronize frames into mounted tree and CALayers
        RenderTransaction.perform(disableActions: context.disableActions) {
            rootNode.update(newElement: normalized, frame: rootFrame, context: context)
            syncLayoutFrames(mounted: rootNode, layout: layoutTree, context: context)
        }

        return diff
    }

    private static func syncLayoutFrames(
        mounted: MountedNode,
        layout: LayoutNode,
        context: RenderContext
    ) {
        var childPairs: [(element: RenderElement, frame: LayoutFrame)] = []
        for (childMounted, childLayout) in zip(mounted.children, layout.children) {
            let frame = childLayout.layoutFrame ?? .zero
            childMounted.update(newElement: childMounted.element, frame: frame, context: context)
            childPairs.append((childMounted.element, frame))

            if !childMounted.children.isEmpty {
                syncLayoutFrames(mounted: childMounted, layout: childLayout, context: context)
            }
        }

        if let containerRenderer = mounted.renderer as? ContainerRenderer {
            containerRenderer.updateChildren(children: childPairs, context: context)
        }
    }
}
