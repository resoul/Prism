import XCTest
@testable import PrismCore

final class DataGridInteractionsTests: XCTestCase {
    func testSelectionSurvivesSortAndFilterRows() { var model = DataGridInteractionModel(rowIDs: [1, 2, 3]); model.toggleSelection(2); model.setSort([GridSortDescriptor(key: "name")]); model.setFilters([GridFilterDescriptor(key: "status", value: "active")]); model.replaceRows([3, 2]); XCTAssertEqual(model.selectedIDs, [2]); model.replaceRows([3]); XCTAssertTrue(model.selectedIDs.isEmpty) }
    func testStaleProviderResponseDropped() async throws { let provider = DataGridInteractionProvider<Int> { sort, _ in if sort.first?.key == "old" { try await Task.sleep(nanoseconds: 50_000_000) }; return [sort.first?.key == "new" ? 2 : 1] }; await provider.load(sort: [GridSortDescriptor(key: "old")]); await provider.load(sort: [GridSortDescriptor(key: "new")]); try await Task.sleep(nanoseconds: 80_000_000); let rows = await provider.snapshot(); XCTAssertEqual(rows, [2]) }
}
