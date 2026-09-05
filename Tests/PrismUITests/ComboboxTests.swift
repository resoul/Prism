import XCTest
@testable import PrismUI

final class ComboboxTests: XCTestCase {
    func testSearchKeyboardSelectionAndDisabledOptions() {
        var value = "a"
        let binding = Binding(get: { value }, set: { value = $0 })
        var combo = Combobox("Fruit", selection: binding, options: [SelectionOption("a", label: "Apple"), SelectionOption("b", label: "Berry", isDisabled: true), SelectionOption("c", label: "Cherry")])
        combo.search("ch")
        XCTAssertEqual(combo.filteredOptions.map(\.value), ["c"])
        XCTAssertTrue(combo.commitHighlighted()); XCTAssertEqual(value, "c")
        combo.open(); combo.moveHighlight(by: 1); XCTAssertTrue(combo.commitHighlighted()); XCTAssertEqual(value, "c")
        combo.select(SelectionOption("b", label: "Berry", isDisabled: true)); XCTAssertEqual(value, "c")
    }

    func testCancellationAndVirtualizedWindow() {
        var value = 0
        let binding = Binding(get: { value }, set: { value = $0 })
        let options = (0..<10_000).map { SelectionOption($0, label: "Item \($0)") }
        var combo = Combobox(selection: binding, options: options)
        XCTAssertEqual(combo.visibleOptions(offset: 9_990, limit: 20).count, 10)
        combo.search("Item 99"); combo.cancel()
        XCTAssertFalse(combo.isExpanded); XCTAssertEqual(combo.query, "")
    }
}
