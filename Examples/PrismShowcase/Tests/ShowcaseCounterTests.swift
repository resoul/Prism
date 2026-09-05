import XCTest
import PrismUI
@testable import PrismCore

@MainActor
final class ShowcaseCounterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActionRegistry.shared.reset()
    }

    override func tearDown() {
        ActionRegistry.shared.reset()
        super.tearDown()
    }

    func testCounterRootHasStableAutomationIDs() {
        let store = ShowcaseStore()
        let root = store.rootElement()
        let tree = root.dumpTree()

        XCTAssertTrue(tree.contains("showcase.title"))
        XCTAssertTrue(tree.contains("showcase.counter"))
        XCTAssertTrue(tree.contains("showcase.increment"))
        XCTAssertTrue(tree.contains("showcase.decrement"))
        XCTAssertTrue(tree.contains("showcase.reset"))
        XCTAssertTrue(tree.contains("showcase.input"))
        XCTAssertTrue(tree.contains("showcase.input_submit"))
        XCTAssertTrue(tree.contains("showcase.scroll_area"))
        XCTAssertTrue(tree.contains("showcase.scroll_status"))
    }

    func testFluxStateTransitionsAndMainActorOwnership() {
        let store = ShowcaseStore()
        var publishedElements: [RenderElement] = []
        store.onChange = { elem in
            publishedElements.append(elem)
        }

        XCTAssertEqual(store.count, 0)
        XCTAssertEqual(store.inputText, "")

        store.increment()
        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.state.lastAction, "increment")

        store.increment()
        XCTAssertEqual(store.count, 2)

        store.decrement()
        XCTAssertEqual(store.count, 1)

        store.setInputText("Hello Prism")
        XCTAssertEqual(store.inputText, "Hello Prism")

        store.submitInput()
        XCTAssertEqual(store.submittedText, "Hello Prism")

        store.scrollBy(40)
        XCTAssertEqual(store.scrollOffset, 40.0)

        store.reset()
        XCTAssertEqual(store.count, 0)
        XCTAssertEqual(store.inputText, "")
        XCTAssertEqual(store.submittedText, "")
        XCTAssertEqual(store.scrollOffset, 0.0)

        XCTAssertGreaterThan(publishedElements.count, 0)
    }

    func testTeardownCancelsSubscriptions() {
        let store = ShowcaseStore()
        var publishedCount = 0
        store.onChange = { _ in
            publishedCount += 1
        }

        store.increment()
        XCTAssertEqual(publishedCount, 1)

        store.teardown()
        XCTAssertNil(store.onChange)

        store.increment()
        // Callback should not be invoked after teardown
        XCTAssertEqual(publishedCount, 1)
    }

    func testRepeatedMountUnmountCyclesLeakFree() {
        // 100 mount/unmount cycles without orphan overlays, lingering subscriptions, or stale state
        for _ in 1...100 {
            let store = ShowcaseStore()
            let engine = PrismHostEngine(rootElement: store.rootElement())
            let layer = CALayer()
            layer.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
            engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
            engine.mount(in: layer)

            store.increment()
            store.setInputText("Cycle test")

            engine.teardown()
            store.teardown()

            XCTAssertNil(engine.focusTree.rootNode)
            XCTAssertEqual(engine.overlayHost.activeEntries.count, 0)
        }
    }

    func testAccessibilityElementBridging() {
        let store = ShowcaseStore()
        let engine = PrismHostEngine(rootElement: store.rootElement())
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
        engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
        engine.mount(in: layer)

        let axTree = engine.accessibilityTree
        let incrementElement = axTree.findElement(byTestID: "showcase.increment")
        XCTAssertNotNil(incrementElement)
        XCTAssertTrue(incrementElement?.traits.contains(.button) ?? false)

        // Perform activate action via AccessibilityElement
        let didActivate = incrementElement?.performAction(.activate) ?? false
        XCTAssertTrue(didActivate)

        // Count should have incremented
        XCTAssertEqual(store.count, 1)

        engine.teardown()
        store.teardown()
    }
}
