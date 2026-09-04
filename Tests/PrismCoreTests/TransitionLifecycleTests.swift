import XCTest
import QuartzCore
@testable import PrismCore

@MainActor
final class TransitionLifecycleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReduceMotionPreference.isEnabled = false
    }

    // MARK: - 1. Node Retention During Exit Transition

    func testNodeRetainedDuringExitTransition() {
        let parentElement = RenderElement(
            id: ElementID(typeName: "Stack", key: "parent"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 0)
        )
        let parentNode = MountedNode(element: parentElement)
        parentNode.mount()

        let childElement = RenderElement(
            id: ElementID(typeName: "Text", key: "child1"),
            kind: .text("Dismissible Item")
        ).transition(.opacity)

        // Mount initial child
        Reconciler.reconcileChildren(parent: parentNode, newElements: [childElement])
        XCTAssertEqual(parentNode.children.count, 1)
        let childNode = parentNode.children[0]
        XCTAssertTrue(childNode.isMounted)

        // Remove child with animation
        withAnimation(.linear(duration: 0.5)) {
            Reconciler.reconcileChildren(parent: parentNode, newElements: [])
        }

        // Active children array is empty, but node is retained in animatingOutChildren until completion
        XCTAssertEqual(parentNode.children.count, 0)
        XCTAssertEqual(parentNode.animatingOutChildren.count, 1)
        XCTAssertTrue(parentNode.animatingOutChildren[childNode.id] === childNode)
        XCTAssertTrue(childNode.isAnimatingRemoval)
        XCTAssertTrue(childNode.isMounted)
        XCTAssertNotNil(childNode.rootLayer.superlayer)
    }

    // MARK: - 2. In-flight Re-insertion (Resurrection)

    func testInterruptedRemovalAndResurrection() {
        let parentElement = RenderElement(
            id: ElementID(typeName: "Stack", key: "parent"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 0)
        )
        let parentNode = MountedNode(element: parentElement)
        parentNode.mount()

        let childElement = RenderElement(
            id: ElementID(typeName: "Text", key: "resurrect_item"),
            kind: .text("Item to Remove and Reinsert")
        ).transition(.slide)

        // Mount initial
        Reconciler.reconcileChildren(parent: parentNode, newElements: [childElement])
        let originalNode = parentNode.children[0]

        // Begin exit transition
        withAnimation(.easeInOut(duration: 0.5)) {
            Reconciler.reconcileChildren(parent: parentNode, newElements: [])
        }
        XCTAssertEqual(parentNode.animatingOutChildren.count, 1)
        XCTAssertTrue(originalNode.isAnimatingRemoval)

        // Re-insert same item while exit transition is in flight
        Reconciler.reconcileChildren(parent: parentNode, newElements: [childElement])

        // Node must be restored into children and removed from animatingOutChildren
        XCTAssertEqual(parentNode.children.count, 1)
        XCTAssertEqual(parentNode.animatingOutChildren.count, 0)
        let activeChild = parentNode.children[0]
        XCTAssertTrue(activeChild === originalNode, "Node should be resurrected and reused rather than recreated")
        XCTAssertFalse(activeChild.isAnimatingRemoval)
        XCTAssertTrue(activeChild.isMounted)
    }

    // MARK: - 3. Immediate Unmount Under Disabled Animations

    func testImmediateUnmountWhenAnimationsDisabled() {
        let parentElement = RenderElement(
            id: ElementID(typeName: "Stack", key: "parent"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 0)
        )
        let parentNode = MountedNode(element: parentElement)
        parentNode.mount()

        let childElement = RenderElement(
            id: ElementID(typeName: "Text", key: "instant_item"),
            kind: .text("Instant Dismiss")
        ).transition(.opacity)

        Reconciler.reconcileChildren(parent: parentNode, newElements: [childElement])
        let childNode = parentNode.children[0]

        let disabledTx = Transaction(disablesAnimations: true)
        withTransaction(disabledTx) {
            Reconciler.reconcileChildren(parent: parentNode, newElements: [])
        }

        // Node must unmount immediately without entering animatingOutChildren
        XCTAssertEqual(parentNode.children.count, 0)
        XCTAssertEqual(parentNode.animatingOutChildren.count, 0)
        XCTAssertFalse(childNode.isMounted)
        XCTAssertNil(childNode.rootLayer.superlayer)
    }
}
