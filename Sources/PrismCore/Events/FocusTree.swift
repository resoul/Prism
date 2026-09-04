import Foundation
import CoreGraphics
import Flux

/// Direction for focus navigation requests.
public enum FocusDirection: Sendable, Equatable {
    case next
    case previous
    case up
    case down
    case left
    case right
}

/// Manages focus navigation, Tab order, and 2D spatial focus direction across the mounted tree.
/// Backed by a Flux `CurrentValueDistinct` state holder for reactive subscriptions.
@MainActor
public final class FocusTree {

    /// The currently focused ElementID on MainActor.
    public private(set) var currentFocus: ElementID? = nil

    /// Flux-backed state holder for reactive observation.
    public let currentFocusState: CurrentValueDistinct<ElementID?> = CurrentValueDistinct(nil)

    /// Reactive Flux stream notifying subscribers of focus changes.
    public var focusFlux: Flux<ElementID?> {
        currentFocusState.flux
    }

    /// Root mounted node of the hierarchy.
    public weak var rootNode: MountedNode?

    public init(rootNode: MountedNode? = nil) {
        self.rootNode = rootNode
    }

    /// Focuses the given ElementID, dispatching focusOut to the old node and focusIn to the new node.
    public func setFocus(to newTargetID: ElementID?) {
        guard newTargetID != currentFocus else { return }

        let oldID = currentFocus

        // Dispatch focusOut to old node
        if let oldID, let root = rootNode, let oldNode = findNode(by: oldID, in: root) {
            let focusOutEvent = Event(
                type: .focusOut,
                targetID: oldID,
                payload: .focus(FocusEventData(relatedID: newTargetID))
            )
            EventDispatcher().dispatch(event: focusOutEvent, target: oldNode)
        }

        currentFocus = newTargetID
        let state = currentFocusState
        Task {
            await state.set(newTargetID)
        }

        // Dispatch focusIn to new node
        if let newTargetID, let root = rootNode, let newNode = findNode(by: newTargetID, in: root) {
            let focusInEvent = Event(
                type: .focusIn,
                targetID: newTargetID,
                payload: .focus(FocusEventData(relatedID: oldID))
            )
            EventDispatcher().dispatch(event: focusInEvent, target: newNode)
        }
    }

    /// Moves focus in the given direction (Tab navigation or 2D spatial directions).
    @discardableResult
    public func moveFocus(direction: FocusDirection) -> Bool {
        guard let root = rootNode else { return false }
        let focusableNodes = collectFocusableNodes(in: root)
        guard !focusableNodes.isEmpty else { return false }

        switch direction {
        case .next:
            return moveSequential(forward: true, candidates: focusableNodes)
        case .previous:
            return moveSequential(forward: false, candidates: focusableNodes)
        case .up, .down, .left, .right:
            return moveSpatial(direction: direction, candidates: focusableNodes)
        }
    }

    /// Clears focus if the given node was unmounted, preventing stale focus retention.
    public func nodeUnmounted(id: ElementID) {
        if currentFocus == id {
            setFocus(to: nil)
        }
    }

    // MARK: - Private Traversal & Spatial Logic

    private func moveSequential(forward: Bool, candidates: [MountedNode]) -> Bool {
        guard !candidates.isEmpty else { return false }

        guard let curID = currentFocus,
              let currentIndex = candidates.firstIndex(where: { $0.id == curID }) else {
            // No current focus: select first or last
            let target = forward ? candidates.first : candidates.last
            setFocus(to: target?.id)
            return target != nil
        }

        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % candidates.count
        } else {
            nextIndex = (currentIndex - 1 + candidates.count) % candidates.count
        }

        setFocus(to: candidates[nextIndex].id)
        return true
    }

    private func moveSpatial(direction: FocusDirection, candidates: [MountedNode]) -> Bool {
        guard let curID = currentFocus,
              let root = rootNode,
              let currentNode = findNode(by: curID, in: root) else {
            // Default to sequential first element
            if let first = candidates.first {
                setFocus(to: first.id)
                return true
            }
            return false
        }

        let curFrame = currentNode.globalFrame
        let curCenter = CGPoint(x: curFrame.midX, y: curFrame.midY)

        var bestCandidate: MountedNode?
        var bestScore = Double.infinity

        for cand in candidates where cand.id != curID {
            let candFrame = cand.globalFrame
            let candCenter = CGPoint(x: candFrame.midX, y: candFrame.midY)

            let dx = candCenter.x - curCenter.x
            let dy = candCenter.y - curCenter.y

            let isValidDirection: Bool
            let primaryDist: Double
            let secondaryDist: Double

            switch direction {
            case .right:
                isValidDirection = dx > 0
                primaryDist = Double(dx)
                secondaryDist = Double(abs(dy))
            case .left:
                isValidDirection = dx < 0
                primaryDist = Double(-dx)
                secondaryDist = Double(abs(dy))
            case .down:
                isValidDirection = dy > 0
                primaryDist = Double(dy)
                secondaryDist = Double(abs(dx))
            case .up:
                isValidDirection = dy < 0
                primaryDist = Double(-dy)
                secondaryDist = Double(abs(dx))
            default:
                isValidDirection = false
                primaryDist = 0
                secondaryDist = 0
            }

            guard isValidDirection else { continue }

            // Spatial score: primary distance weighted heavily, with secondary distance penalty
            let score = primaryDist + secondaryDist * 2.0
            if score < bestScore {
                bestScore = score
                bestCandidate = cand
            }
        }

        if let best = bestCandidate {
            setFocus(to: best.id)
            return true
        }

        return false
    }

    /// Collects all focusable mounted nodes ordered by focusOrder then layout coordinates.
    public func collectFocusableNodes(in root: MountedNode) -> [MountedNode] {
        var results: [MountedNode] = []

        func traverse(_ node: MountedNode) {
            guard node.isMounted, node.element.resolvedStyle.opacity > 0.001 else { return }

            let isFocusable = node.element.props.custom["isFocusable"] == "true"
            if isFocusable {
                results.append(node)
            }

            for child in node.children {
                traverse(child)
            }
        }

        traverse(root)

        // Sort by:
        // 1. Explicit focusOrder (ascending, nil counts as 0)
        // 2. Vertical position (top to bottom)
        // 3. Horizontal position (left to right)
        return results.sorted { a, b in
            let orderA = Int(a.element.props.custom["focusOrder"] ?? "0") ?? 0
            let orderB = Int(b.element.props.custom["focusOrder"] ?? "0") ?? 0
            if orderA != orderB {
                return orderA < orderB
            }
            let frameA = a.globalFrame
            let frameB = b.globalFrame
            if abs(frameA.origin.y - frameB.origin.y) > 2.0 {
                return frameA.origin.y < frameB.origin.y
            }
            return frameA.origin.x < frameB.origin.x
        }
    }

    private func findNode(by id: ElementID, in root: MountedNode) -> MountedNode? {
        if root.id == id { return root }
        for child in root.children {
            if let match = findNode(by: id, in: child) {
                return match
            }
        }
        return nil
    }
}
