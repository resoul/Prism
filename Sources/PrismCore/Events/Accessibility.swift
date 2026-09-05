import Foundation
import CoreGraphics

/// Semantic accessibility traits for assistive technologies.
public struct AccessibilityTraits: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let none          = AccessibilityTraits([])
    public static let button        = AccessibilityTraits(rawValue: 1 << 0)
    public static let link          = AccessibilityTraits(rawValue: 1 << 1)
    public static let header        = AccessibilityTraits(rawValue: 1 << 2)
    public static let selected      = AccessibilityTraits(rawValue: 1 << 3)
    public static let disabled      = AccessibilityTraits(rawValue: 1 << 4)
    public static let adjustable    = AccessibilityTraits(rawValue: 1 << 5)
    public static let image         = AccessibilityTraits(rawValue: 1 << 6)
    public static let searchField   = AccessibilityTraits(rawValue: 1 << 7)
    public static let staticText    = AccessibilityTraits(rawValue: 1 << 8)
    public static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 9)
}

/// Actions performable on an accessibility element by assistive technologies.
public enum AccessibilityActionKind: Sendable, Hashable {
    case activate
    case increment
    case decrement
    case dismiss
    case custom(String)
}

/// An executable accessibility action.
public struct AccessibilityAction {
    public let kind: AccessibilityActionKind
    public let handler: @MainActor () -> Void

    public init(kind: AccessibilityActionKind, handler: @escaping @MainActor () -> Void) {
        self.kind = kind
        self.handler = handler
    }

    public static func activate(handler: @escaping @MainActor () -> Void) -> AccessibilityAction {
        AccessibilityAction(kind: .activate, handler: handler)
    }

    public static func increment(handler: @escaping @MainActor () -> Void) -> AccessibilityAction {
        AccessibilityAction(kind: .increment, handler: handler)
    }

    public static func decrement(handler: @escaping @MainActor () -> Void) -> AccessibilityAction {
        AccessibilityAction(kind: .decrement, handler: handler)
    }

    public static func custom(named name: String, handler: @escaping @MainActor () -> Void) -> AccessibilityAction {
        AccessibilityAction(kind: .custom(name), handler: handler)
    }
}

/// Semantic representation of an accessible UI element.
@MainActor
public final class AccessibilityElement {
    public let id: ElementID
    public var label: String?
    public var hint: String?
    public var value: String?
    public var traits: AccessibilityTraits
    public var actions: [AccessibilityAction]
    public var testID: String?
    public var frame: CGRect
    public var isAccessible: Bool
    public private(set) var isStale: Bool = false

    public init(
        id: ElementID,
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = .none,
        actions: [AccessibilityAction] = [],
        testID: String? = nil,
        frame: CGRect = .zero,
        isAccessible: Bool = true
    ) {
        self.id = id
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.actions = actions
        self.testID = testID
        self.frame = frame
        self.isAccessible = isAccessible
    }

    /// Marks this accessibility element as stale/invalidated upon unmount.
    public func invalidate() {
        self.isStale = true
        self.actions.removeAll()
    }

    /// Executes an accessibility action if the element is active and not stale.
    @discardableResult
    public func performAction(_ kind: AccessibilityActionKind) -> Bool {
        guard !isStale, isAccessible else { return false }
        if let match = actions.first(where: { $0.kind == kind }) {
            match.handler()
            return true
        }
        return false
    }
}

/// Accessibility tree synchronized with the live MountedNode hierarchy.
@MainActor
public final class AccessibilityTree {
    public private(set) var elements: [ElementID: AccessibilityElement] = [:]
    private var testIDIndex: [String: ElementID] = [:]

    public init() {}

    /// Synchronizes the accessibility tree from a root MountedNode.
    public func update(from root: MountedNode) {
        var newElements: [ElementID: AccessibilityElement] = [:]
        var newTestIDIndex: [String: ElementID] = [:]

        func traverse(_ node: MountedNode) {
            guard node.isMounted, node.element.resolvedStyle.opacity > 0.001 else { return }

            let props = node.element.props
            let hasAXLabel = props.accessibilityLabel != nil
            let hasCustomTraits = props.custom["accessibilityTraits"] != nil
            let hasTestID = props.testID != nil

            let isExplicitlyAccessible = props.custom["isAccessible"] != "false"
            let shouldBeAccessible = (hasAXLabel || hasCustomTraits || hasTestID || node.element.props.custom["isFocusable"] == "true") && isExplicitlyAccessible

            if shouldBeAccessible {
                var traits: AccessibilityTraits = .none
                if let raw = UInt(props.custom["accessibilityTraits"] ?? "") {
                    traits = AccessibilityTraits(rawValue: raw)
                }

                if props.custom["isButton"] == "true" {
                    traits.insert(.button)
                }
                if case .text = node.element.kind {
                    traits.insert(.staticText)
                }

                var actions: [AccessibilityAction] = []
                // If node has tap handler, button trait, or registered action, supply default activate action
                let hasAction = traits.contains(.button) || node.eventHandlers[.tap] != nil || ActionRegistry.shared.action(for: node.id) != nil || (props.testID.flatMap { ActionRegistry.shared.action(forTestID: $0) } != nil)
                if hasAction {
                    actions.append(.activate { [weak node] in
                        guard let node, node.isMounted else { return }
                        let tapEvent = Event(
                            type: .tap,
                            targetID: node.id,
                            payload: .pointer(PointerEventData(location: .zero, globalLocation: .zero))
                        )
                        let result = EventDispatcher().dispatch(event: tapEvent, target: node)
                        if result != .handled {
                            if let act = ActionRegistry.shared.action(for: node.id) ?? props.testID.flatMap({ ActionRegistry.shared.action(forTestID: $0) }) {
                                act()
                            }
                        }
                    })
                }

                let element = AccessibilityElement(
                    id: node.id,
                    label: props.accessibilityLabel,
                    hint: props.custom["accessibilityHint"],
                    value: props.custom["accessibilityValue"],
                    traits: traits,
                    actions: actions,
                    testID: props.testID,
                    frame: node.globalFrame,
                    isAccessible: isExplicitlyAccessible
                )

                newElements[node.id] = element
                if let testID = props.testID {
                    newTestIDIndex[testID] = node.id
                }
            }

            for child in node.children {
                traverse(child)
            }
        }

        traverse(root)

        // Mark removed elements as stale
        for (oldID, oldElem) in elements where newElements[oldID] == nil {
            oldElem.invalidate()
        }

        self.elements = newElements
        self.testIDIndex = newTestIDIndex
    }

    /// Finds an accessibility element by its stable testID.
    public func findElement(byTestID testID: String) -> AccessibilityElement? {
        guard let id = testIDIndex[testID] else { return nil }
        return elements[id]
    }

    /// Finds an accessibility element by ElementID.
    public func findElement(by id: ElementID) -> AccessibilityElement? {
        elements[id]
    }

    /// Invalidates an element when its corresponding node is unmounted.
    public func nodeUnmounted(id: ElementID) {
        if let elem = elements.removeValue(forKey: id) {
            elem.invalidate()
            if let testID = elem.testID {
                testIDIndex.removeValue(forKey: testID)
            }
        }
    }
}
