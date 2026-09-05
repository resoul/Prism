import XCTest
@testable import PrismCore

final class DataGridViewportTests: XCTestCase {
    func testHundredThousandByHundredBoundedViewportAndPinnedHeaders() {
        var grid = DataGridViewport(rows: 100_000, columns: 100); grid.updateViewport(offsetX: 1_200, offsetY: 50_000, width: 800, height: 600, overscan: 1, pinnedRows: 1, pinnedColumns: 1)
        XCTAssertLessThan(grid.mountedCells.count, 1_000); XCTAssertTrue(grid.mountedCells.contains { $0.row == 0 }); XCTAssertTrue(grid.mountedCells.contains { $0.column == 0 })
    }
    func testVariableResizeAnchorAndAccessibilityCoordinate() {
        var grid = DataGridViewport(rows: 20, columns: 10); grid.resizeRow(2, extent: 80); grid.resizeColumn(3, extent: 200); grid.updateViewport(offsetX: 0, offsetY: 80, width: 300, height: 100)
        XCTAssertEqual(grid.scrollAnchor.row, 1); XCTAssertEqual(grid.accessibilityCoordinate(row: 2, column: 3), "row 3, column 4")
    }
}
