import XCTest
@testable import PrismCore

final class ChartModelTests: XCTestCase {
    func testNormalizationDecimationHitTestAndExport() { let model = ChartModel(kind: .line, series: [ChartSeries(id: "s", label: "S", points: [ChartPoint(x: 0, y: 1), ChartPoint(x: .nan, y: 2), ChartPoint(x: 2, y: 3)])]); let normalized = model.normalized(); XCTAssertEqual(normalized.series[0].points.count, 2); XCTAssertEqual(normalized.decimated(maxPoints: 2).series[0].points.count, 2); XCTAssertEqual(normalized.hitTest(x: 2.1, y: 3, tolerance: 1)?.x, 2); XCTAssertTrue(normalized.csv().contains("series,x,y")) }
    func testBarPieEmptyAndOutlierSafety() { let empty = ChartModel(kind: .bar, series: [ChartSeries(id: "x", label: "X", points: [ChartPoint(x: .infinity, y: 1)])]); XCTAssertTrue(empty.normalized().series[0].points.isEmpty); XCTAssertNil(empty.hitTest(x: 0, y: 0, tolerance: 1)); let pie = ChartModel(kind: .pie, series: []); XCTAssertEqual(pie.accessibilityTable().count, 1) }
}
