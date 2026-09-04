import Foundation
import CoreGraphics

/// Dispatches events across the MountedNode tree using standard W3C-style
/// capturing -> target -> bubbling propagation phases.
@MainActor
public final class EventDispatcher {

    /// Currently hovered node for pointer move/enter/leave tracking.
    public private(set) weak var currentlyHoveredNode: MountedNode?

    /// Last pointer down target and location for click/tap gesture detection.
    private weak var lastPointerDownTarget: MountedNode?
    private var lastPointerDownLocation: CGPoint = .zero

    public init() {}

    /// Dispatches an event starting from the given target node.
    ///
    /// - Parameters:
    ///   - event: The event to dispatch.
    ///   - target: The target mounted node where the event originated.
    /// - Returns: `EventResult.handled` if any handler processed the event or called preventDefault/stopPropagation, `.ignored` otherwise.
    @discardableResult
    public func dispatch(event: Event, target: MountedNode) -> EventResult {
        guard target.isMounted else { return .ignored }

        // 1. Build ancestry path from root down to target
        var path: [MountedNode] = []
        var current: MountedNode? = target
        while let node = current {
            path.append(node)
            current = node.parent
        }
        let rootToTarget = path.reversed()
        let ancestors = Array(rootToTarget.dropLast()) // Root down to target.parent

        var didHandle = false

        // Phase 1: Capturing (Root -> target.parent)
        for ancestor in ancestors {
            if event.isPropagationStopped { break }
            event.phase = .capturing
            event.currentTargetID = ancestor.id

            if let handlers = ancestor.capturingHandlers[event.type] {
                for handler in handlers {
                    handler(event)
                    didHandle = true
                    if event.isPropagationStopped { break }
                }
            }
        }

        // Phase 2: At Target
        if !event.isPropagationStopped {
            event.phase = .atTarget
            event.currentTargetID = target.id

            if let capHandlers = target.capturingHandlers[event.type] {
                for handler in capHandlers {
                    handler(event)
                    didHandle = true
                    if event.isPropagationStopped { break }
                }
            }

            if !event.isPropagationStopped, let handlers = target.eventHandlers[event.type] {
                for handler in handlers {
                    handler(event)
                    didHandle = true
                    if event.isPropagationStopped { break }
                }
            }
        }

        // Phase 3: Bubbling (target.parent -> Root)
        if !event.isPropagationStopped {
            for ancestor in ancestors.reversed() {
                if event.isPropagationStopped { break }
                event.phase = .bubbling
                event.currentTargetID = ancestor.id

                if let handlers = ancestor.eventHandlers[event.type] {
                    for handler in handlers {
                        handler(event)
                        didHandle = true
                        if event.isPropagationStopped { break }
                    }
                }
            }
        }

        return (didHandle || event.isDefaultPrevented) ? .handled : .ignored
    }

    /// Handles pointer movement, updating hover state and dispatching pointerMove/pointerEnter/pointerLeave.
    public func handlePointerMove(
        location: CGPoint,
        root: MountedNode,
        modifiers: EventModifiers = .none
    ) {
        let hitTarget = HitTester.hitTest(point: location, root: root)

        // 1. Dispatch pointerMove to hit target
        if let target = hitTarget {
            let localPoint = target.convertToLocal(pointInHost: location)
            let moveData = PointerEventData(
                location: localPoint,
                globalLocation: location,
                button: .none,
                pointerType: .mouse,
                modifiers: modifiers
            )
            let moveEvent = Event(
                type: .pointerMove,
                targetID: target.id,
                payload: .pointer(moveData)
            )
            dispatch(event: moveEvent, target: target)
        }

        // 2. Manage pointerEnter / pointerLeave transitions
        if hitTarget !== currentlyHoveredNode {
            // Leave old target
            if let oldNode = currentlyHoveredNode, oldNode.isMounted {
                let localOld = oldNode.convertToLocal(pointInHost: location)
                let leaveData = PointerEventData(
                    location: localOld,
                    globalLocation: location,
                    button: .none,
                    pointerType: .mouse,
                    modifiers: modifiers
                )
                let leaveEvent = Event(
                    type: .pointerLeave,
                    targetID: oldNode.id,
                    payload: .pointer(leaveData)
                )
                dispatch(event: leaveEvent, target: oldNode)
            }

            // Enter new target
            if let newNode = hitTarget, newNode.isMounted {
                let localNew = newNode.convertToLocal(pointInHost: location)
                let enterData = PointerEventData(
                    location: localNew,
                    globalLocation: location,
                    button: .none,
                    pointerType: .mouse,
                    modifiers: modifiers
                )
                let enterEvent = Event(
                    type: .pointerEnter,
                    targetID: newNode.id,
                    payload: .pointer(enterData)
                )
                dispatch(event: enterEvent, target: newNode)
            }

            currentlyHoveredNode = hitTarget
        }
    }

    /// Handles pointer down events and records the initial touch/click target.
    public func handlePointerDown(
        location: CGPoint,
        root: MountedNode,
        button: PointerButton = .primary,
        pointerType: PointerType = .mouse,
        modifiers: EventModifiers = .none,
        clickCount: Int = 1
    ) -> EventResult {
        guard let target = HitTester.hitTest(point: location, root: root) else {
            lastPointerDownTarget = nil
            return .ignored
        }

        lastPointerDownTarget = target
        lastPointerDownLocation = location

        let localPoint = target.convertToLocal(pointInHost: location)
        let data = PointerEventData(
            location: localPoint,
            globalLocation: location,
            button: button,
            pointerType: pointerType,
            modifiers: modifiers,
            clickCount: clickCount
        )
        let event = Event(type: .pointerDown, targetID: target.id, payload: .pointer(data))
        return dispatch(event: event, target: target)
    }

    /// Handles pointer up events and synthesizes a `.tap` event if down and up correspond.
    public func handlePointerUp(
        location: CGPoint,
        root: MountedNode,
        button: PointerButton = .primary,
        pointerType: PointerType = .mouse,
        modifiers: EventModifiers = .none,
        clickCount: Int = 1
    ) -> EventResult {
        guard let target = HitTester.hitTest(point: location, root: root) else {
            lastPointerDownTarget = nil
            return .ignored
        }

        let localPoint = target.convertToLocal(pointInHost: location)
        let data = PointerEventData(
            location: localPoint,
            globalLocation: location,
            button: button,
            pointerType: pointerType,
            modifiers: modifiers,
            clickCount: clickCount
        )
        let upEvent = Event(type: .pointerUp, targetID: target.id, payload: .pointer(data))
        let result = dispatch(event: upEvent, target: target)

        // Synthesize tap if pointer up is on the same target as pointer down
        if let downTarget = lastPointerDownTarget, downTarget === target {
            let tapEvent = Event(type: .tap, targetID: target.id, payload: .pointer(data))
            dispatch(event: tapEvent, target: target)
        }

        lastPointerDownTarget = nil
        return result
    }

    /// Cleans up state when a node or root is unmounted.
    public func reset() {
        currentlyHoveredNode = nil
        lastPointerDownTarget = nil
    }
}
