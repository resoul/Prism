import Foundation

/// Coalesces high-frequency reactive state updates onto the next `@MainActor` cycle,
/// preventing redundant intermediate render passes while strictly guaranteeing that the latest value is applied.
@MainActor
public final class UpdateCoalescer {
    public private(set) var isScheduled: Bool = false
    private var pendingAction: (() -> Void)?

    public init() {}

    /// Schedules an update closure. If multiple updates are submitted before execution,
    /// only the most recent closure executes, coalescing all rapid updates.
    public func schedule(_ action: @escaping () -> Void) {
        pendingAction = action
        guard !isScheduled else { return }
        isScheduled = true

        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, self.isScheduled else { return }
            self.isScheduled = false
            let actionToRun = self.pendingAction
            self.pendingAction = nil
            actionToRun?()
        }
    }

    /// Synchronously flushes any pending coalesced update immediately on MainActor.
    public func flush() {
        guard isScheduled else { return }
        isScheduled = false
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    /// Cancels any scheduled update without executing it.
    public func cancel() {
        isScheduled = false
        pendingAction = nil
    }
}
