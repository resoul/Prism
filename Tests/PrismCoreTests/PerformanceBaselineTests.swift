import XCTest
@testable import PrismCore
@testable import PrismUI

final class PerformanceBaselineTests: XCTestCase {
    func testTenThousandVirtualizationSoakStaysBounded() {
        let start = DispatchTime.now().uptimeNanoseconds
        var maximumRendered = 0
        for offset in stride(from: 0.0, through: 430_000.0, by: 4_300.0) {
            let window = VirtualizationWindow.compute(
                totalCount: 10_000,
                viewportLength: 800,
                scrollOffset: offset,
                estimatedItemLength: 44,
                overscanFactor: 1
            )
            maximumRendered = max(maximumRendered, window.renderedRange.count)
        }
        let elapsedMS = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
        XCTAssertLessThanOrEqual(maximumRendered, 60)
        XCTAssertLessThan(elapsedMS, 2_000, "sanity budget for the deterministic host-independent soak")
        print("PERF baseline=virtualization-10k elapsed_ms=\(String(format: "%.2f", elapsedMS)) max_rendered=\(maximumRendered)")
    }

    @MainActor
    func testHundredToastQueueReturnsToBaseline() {
        let center = ToastCenter(maximumVisible: 3)
        let start = DispatchTime.now().uptimeNanoseconds
        for index in 0..<100 {
            center.enqueue(ToastItem(title: "Toast \(index)", deduplicationKey: "toast-\(index)"))
        }
        XCTAssertEqual(center.visible.count, 3)
        XCTAssertEqual(center.pending.count, 97)
        center.dismissAll()
        let elapsedMS = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
        XCTAssertTrue(center.visible.isEmpty)
        XCTAssertTrue(center.pending.isEmpty)
        XCTAssertLessThan(elapsedMS, 500)
        print("PERF baseline=toast-100 elapsed_ms=\(String(format: "%.2f", elapsedMS)) visible_after=\(center.visible.count) pending_after=\(center.pending.count)")
    }

    func testCatalogThemeChurnKeepsTreeSizeStable() {
        let store = PrismCatalogStore()
        let host = PrismCatalogHost(store: store)
        let baselineChildren = host.render().children.count
        let start = DispatchTime.now().uptimeNanoseconds
        for index in 0..<100 {
            store.setTheme(index.isMultiple(of: 2) ? "light" : "dark")
            _ = host.render()
        }
        let elapsedMS = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
        XCTAssertEqual(host.render().children.count, baselineChildren)
        XCTAssertLessThan(elapsedMS, 2_000)
        print("PERF baseline=theme-churn-100 elapsed_ms=\(String(format: "%.2f", elapsedMS)) root_children=\(baselineChildren)")
    }
}
