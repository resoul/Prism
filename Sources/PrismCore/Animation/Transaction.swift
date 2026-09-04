import Foundation

/// Transaction context governing animation properties during state mutations.
public struct Transaction: Sendable, Equatable {
    public var id: UUID
    public var animation: Animation?
    public var disablesAnimations: Bool
    public var isReduceMotionForced: Bool?

    public init(
        id: UUID = UUID(),
        animation: Animation? = nil,
        disablesAnimations: Bool = false,
        isReduceMotionForced: Bool? = nil
    ) {
        self.id = id
        self.animation = animation
        self.disablesAnimations = disablesAnimations
        self.isReduceMotionForced = isReduceMotionForced
    }

    /// Accesses the active ambient transaction in the current execution scope.
    public static var current: Transaction {
        TransactionContext.current
    }
}

/// Task-local transaction holder for structured transaction scoping.
public enum TransactionContext {
    @TaskLocal
    public static var current: Transaction = Transaction()
}

/// Global / ambient accessibility preference for motion reduction.
@MainActor
public enum ReduceMotionPreference {
    /// Global override flag, primarily used for testing or platform observer sync.
    public static var isEnabled: Bool = false

    /// Resolves whether motion reduction should be applied for the given transaction and render context.
    public static func shouldReduceMotion(
        transaction: Transaction? = nil,
        reduceMotionContext: Bool? = nil
    ) -> Bool {
        if let forced = transaction?.isReduceMotionForced {
            return forced
        }
        if let reduceMotionContext, reduceMotionContext {
            return true
        }
        return isEnabled
    }
}

/// Executes a closure within an animation transaction context.
///
/// If animations are already disabled in the ambient transaction, nested `withAnimation` calls
/// respect the suppression and will not trigger animations.
@discardableResult
@MainActor
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    let current = TransactionContext.current
    if current.disablesAnimations {
        return try body()
    }

    let effectiveAnimation: Animation?
    if ReduceMotionPreference.isEnabled && (current.isReduceMotionForced != false) {
        effectiveAnimation = nil
    } else {
        effectiveAnimation = animation
    }

    let nextTransaction = Transaction(
        id: UUID(),
        animation: effectiveAnimation,
        disablesAnimations: false,
        isReduceMotionForced: current.isReduceMotionForced
    )

    return try TransactionContext.$current.withValue(nextTransaction) {
        try body()
    }
}

/// Executes a closure within a specific explicit transaction.
@discardableResult
@MainActor
public func withTransaction<Result>(
    _ transaction: Transaction,
    _ body: () throws -> Result
) rethrows -> Result {
    let current = TransactionContext.current
    var resolved = transaction
    if current.disablesAnimations {
        resolved.disablesAnimations = true
        resolved.animation = nil
    }
    return try TransactionContext.$current.withValue(resolved) {
        try body()
    }
}
