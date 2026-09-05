import XCTest
import PrismUI

@MainActor
final class ShowcaseCounterTests: XCTestCase {
    func testCounterRootHasStableAutomationIDs() {
        let store = ShowcaseCounterStore()
        let root = store.rootElement()
        let tree = root.dumpTree()

        XCTAssertTrue(tree.contains("showcase.title"))
        XCTAssertTrue(tree.contains("showcase.counter"))
        XCTAssertTrue(tree.contains("showcase.increment"))
    }
}
