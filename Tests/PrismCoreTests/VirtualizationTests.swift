import XCTest
@testable import PrismCore
@testable import PrismUI

final class VirtualizationTests: XCTestCase {

    func testTenThousandRowsBoundedVirtualization() {
        let totalCount = 10_000
        let viewportHeight = 800.0
        let itemHeight = 44.0

        // At scroll offset 0
        let window = VirtualizationWindow.compute(
            totalCount: totalCount,
            viewportLength: viewportHeight,
            scrollOffset: 0.0,
            estimatedItemLength: itemHeight,
            overscanFactor: 1.0
        )

        // Visible rows in 800pt: ~19 rows (800 / 44 = 18.18)
        XCTAssertLessThanOrEqual(window.visibleRange.count, 20)
        XCTAssertEqual(window.visibleRange.lowerBound, 0)

        // Rendered rows (viewport + 1x overscan above and below = 1600pt): ~38 rows
        XCTAssertLessThanOrEqual(window.renderedRange.count, 40)
        XCTAssertEqual(window.renderedRange.lowerBound, 0)

        // Total content length for 10,000 items at 44pt is 440,000pt
        XCTAssertEqual(window.estimatedContentLength, 440_000.0)
    }

    func testVirtualizationWindowShiftOnScroll() {
        let totalCount = 1_000
        let viewportHeight = 600.0
        let itemHeight = 50.0

        // Scroll down to offset 2500 (item 50)
        let window = VirtualizationWindow.compute(
            totalCount: totalCount,
            viewportLength: viewportHeight,
            scrollOffset: 2500.0,
            estimatedItemLength: itemHeight,
            overscanFactor: 1.0
        )

        // Item at offset 2500 is index 50
        XCTAssertEqual(window.visibleRange.lowerBound, 50)
        // 600pt / 50 = 12 visible items (50..<62)
        XCTAssertEqual(window.visibleRange.count, 12)

        // With 1x overscan (600pt before = 12 items, 600pt after = 12 items)
        XCTAssertLessThanOrEqual(window.renderedRange.lowerBound, 38)
        XCTAssertGreaterThanOrEqual(window.renderedRange.upperBound, 74)
    }

    func testCellReusePoolLifecycleAndReset() {
        let pool = CellReusePool()
        XCTAssertEqual(pool.idleCount, 0)

        // Dequeue from empty pool returns nil (triggers new allocation)
        let element1 = pool.dequeue(reuseID: "RowCell")
        XCTAssertNil(element1)
        XCTAssertEqual(pool.allocatedCount, 1)

        // Create an element with transient state and recycle it
        var row = RenderElement(
            id: ElementID(typeName: "Row"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8)
        )
        row.props.custom["isSelected"] = "true"
        row.props.custom["isHighlighted"] = "true"

        pool.recycle(row, reuseID: "RowCell")
        XCTAssertEqual(pool.idleCount, 1)
        XCTAssertEqual(pool.recycledCount, 1)

        // Dequeue reused element
        let dequeued = pool.dequeue(reuseID: "RowCell")
        XCTAssertNotNil(dequeued)
        XCTAssertEqual(pool.reusedCount, 1)
        XCTAssertEqual(pool.idleCount, 0)

        // Verify transient attributes were reset
        XCTAssertNil(dequeued?.props.custom["isSelected"])
        XCTAssertNil(dequeued?.props.custom["isHighlighted"])
    }
}
