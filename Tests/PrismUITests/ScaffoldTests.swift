import XCTest
@testable import PrismUI
@testable import PrismCore

final class ScaffoldTests: XCTestCase {

    func testScaffoldSlotComposition() {
        let scaffold = Scaffold(
            topBar: Text("Top Navigation"),
            bottomBar: Text("Bottom Bar"),
            sidebar: Text("Sidebar"),
            overlay: Text("Floating Notice"),
            content: Text("Main Content")
        )

        let context = ComponentContext()
        let element = scaffold.body(context: context)

        // Root is a Stack because overlay is present
        if case .stack(let axis, _, _) = element.kind {
            XCTAssertEqual(axis, .vertical)
        } else {
            XCTFail("Expected stack kind")
        }
        XCTAssertEqual(element.children.count, 2) // [mainLayout, overlay]

        let mainVStack = element.children[0]
        if case .stack(let axis, _, _) = mainVStack.kind {
            XCTAssertEqual(axis, .vertical)
        } else {
            XCTFail("Expected vertical stack")
        }
        XCTAssertEqual(mainVStack.children.count, 3) // [topBar, middleSection, bottomBar]

        let middleHStack = mainVStack.children[1]
        if case .stack(let axis, _, _) = middleHStack.kind {
            XCTAssertEqual(axis, .horizontal)
        } else {
            XCTFail("Expected horizontal stack")
        }
        XCTAssertEqual(middleHStack.children.count, 2) // [sidebar, content]
    }

    func testScaffoldWithoutOverlayOrSidebar() {
        let scaffold = Scaffold(
            topBar: Text("Header"),
            content: Text("Only Body")
        )

        let context = ComponentContext()
        let element = scaffold.body(context: context)

        // Root is directly a vertical stack without extra stack wrapper
        if case .stack(let axis, _, _) = element.kind {
            XCTAssertEqual(axis, .vertical)
        } else {
            XCTFail("Expected vertical stack")
        }
        XCTAssertEqual(element.children.count, 2) // [topBar, content]
    }

    func testScaffoldFluentModifiers() {
        let scaffold = Scaffold {
            Text("Body")
        }
        .topBar { Text("Modified Top") }
        .bottomBar { Text("Modified Bottom") }
        .sidebar { Text("Modified Sidebar") }
        .autoScroll(.automatic)
        .safeArea(.topOnly)

        XCTAssertNotNil(scaffold.topBar)
        XCTAssertNotNil(scaffold.bottomBar)
        XCTAssertNotNil(scaffold.sidebar)
        XCTAssertEqual(scaffold.autoScrollPolicy, .automatic)
        XCTAssertEqual(scaffold.safeAreaPolicy, .topOnly)
    }
}
