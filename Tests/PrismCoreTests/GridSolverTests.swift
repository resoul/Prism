import XCTest
@testable import PrismCore

final class GridSolverTests: XCTestCase {
    func testFractionTracksAndSpansResolveFiniteFrames() {
        let items = [
            GridPlacement(id: "a", column: 0, row: 0),
            GridPlacement(id: "b", column: 1, row: 0, columnSpan: 2, intrinsicHeight: 60)
        ]
        let result = GridLayoutSolver.resolve(columns: [.fraction(1), .fraction(2), .fixed(100)], items: items, width: 700, columnGap: 10, rowGap: 8)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.frame.rect.isNull == false && $0.frame.width.isFinite && $0.frame.height.isFinite })
        XCTAssertGreaterThan(result[1].frame.width, result[0].frame.width)
    }

    func testRTLMirrorsPlacementAndClampsInvalidSpans() {
        let item = GridPlacement(id: "rtl", column: 0, row: 1, columnSpan: 99, rowSpan: 0, intrinsicHeight: -1)
        let ltr = GridLayoutSolver.resolve(columns: [.fixed(100), .fixed(100)], items: [item], width: 220, columnGap: 10)
        let rtl = GridLayoutSolver.resolve(columns: [.fixed(100), .fixed(100)], items: [item], width: 220, columnGap: 10, rtl: true)
        XCTAssertEqual(ltr.first?.frame.width, 210)
        XCTAssertEqual(rtl.first?.frame.origin.x, 10)
        XCTAssertEqual(ltr.first?.frame.height, 0)
    }

}
