import XCTest
@testable import PrismCore

private struct MockItem: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
}

final class PagedStoreTests: XCTestCase {

    // MARK: - Loadable Tests

    func testLoadableStateTransitionsAndMapping() {
        var state: Loadable<String> = .idle
        XCTAssertTrue(state.isIdle)
        XCTAssertNil(state.value)
        XCTAssertNil(state.previousValue)

        // Loading
        state = .loading(previous: nil)
        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.isRefreshing)
        XCTAssertNil(state.value)

        // Loaded
        state = .loaded("Prism")
        XCTAssertTrue(state.isSuccess)
        XCTAssertEqual(state.value, "Prism")
        XCTAssertNil(state.previousValue)

        // Refreshing
        state = .refreshing(previous: "Prism")
        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isRefreshing)
        XCTAssertEqual(state.value, "Prism")
        XCTAssertEqual(state.previousValue, "Prism")

        // Failure with previous
        let error = LoadableError(code: .network, message: "Connection lost")
        state = .failure(error: error, previous: "Prism")
        XCTAssertTrue(state.isFailure)
        XCTAssertEqual(state.value, "Prism")
        XCTAssertEqual(state.previousValue, "Prism")
        XCTAssertEqual(state.error?.code, .network)

        // Mapping
        let lengthState = state.map { $0.count }
        XCTAssertEqual(lengthState.value, 5)
        XCTAssertEqual(lengthState.error?.code, .network)
    }

    func testLoadableErrorClassificationAndDescription() {
        let err = LoadableError(code: .timeout, message: "Request timed out", debugDetails: "NSURLErrorDomain:-1001")
        XCTAssertEqual(err.code, .timeout)
        XCTAssertTrue(err.description.contains("timeout"))
        XCTAssertTrue(err.description.contains("-1001"))

        let cancelErr = LoadableError(from: CancellationError())
        XCTAssertEqual(cancelErr.code, .cancelled)

        let nsErr = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        let networkErr = LoadableError(from: nsErr)
        XCTAssertEqual(networkErr.code, .network)
    }

    // MARK: - PagedStore Tests

    @MainActor
    func testInitialLoadSuccessAndCursor() async throws {
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            XCTAssertEqual(query, "posts")
            XCTAssertNil(cursor)
            return PageResult(
                items: [MockItem(id: "1", title: "Item 1"), MockItem(id: "2", title: "Item 2")],
                nextCursor: 2,
                totalCount: 10
            )
        }

        let store = PagedStore(query: "posts", loader: loader)
        XCTAssertFalse(store.hasMorePages)
        XCTAssertEqual(store.items.count, 0)

        store.loadInitial()
        XCTAssertTrue(store.currentState.isInitialLoading)

        // Yield to allow async Task to execute
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertFalse(store.currentState.isInitialLoading)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].title, "Item 1")
        XCTAssertEqual(store.items[1].title, "Item 2")
        XCTAssertEqual(store.currentState.nextCursor, 2)
        XCTAssertEqual(store.currentState.totalCount, 10)
        XCTAssertTrue(store.hasMorePages)

        // Verify Flux stream received the updated state
        let streamValue = await store.state.value
        XCTAssertEqual(streamValue.items.count, 2)
    }

    @MainActor
    func testNextPageAppendAndHasMore() async throws {
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            if cursor == nil {
                return PageResult(
                    items: [MockItem(id: "1", title: "Item 1")],
                    nextCursor: 2
                )
            } else if cursor == 2 {
                return PageResult(
                    items: [MockItem(id: "2", title: "Item 2")],
                    nextCursor: nil // End reached
                )
            }
            throw LoadableError(code: .notFound, message: "Invalid cursor")
        }

        let store = PagedStore(query: "posts", loader: loader)
        store.loadInitial()
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertTrue(store.hasMorePages)

        // Load next page
        store.loadNextPage()
        XCTAssertTrue(store.currentState.isLoadingNextPage)
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertFalse(store.currentState.isLoadingNextPage)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[1].title, "Item 2")
        XCTAssertFalse(store.hasMorePages) // nextCursor == nil

        // Subsequent loadNextPage does nothing because nextCursor is nil
        store.loadNextPage()
        XCTAssertFalse(store.currentState.isLoadingNextPage)
    }

    @MainActor
    func testDeduplicationConcurrentLoadNextPage() async throws {
        let counter = Counter()

        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return PageResult(items: [MockItem(id: "next", title: "Next")], nextCursor: nil)
        }

        let store = PagedStore(query: "test", loader: loader, initialState: PagedState(
            items: [MockItem(id: "0", title: "Initial")],
            nextCursor: 1
        ))

        // Trigger 10 rapid concurrent prefetch calls
        for _ in 0..<10 {
            store.loadNextPage()
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        let totalCalls = await counter.count
        XCTAssertEqual(totalCalls, 1, "Repeated concurrent loadNextPage calls must trigger exactly 1 request")
        XCTAssertEqual(store.items.count, 2)
    }

    @MainActor
    func testStableIDMerging() async throws {
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            if cursor == nil {
                return PageResult(
                    items: [
                        MockItem(id: "1", title: "Original 1"),
                        MockItem(id: "2", title: "Original 2")
                    ],
                    nextCursor: 2
                )
            } else {
                // Return overlapping item "2" with updated title and new item "3"
                return PageResult(
                    items: [
                        MockItem(id: "2", title: "Updated 2"),
                        MockItem(id: "3", title: "New 3")
                    ],
                    nextCursor: nil
                )
            }
        }

        let store = PagedStore(query: "merge", loader: loader)
        store.loadInitial()
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(store.items.count, 2)

        store.loadNextPage()
        try await Task.sleep(nanoseconds: 50_000_000)

        // Count should be 3, with item 2 updated in place, no duplicates
        XCTAssertEqual(store.items.count, 3)
        XCTAssertEqual(store.items.map(\.id), ["1", "2", "3"])
        XCTAssertEqual(store.items[1].title, "Updated 2")
        XCTAssertEqual(store.items[2].title, "New 3")
    }

    @MainActor
    func testRefreshWithStaleContent() async throws {
        let counter = Counter()
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            await counter.increment()
            let count = await counter.count
            if count == 1 {
                return PageResult(items: [MockItem(id: "1", title: "V1")], nextCursor: nil)
            } else {
                // Refresh failure
                throw LoadableError(code: .serverError, message: "500 Internal Error")
            }
        }

        let store = PagedStore(query: "refresh", loader: loader)
        store.loadInitial()
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].title, "V1")

        // Trigger refresh
        store.refresh()
        XCTAssertTrue(store.currentState.isRefreshing)
        // Stale items must remain available during refresh
        XCTAssertEqual(store.items.count, 1)

        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(store.currentState.isRefreshing)
        // Refresh failed, but stale items are preserved!
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].title, "V1")
        XCTAssertEqual(store.currentState.refreshError?.code, .serverError)
    }

    @MainActor
    func testStaleQueryResponseProtection() async throws {
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            if query == "slow" {
                // Slow response from old query
                try await Task.sleep(nanoseconds: 80_000_000)
                return PageResult(items: [MockItem(id: "slow", title: "Slow Old Item")], nextCursor: nil)
            } else {
                // Fast response from new query
                try await Task.sleep(nanoseconds: 20_000_000)
                return PageResult(items: [MockItem(id: "fast", title: "Fast New Item")], nextCursor: nil)
            }
        }

        let store = PagedStore(query: "slow", loader: loader)
        store.loadInitial()

        // Almost immediately switch query to "fast"
        try await Task.sleep(nanoseconds: 10_000_000)
        store.updateQuery("fast", reload: true)

        // Wait for both tasks to resolve
        try await Task.sleep(nanoseconds: 120_000_000)

        // Only the "fast" item from the latest generation should be present
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.id, "fast")
        XCTAssertEqual(store.items.first?.title, "Fast New Item")
    }

    @MainActor
    func testCancellation() async throws {
        let loader = AnyPageLoader<MockItem, String, Int> { query, cursor, pageSize in
            try await Task.sleep(nanoseconds: 100_000_000)
            return PageResult(items: [MockItem(id: "1", title: "Item")], nextCursor: nil)
        }

        let store = PagedStore(query: "cancel", loader: loader)
        store.loadInitial()
        XCTAssertTrue(store.currentState.isInitialLoading)

        store.cancel()
        XCTAssertFalse(store.currentState.isInitialLoading)

        try await Task.sleep(nanoseconds: 120_000_000)
        // Ensure no items were set after cancellation
        XCTAssertEqual(store.items.count, 0)
    }
}

// MARK: - Helper Actor

private actor Counter {
    var count = 0
    func increment() {
        count += 1
    }
}
