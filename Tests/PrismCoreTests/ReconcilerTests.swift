import XCTest
import QuartzCore
import Flux
@testable import PrismCore
@testable import PrismUI

@MainActor
final class ReconcilerTests: XCTestCase {

    // MARK: - 1. Keyed Insert, Remove, Move & Layer Reuse

    func testKeyedInsertRemoveMove() {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Container"), kind: .stack(axis: .vertical, alignment: .start, spacing: 8)))

        let itemA = RenderElement(id: ElementID(typeName: "Text", key: "a"), kind: .text("Item A"))
        let itemB = RenderElement(id: ElementID(typeName: "Text", key: "b"), kind: .text("Item B"))
        let itemC = RenderElement(id: ElementID(typeName: "Text", key: "c"), kind: .text("Item C"))

        // Initial mount: [A, B, C]
        let initialDiff = Reconciler.reconcileChildren(parent: parent, newElements: [itemA, itemB, itemC])
        XCTAssertEqual(initialDiff.mounts, 3)
        XCTAssertEqual(parent.children.count, 3)

        let layerA = parent.children[0].rootLayer
        let layerC = parent.children[2].rootLayer

        // Update to [C, A, D]: B removed, D inserted, C moved to front, A retained
        let itemD = RenderElement(id: ElementID(typeName: "Text", key: "d"), kind: .text("Item D"))
        let updateDiff = Reconciler.reconcileChildren(parent: parent, newElements: [itemC, itemA, itemD])

        XCTAssertEqual(updateDiff.unmounts, 1) // B removed
        XCTAssertEqual(updateDiff.mounts, 1)   // D inserted
        XCTAssertEqual(updateDiff.moves, 2)    // C and A moved positions
        XCTAssertEqual(updateDiff.reusedLayers, 2) // A and C reused

        XCTAssertEqual(parent.children.count, 3)
        XCTAssertEqual(parent.children[0].id.key, "c")
        XCTAssertEqual(parent.children[1].id.key, "a")
        XCTAssertEqual(parent.children[2].id.key, "d")

        // Assert layer identity preserved for reused nodes
        XCTAssertTrue(parent.children[0].rootLayer === layerC, "CALayer of item C must be preserved across move")
        XCTAssertTrue(parent.children[1].rootLayer === layerA, "CALayer of item A must be preserved across move")
    }

    // MARK: - 2. Type Replacement For Same Key

    func testTypeReplacementForSameKey() {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Container"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))

        let textElem = RenderElement(id: ElementID(typeName: "Text", key: "slot1"), kind: .text("Header"))
        Reconciler.reconcileChildren(parent: parent, newElements: [textElem])

        let oldNode = parent.children[0]
        XCTAssertTrue(oldNode.renderer is TextRenderer)

        // Replace Text with Shape under the exact same key
        let shapeElem = RenderElement(id: ElementID(typeName: "Shape", key: "slot1"), kind: .shape(.rectangle(cornerRadius: 8)))
        let diff = Reconciler.reconcileChildren(parent: parent, newElements: [shapeElem])

        XCTAssertEqual(diff.unmounts, 1)
        XCTAssertEqual(diff.mounts, 1)
        XCTAssertFalse(oldNode.isMounted, "Old node must be unmounted on type replacement")

        let newNode = parent.children[0]
        XCTAssertTrue(newNode.renderer is ShapeRenderer)
        XCTAssertFalse(newNode === oldNode)
    }

    // MARK: - 3. Duplicate Key Diagnostic Warning

    func testDuplicateKeyDiagnosticWarning() {
        let item1 = RenderElement(id: ElementID(typeName: "Text", key: "dup_key"), kind: .text("One"))
        let item2 = RenderElement(id: ElementID(typeName: "Text", key: "dup_key"), kind: .text("Two"))

        let diff = Reconciler.diff(current: [], elements: [item1, item2])
        XCTAssertTrue(diff.warnings.contains { $0.contains("Duplicate keys detected") })
    }

    // MARK: - 4. Unkeyed Sibling Fallback and Warning

    func testUnkeyedSiblingFallbackAndWarning() {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Container"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))

        let unkeyed1 = RenderElement(id: ElementID(typeName: "Text", key: nil, siblingIndex: 0), kind: .text("Hello"))
        let unkeyed2 = RenderElement(id: ElementID(typeName: "Text", key: nil, siblingIndex: 1), kind: .text("World"))

        Reconciler.reconcileChildren(parent: parent, newElements: [unkeyed1, unkeyed2])
        XCTAssertEqual(parent.children.count, 2)

        // Mutate second unkeyed sibling
        let unkeyed2Updated = RenderElement(id: ElementID(typeName: "Text", key: nil, siblingIndex: 1), kind: .text("Prism"))
        let diff = Reconciler.reconcileChildren(parent: parent, newElements: [unkeyed1, unkeyed2Updated])

        XCTAssertEqual(diff.reusedLayers, 2)
        XCTAssertTrue(diff.warnings.contains { $0.contains("Unkeyed sibling mutation detected") })
    }

    // MARK: - 5. Nested Conditional Reconciliation

    func testNestedConditionalReconciliation() {
        let root = MountedNode(element: RenderElement(id: ElementID(typeName: "Root"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))

        // Branch 1: Logged out
        let loginButton = RenderElement(id: ElementID(typeName: "Text", key: "auth_btn"), kind: .text("Login"))
        Reconciler.reconcileChildren(parent: root, newElements: [loginButton])
        XCTAssertEqual(root.children.count, 1)
        XCTAssertEqual(root.children[0].id.key, "auth_btn")

        // Branch 2: Logged in (replaces login button with profile stack)
        let profileName = RenderElement(id: ElementID(typeName: "Text", key: "username"), kind: .text("Alice"))
        let avatar = RenderElement(id: ElementID(typeName: "Shape", key: "avatar"), kind: .shape(.circle))
        let profileStack = RenderElement(
            id: ElementID(typeName: "ProfileStack", key: "profile_container"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8),
            children: [avatar, profileName]
        )

        let diff = Reconciler.reconcileChildren(parent: root, newElements: [profileStack])
        XCTAssertEqual(diff.unmounts, 1) // auth_btn removed
        XCTAssertEqual(diff.mounts, 1)   // profile_container inserted

        let mountedProfile = root.children[0]
        XCTAssertEqual(mountedProfile.children.count, 2)
        XCTAssertEqual(mountedProfile.children[0].id.key, "avatar")
        XCTAssertEqual(mountedProfile.children[1].id.key, "username")
    }

    // MARK: - 6. Layer Identity Preserved on Sibling Update

    func testLayerIdentityPreservedOnSiblingChange() {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Container"), kind: .stack(axis: .vertical, alignment: .start, spacing: 8)))

        let counterElem0 = RenderElement(id: ElementID(typeName: "Text", key: "counter"), kind: .text("Count: 0"))
        let boxElem = RenderElement(id: ElementID(typeName: "Shape", key: "box"), kind: .shape(.rectangle(cornerRadius: 4)))

        Reconciler.reconcileChildren(parent: parent, newElements: [counterElem0, boxElem])
        let initialBoxLayer = parent.children[1].rootLayer

        // Update only counter text
        let counterElem1 = RenderElement(id: ElementID(typeName: "Text", key: "counter"), kind: .text("Count: 1"))
        let diff = Reconciler.reconcileChildren(parent: parent, newElements: [counterElem1, boxElem])

        XCTAssertEqual(diff.updates, 2)
        XCTAssertEqual(diff.reusedLayers, 2)
        XCTAssertTrue(parent.children[1].rootLayer === initialBoxLayer, "Sibling box layer must remain identical")
    }

    // MARK: - 7. Subscription Cancellation on Unmount

    func testSubscriptionCancellationOnUnmount() async {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "Text", key: "item"), kind: .text("Initial")))
        node.mount()

        let state = CurrentValue<Int>(1)
        var receivedValues: [Int] = []

        node.bind(to: state) { _, val in
            receivedValues.append(val)
        }

        XCTAssertEqual(node.subscriptionBag.count, 1)

        // Wait for initial replay value
        try? await Task.sleep(nanoseconds: 20_000_000)
        node.updateCoalescer.flush()
        XCTAssertEqual(receivedValues, [1])

        // Unmount node
        node.unmount()
        XCTAssertEqual(node.subscriptionBag.count, 0)
        XCTAssertFalse(node.isMounted)

        // Mutate state after unmount
        await state.set(999)
        try? await Task.sleep(nanoseconds: 20_000_000)
        node.updateCoalescer.flush()

        // Must not receive any updates after unmount
        XCTAssertEqual(receivedValues, [1])
    }

    // MARK: - 8. Flux 100 Rapid Updates Coalescing

    func testFlux100RapidUpdatesCoalescing() async {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "Text", key: "counter"), kind: .text("0")))
        node.mount()

        let state = CurrentValue<Int>(0)
        var updateInvocationCount = 0
        var latestApplied = -1

        node.bind(to: state) { _, val in
            updateInvocationCount += 1
            latestApplied = val
        }

        // Fire 100 rapid state updates
        for i in 1...100 {
            await state.set(i)
        }

        // Settle & flush
        try? await Task.sleep(nanoseconds: 50_000_000)
        node.updateCoalescer.flush()

        XCTAssertEqual(latestApplied, 100, "Must strictly apply the latest value")
        XCTAssertLessThan(updateInvocationCount, 100, "Rapid updates must be coalesced")
    }

    // MARK: - 9. CurrentValueDistinct Deduplication

    func testCurrentValueDistinctDeduplication() async {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "Text", key: "distinct"), kind: .text("A")))
        node.mount()

        let state = CurrentValueDistinct<String>("Active")
        var updatesCount = 0

        node.bind(to: state) { _, _ in
            updatesCount += 1
        }

        try? await Task.sleep(nanoseconds: 20_000_000)
        node.updateCoalescer.flush()
        XCTAssertEqual(updatesCount, 1) // Initial replay

        // Set same value twice
        await state.set("Active")
        await state.set("Active")
        try? await Task.sleep(nanoseconds: 20_000_000)
        node.updateCoalescer.flush()
        XCTAssertEqual(updatesCount, 1, "Duplicate value must not trigger update")

        // Set distinct value
        await state.set("Inactive")
        try? await Task.sleep(nanoseconds: 20_000_000)
        node.updateCoalescer.flush()
        XCTAssertEqual(updatesCount, 2)
    }

    // MARK: - 10. Reconciler Diff Description Readability

    func testReconcilerDiffDescriptionReadability() {
        let item1 = RenderElement(id: ElementID(typeName: "Text", key: "k1"), kind: .text("Hello"))
        let diff = Reconciler.diff(current: [], elements: [item1])

        let description = diff.description
        XCTAssertTrue(description.contains("ReconcilerDiff"))
        XCTAssertTrue(description.contains("INSERT[Text[k1]@0]"))
    }
}
