import XCTest
@testable import PrismCore

final class MenubarModelTests: XCTestCase {
    func testKeyboardNavigationDisabledAndFocusClose() {
        var model = MenubarModel(menus: [[MenuCommand(id: "new", title: "New"), MenuCommand(id: "quit", title: "Quit", isEnabled: false)]], previousFocusID: "trigger")
        model.open(menu: 0); XCTAssertEqual(model.handle(.down), nil); XCTAssertEqual(model.handle(.enter), "new"); _ = model.handle(.escape); XCTAssertNil(model.menuIndex)
    }
    func testShortcutConflictUsesFirstEnabledCommand() {
        var model = MenubarModel(menus: [[MenuCommand(id: "one", title: "One", shortcut: "o")], [MenuCommand(id: "two", title: "Two", shortcut: "o")]])
        XCTAssertEqual(model.handle(.character("O")), "one")
    }
}
