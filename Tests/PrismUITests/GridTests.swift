import XCTest
@testable import PrismUI

final class GridTests: XCTestCase {
    func testGridComponentCarriesResolvedContractMetadata() {
        let grid = Grid(columns: [.fraction(1), .fraction(1)], cells: [
            GridCell(id: "first", column: 0, row: 0, content: Text("First"))
        ], width: 320, columnGap: 8, rowGap: 8)
        let element = grid.render()
        XCTAssertEqual(element.props.custom["gridColumns"], "2")
        XCTAssertEqual(element.props.custom["gridCells"], "1")
        XCTAssertFalse(element.children.isEmpty)
    }
}
