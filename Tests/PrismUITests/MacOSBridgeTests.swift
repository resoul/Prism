import XCTest
import CoreGraphics
@testable import PrismUI

final class MacOSBridgeTests: XCTestCase {

    func testToolbarItemPropertiesAndAction() {
        final class ActionBox: @unchecked Sendable {
            private let lock = NSLock()
            private var fired = false
            func fire() { lock.withLock { fired = true } }
            var isFired: Bool { lock.withLock { fired } }
        }

        let box = ActionBox()
        let item = ToolbarItem(
            id: "search_btn",
            placement: .leading,
            label: "Search",
            iconName: "magnifyingglass",
            isEnabled: true
        ) {
            box.fire()
        }

        XCTAssertEqual(item.id, "search_btn")
        XCTAssertEqual(item.placement, .leading)
        XCTAssertEqual(item.label, "Search")
        XCTAssertEqual(item.iconName, "magnifyingglass")
        XCTAssertTrue(item.isEnabled)

        item.action()
        XCTAssertTrue(box.isFired)
    }

    func testMenuCommandEquality() {
        XCTAssertEqual(MenuCommand.undo, MenuCommand.undo)
        XCTAssertEqual(MenuCommand.copy, MenuCommand.copy)
        XCTAssertEqual(MenuCommand.paste, MenuCommand.paste)
        XCTAssertNotEqual(MenuCommand.copy, MenuCommand.paste)

        let custom1 = MenuCommand.custom(title: "Export", keyEquivalent: "e", action: {})
        let custom2 = MenuCommand.custom(title: "Export", keyEquivalent: "e", action: {})
        let custom3 = MenuCommand.custom(title: "Import", keyEquivalent: "i", action: {})

        XCTAssertEqual(custom1, custom2)
        XCTAssertNotEqual(custom1, custom3)
    }

    func testWindowGroupConfigurationAndManager() {
        let manager = WindowManager()

        let editorGroup = WindowGroup(
            id: "editor",
            title: "Document Editor",
            defaultSize: CGSize(width: 800, height: 500),
            minSize: CGSize(width: 400, height: 300)
        ) { docId in
            Text("Document: \(docId ?? "Untitled")")
        }

        XCTAssertEqual(editorGroup.id, "editor")
        XCTAssertEqual(editorGroup.title, "Document Editor")
        XCTAssertEqual(editorGroup.defaultSize.width, 800)
        XCTAssertEqual(editorGroup.minSize.height, 300)
        XCTAssertTrue(editorGroup.isRestorable)

        XCTAssertFalse(manager.hasGroup("editor"))
        manager.register(editorGroup)
        XCTAssertTrue(manager.hasGroup("editor"))
    }
}
