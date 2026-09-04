import XCTest
import CoreGraphics
import Flux
@testable import PrismCore

@MainActor
final class EventsFocusAccessibilityTests: XCTestCase {

    // MARK: - 1. Event Propagation: Capture, Target, Bubble, and StopPropagation

    func testEventCaptureTargetBubbleOrder() {
        let rootNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Root", key: "root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let childNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Child", key: "child"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let targetNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Target", key: "target"), kind: .text("Tap me")))

        rootNode.mount()
        childNode.mount(in: rootNode)
        targetNode.mount(in: childNode)
        rootNode.children = [childNode]
        childNode.children = [targetNode]

        var executionLog: [String] = []

        rootNode.addHandler(for: .tap, phase: .capturing) { _ in
            executionLog.append("root_capture")
        }
        childNode.addHandler(for: .tap, phase: .capturing) { _ in
            executionLog.append("child_capture")
        }
        targetNode.addHandler(for: .tap, phase: .atTarget) { _ in
            executionLog.append("target_atTarget")
        }
        childNode.addHandler(for: .tap, phase: .bubbling) { _ in
            executionLog.append("child_bubble")
        }
        rootNode.addHandler(for: .tap, phase: .bubbling) { _ in
            executionLog.append("root_bubble")
        }

        let event = Event(
            type: .tap,
            targetID: targetNode.id,
            payload: .pointer(PointerEventData(location: .zero, globalLocation: .zero))
        )

        let dispatcher = EventDispatcher()
        let result = dispatcher.dispatch(event: event, target: targetNode)

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(executionLog, [
            "root_capture",
            "child_capture",
            "target_atTarget",
            "child_bubble",
            "root_bubble"
        ])
    }

    func testStopPropagationHaltsTraversal() {
        let rootNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let childNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Child"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let targetNode = MountedNode(element: RenderElement(id: ElementID(typeName: "Target"), kind: .text("Leaf")))

        rootNode.mount()
        childNode.mount(in: rootNode)
        targetNode.mount(in: childNode)
        rootNode.children = [childNode]
        childNode.children = [targetNode]

        var executionLog: [String] = []

        rootNode.addHandler(for: .tap, phase: .capturing) { _ in
            executionLog.append("root_capture")
        }
        childNode.addHandler(for: .tap, phase: .capturing) { event in
            executionLog.append("child_capture_stop")
            event.stopPropagation()
        }
        targetNode.addHandler(for: .tap, phase: .atTarget) { _ in
            executionLog.append("target_atTarget")
        }
        childNode.addHandler(for: .tap, phase: .bubbling) { _ in
            executionLog.append("child_bubble")
        }

        let event = Event(
            type: .tap,
            targetID: targetNode.id,
            payload: .pointer(PointerEventData(location: .zero, globalLocation: .zero))
        )

        let dispatcher = EventDispatcher()
        let result = dispatcher.dispatch(event: event, target: targetNode)

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(executionLog, ["root_capture", "child_capture_stop"])
        XCTAssertTrue(event.isPropagationStopped)
    }

    // MARK: - 2. Reverse-z Hit Testing and Clipping

    func testHitTestingReverseZIndexAndOrder() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 400)
        root.mount()

        // Child A: zIndex 0, covers (0,0, 200, 200)
        let childA = MountedNode(element: RenderElement(id: ElementID(typeName: "A", key: "A"), kind: .shape(.rectangle(cornerRadius: 0))).zIndex(0))
        childA.frame = LayoutFrame(x: 0, y: 0, width: 200, height: 200)
        childA.mount(in: root)

        // Child B: zIndex 10 (higher), covers (50, 50, 200, 200)
        let childB = MountedNode(element: RenderElement(id: ElementID(typeName: "B", key: "B"), kind: .shape(.rectangle(cornerRadius: 0))).zIndex(10))
        childB.frame = LayoutFrame(x: 50, y: 50, width: 200, height: 200)
        childB.mount(in: root)

        root.children = [childA, childB]

        // Hit point (100, 100) is inside both Child A and Child B
        // Because Child B has zIndex 10 > 0, Child B must be hit!
        let hit = HitTester.hitTest(point: CGPoint(x: 100, y: 100), root: root)
        XCTAssertEqual(hit?.id.key, "B")

        // Hit point (20, 20) is only inside Child A
        let hitA = HitTester.hitTest(point: CGPoint(x: 20, y: 20), root: root)
        XCTAssertEqual(hitA?.id.key, "A")

        // Hit point (350, 350) is outside both children, hits root
        let hitRoot = HitTester.hitTest(point: CGPoint(x: 350, y: 350), root: root)
        XCTAssertEqual(hitRoot?.id, root.id)
    }

    func testHitTestingClippedChildOutsideParent() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 400)
        root.mount()

        // Container clipped to (0, 0, 100, 100)
        let container = MountedNode(element: RenderElement(id: ElementID(typeName: "ClippedBox"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)).clipped())
        container.frame = LayoutFrame(x: 0, y: 0, width: 100, height: 100)
        container.mount(in: root)

        // Child overflows container at (150, 50, 50, 50)
        let overflowingChild = MountedNode(element: RenderElement(id: ElementID(typeName: "Overflow"), kind: .shape(.rectangle(cornerRadius: 0))))
        overflowingChild.frame = LayoutFrame(x: 150, y: 50, width: 50, height: 50)
        overflowingChild.mount(in: container)
        container.children = [overflowingChild]
        root.children = [container]

        // Point (160, 60) is geometrically inside overflowingChild, but container is clipped!
        // Hit test must NOT hit overflowingChild
        let hit = HitTester.hitTest(point: CGPoint(x: 160, y: 60), root: root)
        XCTAssertNotEqual(hit?.id, overflowingChild.id)
        XCTAssertEqual(hit?.id, root.id)
    }

    // MARK: - 3. Pointer Move, Hover, and Tap Synthesis

    func testPointerMoveHoverTransitionsAndTapSynthesis() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 400)
        root.mount()

        let button = MountedNode(element: RenderElement(id: ElementID(typeName: "Button", key: "btn"), kind: .shape(.rectangle(cornerRadius: 0))))
        button.frame = LayoutFrame(x: 50, y: 50, width: 100, height: 40)
        button.mount(in: root)
        root.children = [button]

        var entered = false
        var left = false
        var tapped = false

        button.addHandler(for: EventType.pointerEnter) { _ in entered = true }
        button.addHandler(for: EventType.pointerLeave) { _ in left = true }
        button.addHandler(for: EventType.tap) { _ in tapped = true }

        let dispatcher = EventDispatcher()

        // 1. Move inside button
        dispatcher.handlePointerMove(location: CGPoint(x: 60, y: 60), root: root)
        XCTAssertTrue(entered)
        XCTAssertFalse(left)

        // 2. Move outside button
        dispatcher.handlePointerMove(location: CGPoint(x: 300, y: 300), root: root)
        XCTAssertTrue(left)

        // 3. Pointer down on button followed by pointer up on button -> synthesizes tap
        _ = dispatcher.handlePointerDown(location: CGPoint(x: 70, y: 70), root: root)
        XCTAssertFalse(tapped)
        _ = dispatcher.handlePointerUp(location: CGPoint(x: 70, y: 70), root: root)
        XCTAssertTrue(tapped)
    }

    // MARK: - 4. FocusTree: Tab Navigation, Priority Order, and 2D Spatial Directions

    func testFocusTreeTabOrderAndPriority() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 500, height: 500)
        root.mount()

        // Field 1: at y=100, focusOrder=2
        let field1 = MountedNode(element: RenderElement(id: ElementID(typeName: "Field", key: "f1"), kind: .text("F1")).focusable(true, order: 2))
        field1.frame = LayoutFrame(x: 50, y: 100, width: 100, height: 30)
        field1.mount(in: root)

        // Field 2: at y=200, focusOrder=1 (prioritized before f1)
        let field2 = MountedNode(element: RenderElement(id: ElementID(typeName: "Field", key: "f2"), kind: .text("F2")).focusable(true, order: 1))
        field2.frame = LayoutFrame(x: 50, y: 200, width: 100, height: 30)
        field2.mount(in: root)

        root.children = [field1, field2]

        let focusTree = FocusTree(rootNode: root)

        // Tab order must prioritize field2 first (order: 1 < 2)
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.next))
        XCTAssertEqual(focusTree.currentFocus?.key, "f2")

        // Next moves to field1
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.next))
        XCTAssertEqual(focusTree.currentFocus?.key, "f1")

        // Previous moves back to field2
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.previous))
        XCTAssertEqual(focusTree.currentFocus?.key, "f2")
    }

    func testFocusTreeSpatial2DNavigation() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Grid"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 400)
        root.mount()

        // Top-Left (50, 50)
        let cellTL = MountedNode(element: RenderElement(id: ElementID(typeName: "Cell", key: "TL"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)).focusable())
        cellTL.frame = LayoutFrame(x: 50, y: 50, width: 80, height: 80)
        cellTL.mount(in: root)

        // Top-Right (200, 50)
        let cellTR = MountedNode(element: RenderElement(id: ElementID(typeName: "Cell", key: "TR"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)).focusable())
        cellTR.frame = LayoutFrame(x: 200, y: 50, width: 80, height: 80)
        cellTR.mount(in: root)

        // Bottom-Left (50, 200)
        let cellBL = MountedNode(element: RenderElement(id: ElementID(typeName: "Cell", key: "BL"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)).focusable())
        cellBL.frame = LayoutFrame(x: 50, y: 200, width: 80, height: 80)
        cellBL.mount(in: root)

        root.children = [cellTL, cellTR, cellBL]

        let focusTree = FocusTree(rootNode: root)
        focusTree.setFocus(to: cellTL.id)
        XCTAssertEqual(focusTree.currentFocus?.key, "TL")

        // Navigate Right from TL -> TR
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.right))
        XCTAssertEqual(focusTree.currentFocus?.key, "TR")

        // Navigate Left from TR -> TL
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.left))
        XCTAssertEqual(focusTree.currentFocus?.key, "TL")

        // Navigate Down from TL -> BL
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.down))
        XCTAssertEqual(focusTree.currentFocus?.key, "BL")

        // Navigate Up from BL -> TL
        XCTAssertTrue(focusTree.moveFocus(direction: FocusDirection.up))
        XCTAssertEqual(focusTree.currentFocus?.key, "TL")
    }

    func testStaleFocusClearedOnNodeUnmount() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 300, height: 300)
        root.mount()

        let dynamicChild = MountedNode(element: RenderElement(id: ElementID(typeName: "Child", key: "dyn"), kind: .text("Temp")).focusable())
        dynamicChild.frame = LayoutFrame(x: 10, y: 10, width: 100, height: 30)
        dynamicChild.mount(in: root)
        root.children = [dynamicChild]

        let focusTree = FocusTree(rootNode: root)
        focusTree.setFocus(to: dynamicChild.id)
        XCTAssertEqual(focusTree.currentFocus, dynamicChild.id)

        // Unmount dynamicChild
        dynamicChild.unmount()
        focusTree.nodeUnmounted(id: dynamicChild.id)

        // Stale focus must be cleared to nil immediately
        XCTAssertNil(focusTree.currentFocus)
    }

    // MARK: - 5. Accessibility Tree, TestID Lookup, and Stale Record Invalidation

    func testAccessibilityTreeSyncAndTestIDLookup() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 600)
        root.mount()

        let submitBtn = MountedNode(
            element: RenderElement(id: ElementID(typeName: "Button", key: "submit_btn"), kind: .text("Отправить"))
                .accessibilityLabel("Submit Order")
                .accessibilityHint("Double tap to place order")
                .accessibilityTraits([.button])
                .testID("submit_order_button")
        )
        submitBtn.frame = LayoutFrame(x: 20, y: 100, width: 200, height: 44)
        submitBtn.mount(in: root)

        var actionExecuted = false
        submitBtn.addHandler(for: .tap) { _ in actionExecuted = true }

        root.children = [submitBtn]

        let axTree = AccessibilityTree()
        axTree.update(from: root)

        // Lookup by stable testID
        let axElem = axTree.findElement(byTestID: "submit_order_button")
        XCTAssertNotNil(axElem)
        XCTAssertEqual(axElem?.label, "Submit Order")
        XCTAssertEqual(axElem?.hint, "Double tap to place order")
        XCTAssertEqual(axElem?.testID, "submit_order_button")
        XCTAssertTrue(axElem?.traits.contains(.button) ?? false)

        // Perform accessibility activation
        let performed = axElem?.performAction(.activate) ?? false
        XCTAssertTrue(performed)
        XCTAssertTrue(actionExecuted)
    }

    func testStaleAccessibilityRecordCannotBeActivatedAfterUnmount() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        root.mount()

        let child = MountedNode(
            element: RenderElement(id: ElementID(typeName: "Item", key: "item1"), kind: .text("Delete"))
                .testID("delete_item_btn")
        )
        child.mount(in: root)
        root.children = [child]

        let axTree = AccessibilityTree()
        axTree.update(from: root)

        guard let axElem = axTree.findElement(byTestID: "delete_item_btn") else {
            XCTFail("Element not found")
            return
        }
        XCTAssertFalse(axElem.isStale)

        // Node is unmounted
        child.unmount()
        axTree.nodeUnmounted(id: child.id)

        // Stale record invalidated and cannot be activated
        XCTAssertTrue(axElem.isStale)
        XCTAssertNil(axTree.findElement(byTestID: "delete_item_btn"))
        XCTAssertFalse(axElem.performAction(.activate))
    }

    // MARK: - 6. Keyboard Shortcut Registry and Conflict Detection

    func testKeyboardShortcutRegistryAndConflictDetection() {
        let registry = KeyboardShortcutRegistry()

        let idA = ElementID(typeName: "Button", key: "save")
        let idB = ElementID(typeName: "Menu", key: "backup_save")

        var saveTriggered = false
        let shortcut = KeyboardShortcut(key: "s", modifiers: .command)

        // Register first shortcut
        registry.register(shortcut: shortcut, elementID: idA) {
            saveTriggered = true
        }
        XCTAssertEqual(registry.conflicts.count, 0)

        // Register conflicting shortcut for another element
        registry.register(shortcut: shortcut, elementID: idB) {
            // Overriding action
        }
        XCTAssertEqual(registry.conflicts.count, 1)
        XCTAssertEqual(registry.conflicts.first?.existingElementID, idA)
        XCTAssertEqual(registry.conflicts.first?.newElementID, idB)

        // Test key event handling
        let keyEvent = Event(
            type: .keyDown,
            targetID: idB,
            payload: .key(KeyEventData(key: "s", charactersIgnoringModifiers: "s", modifiers: .command))
        )
        let handled = registry.handleKeyEvent(keyEvent)
        XCTAssertTrue(handled)
        XCTAssertTrue(keyEvent.isDefaultPrevented)
        _ = saveTriggered
    }

    // MARK: - 7. Environment Tokens: Reduce Motion & Increase Contrast

    func testAccessibilityEnvironmentTokens() {
        let env = LocalizationEnvironment.standard
        XCTAssertFalse(env.reduceMotion)
        XCTAssertFalse(env.increaseContrast)

        let updated = env.withReduceMotion(true).withIncreaseContrast(true)
        XCTAssertTrue(updated.reduceMotion)
        XCTAssertTrue(updated.increaseContrast)
    }
}
