import Foundation

/// Manages lifecycle-scoped asynchronous tasks and appear/disappear triggers for a mounted node.
/// Guaranteed to cancel running tasks immediately upon node unmount or when effect IDs change.
@MainActor
public final class EffectScope {
    public enum CancellationReason: String, Sendable {
        case unmounted = "Node unmounted"
        case idChanged = "Effect ID changed"
        case replaced = "Task replaced"
        case userCancelled = "Cancelled"
    }

    public private(set) var activeTasks: [String: Task<Void, Never>] = [:]
    public private(set) var lastCancellationReasons: [String: CancellationReason] = [:]
    public var onAppearActions: [() -> Void] = []
    public var onDisappearActions: [() -> Void] = []
    public var errorHandler: ((Error) -> Void)?

    public init() {}

    /// Runs all registered `.onAppear` handlers.
    public func triggerAppear() {
        for action in onAppearActions {
            action()
        }
    }

    /// Runs all registered `.onDisappear` handlers.
    public func triggerDisappear() {
        for action in onDisappearActions {
            action()
        }
    }

    /// Spawns or restarts an asynchronous effect identified by `id`.
    /// If a task with the same `id` is already running, it is cancelled before the new one starts.
    @discardableResult
    public func task(
        id: String = "default",
        priority: TaskPriority = .userInitiated,
        _ action: @Sendable @escaping () async throws -> Void
    ) -> Task<Void, Never> {
        if let existing = activeTasks[id] {
            lastCancellationReasons[id] = .idChanged
            existing.cancel()
        }

        let task = Task(priority: priority) { [weak self] in
            do {
                try await action()
                _ = await MainActor.run { [weak self] in
                    self?.activeTasks.removeValue(forKey: id)
                }
            } catch is CancellationError {
                _ = await MainActor.run { [weak self] in
                    self?.activeTasks.removeValue(forKey: id)
                }
            } catch {
                _ = await MainActor.run { [weak self] in
                    self?.activeTasks.removeValue(forKey: id)
                    self?.errorHandler?(error)
                }
            }
        }


        activeTasks[id] = task
        return task
    }

    /// Cancels a specific task by id with a recorded reason.
    public func cancel(id: String, reason: CancellationReason = .userCancelled) {
        if let existing = activeTasks.removeValue(forKey: id) {
            lastCancellationReasons[id] = reason
            existing.cancel()
        }
    }

    /// Cancels all running effects and records cancellation reason.
    public func cancelAll(reason: CancellationReason = .unmounted) {
        for (id, task) in activeTasks {
            lastCancellationReasons[id] = reason
            task.cancel()
        }
        activeTasks.removeAll()
    }
}
