import XCTest
@testable import PrismCore
@testable import PrismUI

private final class MountTracker: @unchecked Sendable {
    var tabAInstantiated = false
    var tabBInstantiated = false
    var tabCInstantiated = false
}

final class CollapsingPagerIntegrationTests: XCTestCase {

    func testNeighbourMountPolicyActiveIndices() {
        let policy = NeighbourMountPolicy.immediateNeighbours

        // Total 5 pages (0, 1, 2, 3, 4)
        let set0 = policy.activeIndices(selected: 0, total: 5)
        XCTAssertEqual(set0, [0, 1])

        let set2 = policy.activeIndices(selected: 2, total: 5)
        XCTAssertEqual(set2, [1, 2, 3])
        XCTAssertFalse(set2.contains(0))
        XCTAssertFalse(set2.contains(4))

        let set4 = policy.activeIndices(selected: 4, total: 5)
        XCTAssertEqual(set4, [3, 4])
    }

    func testPagePagerMountsOnlyImmediateNeighbours() {
        let tracker = MountTracker()

        let pages = [
            TabPage(ProfileTab.posts) {
                tracker.tabAInstantiated = true
                return [RenderElement(id: ElementID(typeName: "PageA"), kind: .empty)]
            },
            TabPage(ProfileTab.likes) {
                tracker.tabBInstantiated = true
                return [RenderElement(id: ElementID(typeName: "PageB"), kind: .empty)]
            },
            TabPage(ProfileTab.reposts) {
                tracker.tabCInstantiated = true
                return [RenderElement(id: ElementID(typeName: "PageC"), kind: .empty)]
            }
        ]

        // When selected index is 0 (Posts)
        let pager = PagePager(pages: pages, selectedIndex: 0)
        let pagerElement = pager.body(context: .default)

        XCTAssertTrue(tracker.tabAInstantiated)
        XCTAssertTrue(tracker.tabBInstantiated)
        // Distant tab C (Reposts) MUST NOT be instantiated or mounted
        XCTAssertFalse(tracker.tabCInstantiated)
        XCTAssertEqual(pagerElement.children.count, 2)
    }

    @MainActor
    func testTenThousandItemsBenchmarkPaginationAndDeduplication() async {
        let store = ProfileDataBenchmark.makeSyntheticStore(category: "benchmark_posts", totalItems: 10_000, pageSize: 30)

        // 1. Initial load
        store.loadInitial()
        XCTAssertTrue(store.currentState.isInitialLoading)

        // Wait briefly for the task to complete
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(store.items.count, 30)
        XCTAssertFalse(store.currentState.isInitialLoading)
        XCTAssertTrue(store.hasMorePages)

        // 2. Multiple rapid prefetch calls must coalesce into a single page append
        store.loadNextPage()
        store.loadNextPage()
        store.loadNextPage()
        XCTAssertTrue(store.currentState.isLoadingNextPage)

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(store.items.count, 60)
        XCTAssertFalse(store.currentState.isLoadingNextPage)
    }

    @MainActor
    func testQueryGenerationProtectionPreventsStaleResponseMutation() async {
        let loader = AnyPageLoader<ProfileGridItem, String, Int> { query, cursor, count in
            // Simulate slow network query for query "slow"
            if query == "slow" {
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
            return PageResult(
                items: [ProfileGridItem(id: "\(query)_1", imageURL: URL(string: "https://example.com/1.jpg")!, title: "\(query) item")],
                nextCursor: nil
            )
        }

        let store = PagedStore(query: "slow", loader: loader)
        store.loadInitial()

        // Before slow query finishes, user changes query to "fast"
        try? await Task.sleep(nanoseconds: 10_000_000)
        store.updateQuery("fast", reload: true)

        try? await Task.sleep(nanoseconds: 120_000_000)

        // Items should reflect "fast", stale response from "slow" must not overwrite it
        XCTAssertEqual(store.query, "fast")
        XCTAssertEqual(store.items.first?.id, "fast_1")
    }
}
