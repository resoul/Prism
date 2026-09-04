import XCTest
@testable import PrismCore

final class RenderSchedulerTests: XCTestCase {

    @MainActor
    func testScheduleAndCommitExecution() async throws {
        let scheduler = RenderScheduler(maxConcurrentTasks: 2)
        let elementID = ElementID(typeName: "Cell")

        var committedTransaction: DisplayTransaction?
        let expectation = expectation(description: "Work committed on MainActor")

        scheduler.schedule(
            for: elementID,
            priority: .immediate,
            work: {
                XCTAssertFalse(Thread.isMainThread, "Background task must run off main thread!")
                return DisplayTransaction(
                    elementID: elementID,
                    customPayload: ["status": "ready"]
                )
            },
            commit: { transaction in
                XCTAssertTrue(Thread.isMainThread, "Commit must execute on MainActor!")
                committedTransaction = transaction
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(committedTransaction?.customPayload["status"], "ready")
    }

    @MainActor
    func testTaskCancellationPreventsCommit() async throws {
        let scheduler = RenderScheduler(maxConcurrentTasks: 2)
        let elementID = ElementID(typeName: "CancelledCell")

        var didCommit = false

        let token = scheduler.schedule(
            for: elementID,
            priority: .prefetch,
            work: {
                try await Task.sleep(nanoseconds: 100_000_000)
                return DisplayTransaction(elementID: elementID)
            },
            commit: { _ in
                didCommit = true
            }
        )

        // Cancel immediately
        scheduler.cancel(token: token)

        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertFalse(didCommit, "Cancelled background task must never invoke commit callback")
    }

    @MainActor
    func testCancelAllForElementID() async throws {
        let scheduler = RenderScheduler(maxConcurrentTasks: 4)
        let elementID = ElementID(typeName: "RecycledCell")

        var commitCount = 0

        scheduler.schedule(
            for: elementID,
            priority: .idle,
            work: {
                try await Task.sleep(nanoseconds: 80_000_000)
                return DisplayTransaction(elementID: elementID)
            },
            commit: { _ in
                commitCount += 1
            }
        )

        scheduler.cancelAll(for: elementID)

        try await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(commitCount, 0, "cancelAll must abort all tasks for that element ID")
    }
}
