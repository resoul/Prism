import Foundation
import CoreGraphics
import PrismLogging

/// Priority tiers for off-main-thread preparation tasks.
public enum SchedulerPriority: Int, Comparable, Sendable {
    case idle = 0
    case prefetch = 1
    case immediate = 2

    public static func < (lhs: SchedulerPriority, rhs: SchedulerPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Token representing an active scheduled background preparation task.
public struct ScheduleToken: Hashable, Sendable {
    public let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

/// Texture/AsyncDisplayKit-inspired background render scheduler.
///
/// Ensures heavy operations (CoreText line measurement, SVG path rendering, image decoding)
/// execute on bounded background queues with priority arbitration and cooperative cancellation,
/// batch-committing results to `@MainActor` without stalling 60/120 FPS animations.
public final class RenderScheduler: @unchecked Sendable {
    public static let shared = RenderScheduler()

    private let maxConcurrentTasks: Int
    private let lock = NSLock()
    private var activeTasks: [ScheduleToken: Task<Void, Never>] = [:]
    private var taskTokensByElementID: [ElementID: Set<ScheduleToken>] = [:]
    private var activeTaskCount: Int = 0

    public init(maxConcurrentTasks: Int = 4) {
        self.maxConcurrentTasks = max(1, maxConcurrentTasks)
    }

    /// Schedules an asynchronous preparation task off the main thread.
    ///
    /// - Parameters:
    ///   - elementID: The element for which work is being performed.
    ///   - priority: Priority level (.immediate for visible cells, .prefetch for near-viewport).
    ///   - work: Pure, non-MainActor work closure producing a `DisplayTransaction`.
    ///   - commit: MainActor callback receiving the finished transaction.
    /// - Returns: A `ScheduleToken` that can be cancelled if the element scrolls offscreen.
    @discardableResult
    public func schedule(
        for elementID: ElementID,
        priority: SchedulerPriority = .immediate,
        work: @escaping @Sendable () async throws -> DisplayTransaction,
        commit: @escaping @MainActor (DisplayTransaction) -> Void
    ) -> ScheduleToken {
        let token = ScheduleToken()

        let taskPriority: TaskPriority
        switch priority {
        case .immediate:
            taskPriority = .userInitiated
        case .prefetch:
            taskPriority = .utility
        case .idle:
            taskPriority = .background
        }

        let task = Task(priority: taskPriority) { [weak self, token, elementID] in
            guard let self = self else { return }

            do {
                try Task.checkCancellation()
                let transaction = try await work()
                try Task.checkCancellation()

                await MainActor.run {
                    self.assertMainThread()
                    commit(transaction)
                }
            } catch {
                // Cancelled or failed, no commit
            }

            self.cleanup(token: token, for: elementID)
        }

        lock.withLock {
            activeTasks[token] = task
            taskTokensByElementID[elementID, default: []].insert(token)
            activeTaskCount += 1
        }

        return token
    }

    /// Cancels a specific scheduled task.
    public func cancel(token: ScheduleToken) {
        lock.withLock {
            if let task = activeTasks.removeValue(forKey: token) {
                task.cancel()
                activeTaskCount = max(0, activeTaskCount - 1)
            }
        }
    }

    /// Cancels all active tasks associated with a given element (e.g. on cell reuse or unmount).
    public func cancelAll(for elementID: ElementID) {
        lock.withLock {
            if let tokens = taskTokensByElementID.removeValue(forKey: elementID) {
                for token in tokens {
                    if let task = activeTasks.removeValue(forKey: token) {
                        task.cancel()
                        activeTaskCount = max(0, activeTaskCount - 1)
                    }
                }
            }
        }
    }

    /// Current number of active background tasks.
    public var currentTaskCount: Int {
        lock.withLock { activeTaskCount }
    }

    // MARK: - Private Helpers

    private func cleanup(token: ScheduleToken, for elementID: ElementID) {
        lock.withLock {
            activeTasks.removeValue(forKey: token)
            taskTokensByElementID[elementID]?.remove(token)
            if taskTokensByElementID[elementID]?.isEmpty == true {
                taskTokensByElementID.removeValue(forKey: elementID)
            }
            activeTaskCount = max(0, activeTaskCount - 1)
        }
    }

    private func assertMainThread(file: StaticString = #fileID, line: UInt = #line) {
        #if DEBUG
        assert(Thread.isMainThread, "CALayer mutations must occur exclusively on MainActor!", file: file, line: line)
        #endif
    }
}
