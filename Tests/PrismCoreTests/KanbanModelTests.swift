import XCTest
@testable import PrismCore

final class KanbanModelTests: XCTestCase {
    func testCrossColumnMoveAndCommit() { var model = KanbanModel(columns: ["todo", "done"], cards: [KanbanCard(id: "a", columnID: "todo", title: "A"), KanbanCard(id: "b", columnID: "todo", title: "B")]); model.beginMove(cardID: "a"); XCTAssertTrue(model.move(cardID: "a", toColumn: "done", index: 0)); model.commitMove(); XCTAssertEqual(model.cards.first { $0.id == "a" }?.columnID, "done"); XCTAssertFalse(model.isMoving) }
    func testCancellationDataUpdateAndVirtualizedCards() { var model = KanbanModel(columns: ["todo"], cards: (0..<10_000).map { KanbanCard(id: "\($0)", columnID: "todo", title: "Card") }); model.beginMove(cardID: "1"); _ = model.move(cardID: "1", toColumn: "todo", index: 9_999); model.applyDataUpdate(Array(model.cards.dropLast())); model.cancelMove(); XCTAssertLessThanOrEqual(model.visibleCards(in: "todo", offset: 9_990, limit: 20).count, 10) }
}
