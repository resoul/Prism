import XCTest
import Flux
@testable import PrismCore

@MainActor
final class ComponentStateLifecycleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ComponentStateStore.shared.reset()
    }

    // MARK: - 1. State Survives Unrelated Parent Rebuild

    func testStateSurvivesParentRebuild() async {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Parent"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let childElem = RenderElement(id: ElementID(typeName: "Counter", key: "c1"), kind: .text("0"))
        Reconciler.reconcileChildren(parent: parent, newElements: [childElem])

        let childNode = parent.children[0]
        let countState = childNode.state(name: "count") { 0 }
        await countState.set(42)

        // Parent rebuilds with updated sibling, keeping child's key "c1" intact
        let siblingElem = RenderElement(id: ElementID(typeName: "Shape", key: "s1"), kind: .shape(.rectangle(cornerRadius: 0)))
        Reconciler.reconcileChildren(parent: parent, newElements: [childElem, siblingElem])

        let sameChildNode = parent.children[0]
        let retainedState = sameChildNode.state(name: "count") { 0 }
        let currentVal = await retainedState.value

        XCTAssertEqual(currentVal, 42, "State must survive parent rebuild for identical element key")
    }

    // MARK: - 2. State Resets on Key Change / Type Replacement

    func testStateResetsOnExplicitKeyChangeOrTypeReplacement() async {
        let parent = MountedNode(element: RenderElement(id: ElementID(typeName: "Parent"), kind: .stack(axis: .vertical, alignment: .start, spacing: 0)))
        let oldElem = RenderElement(id: ElementID(typeName: "Counter", key: "counter_old"), kind: .text("0"))
        Reconciler.reconcileChildren(parent: parent, newElements: [oldElem])

        let oldNode = parent.children[0]
        let oldState = oldNode.state(name: "count") { 0 }
        await oldState.set(99)

        XCTAssertTrue(ComponentStateStore.shared.registeredKeys.contains { $0.elementID.key == "counter_old" })

        // Replace with new key "counter_new"
        let newElem = RenderElement(id: ElementID(typeName: "Counter", key: "counter_new"), kind: .text("0"))
        Reconciler.reconcileChildren(parent: parent, newElements: [newElem])

        XCTAssertFalse(ComponentStateStore.shared.registeredKeys.contains { $0.elementID.key == "counter_old" }, "Old state must be purged on key change")

        let newNode = parent.children[0]
        let newState = newNode.state(name: "count") { 0 }
        let initialVal = await newState.value
        XCTAssertEqual(initialVal, 0, "State must re-initialize for new element key")
    }

    // MARK: - 3. Two-Way Binding, Mapping & Dynamic Projections

    func testBindingTwoWayMutationAndProjections() {
        // Variable binding
        let (binding, get) = Binding.variable("Hello")
        XCTAssertEqual(binding.wrappedValue, "Hello")

        binding.wrappedValue = "Prism"
        XCTAssertEqual(get(), "Prism")

        // Map projection (String <-> Length)
        let lengthBinding = binding.map(
            get: { $0.count },
            set: { String(repeating: "*", count: $0) }
        )
        XCTAssertEqual(lengthBinding.wrappedValue, 5)

        lengthBinding.wrappedValue = 3
        XCTAssertEqual(get(), "***")

        // Optional projection with fallback
        var optStr: String? = nil
        let optBinding = Binding<String?>(get: { optStr }, set: { optStr = $0 })
        let projected = optBinding[default: "Fallback"]
        XCTAssertEqual(projected.wrappedValue, "Fallback")

        projected.wrappedValue = "Custom"
        XCTAssertEqual(optStr, "Custom")

        // KeyPath dynamicMember projection
        struct Profile {
            var username: String
            var score: Int
        }

        var profile = Profile(username: "Alice", score: 100)
        let profileBinding = Binding(get: { profile }, set: { profile = $0 })

        profileBinding.username.wrappedValue = "Bob"
        profileBinding.score.wrappedValue = 250

        XCTAssertEqual(profile.username, "Bob")
        XCTAssertEqual(profile.score, 250)
    }

    // MARK: - 4. Binding Feedback Loop Prevention

    func testBindingFeedbackLoopPrevention() {
        var setterCallCount = 0
        var val = "Initial"
        let binding = Binding(
            get: { val },
            set: {
                setterCallCount += 1
                val = $0
            }
        )

        // Setting same value should be ignored by setIfChanged
        binding.setIfChanged("Initial")
        XCTAssertEqual(setterCallCount, 0, "Identical value must not invoke setter")

        // Setting distinct value invokes setter
        binding.setIfChanged("Changed")
        XCTAssertEqual(setterCallCount, 1)
        XCTAssertEqual(val, "Changed")
    }

    // MARK: - 5. Effect Cancellation on Unmount

    func testEffectCancellationOnUnmount() async {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "Worker"), kind: .text("Job")))
        node.mount()

        node.effectScope.task(id: "long_poll") {
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        XCTAssertEqual(node.effectScope.activeTasks.count, 1)

        // Unmount node
        node.unmount()
        XCTAssertEqual(node.effectScope.activeTasks.count, 0)
        XCTAssertEqual(node.effectScope.lastCancellationReasons["long_poll"], .unmounted)
    }

    // MARK: - 6. Effect Cancellation on ID Change

    func testEffectCancellationOnIdChange() async {
        let scope = EffectScope()

        scope.task(id: "query") {
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        XCTAssertEqual(scope.activeTasks.count, 1)

        // Restart task with same id
        scope.task(id: "query") {
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        XCTAssertEqual(scope.lastCancellationReasons["query"], .idChanged)
        scope.cancelAll()
    }

    // MARK: - 7. Error Handling in Effects

    func testEffectErrorHandling() async {
        let scope = EffectScope()
        var capturedError: Error?

        struct CustomEffectError: Error, Equatable {}
        scope.errorHandler = { capturedError = $0 }

        scope.task(id: "failing") {
            throw CustomEffectError()
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotNil(capturedError)
        XCTAssertTrue(capturedError is CustomEffectError)
        XCTAssertEqual(scope.activeTasks.count, 0)
    }

    // MARK: - 8. Appear & Disappear Lifecycle Triggers

    func testAppearAndDisappearLifecycleTriggers() {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "View"), kind: .text("Content")))
        var appearCalled = false
        var disappearCalled = false

        node.effectScope.onAppearActions.append { appearCalled = true }
        node.effectScope.onDisappearActions.append { disappearCalled = true }

        XCTAssertFalse(appearCalled)
        XCTAssertFalse(disappearCalled)

        node.mount()
        XCTAssertTrue(appearCalled)
        XCTAssertFalse(disappearCalled)

        node.unmount()
        XCTAssertTrue(disappearCalled)
    }

    // MARK: - 9. State Inspector Diagnostics Dump

    func testStateInspectorDump() {
        let node = MountedNode(element: RenderElement(id: ElementID(typeName: "Item", key: "diag"), kind: .text("Diagnostics")))
        node.mount()

        _ = node.state(name: "active_flag") { true }
        node.effectScope.task(id: "stream_data") {
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        let dump = StateInspector.dump(for: node)
        XCTAssertTrue(dump.contains("State & Effect Diagnostics [Item[diag]@0]"))
        XCTAssertTrue(dump.contains("Active Effects: 1"))
        XCTAssertTrue(dump.contains("active_flag"))

        node.unmount()
    }

    // MARK: - 10. ScreenState vs ComponentState Lifecycle

    func testScreenStateVsComponentStateLifecycle() {
        // ComponentContext holds route-scoped screenState
        let context = ComponentContext(environment: LocalizationEnvironment(), theme: nil, values: [:], screenState: ["route_title": "Dashboard", "selected_tab": 2])
        XCTAssertEqual(context.screenState["route_title"] as? String, "Dashboard")
        XCTAssertEqual(context.screenState["selected_tab"] as? Int, 2)

        // Ownership tiers verify distinct lifecycle descriptions
        XCTAssertNotEqual(StateOwnershipTier.screenState.lifecyclePolicy, StateOwnershipTier.componentState.lifecyclePolicy)
        XCTAssertTrue(StateOwnershipTier.screenState.lifecyclePolicy.contains("Route-scoped"))
        XCTAssertTrue(StateOwnershipTier.componentState.lifecyclePolicy.contains("ElementID-scoped"))
    }
}
