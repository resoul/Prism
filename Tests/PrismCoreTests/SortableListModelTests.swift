import XCTest
@testable import PrismCore

final class SortableListModelTests: XCTestCase {
    func testStableIDReorderKeyboardAndCommit() {
        var model = SortableListModel(ids: ["a", "b", "c"])
        model.begin(id: "b"); XCTAssertTrue(model.move(id: "b", to: 0)); model.keyboardMove(id: "b", by: 1); model.commit()
        XCTAssertEqual(model.ids, ["a", "b", "c"]); XCTAssertFalse(model.isReordering)
    }
    func testCancellationAndRemovedItemUpdate() {
        var model = SortableListModel(ids: Array(0..<10_000)); model.begin(id: 42); _ = model.move(id: 42, to: 0); model.applyDataUpdate(Array(0..<9_999)); model.cancel()
        XCTAssertFalse(model.ids.contains(9_999)); XCTAssertEqual(model.visibleIDs(offset: 9_990, limit: 20).count, 9)
    }
}
