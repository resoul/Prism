import Foundation
import Flux

/// Manages reactive state bindings connecting Flux state holders (`CurrentValue`, `CurrentValueDistinct`, `Flux`)
/// to target closures with automatic update coalescing on `@MainActor`.
@MainActor
public final class ReactiveBinding<T: Sendable> {
    public let coalescer: UpdateCoalescer = UpdateCoalescer()
    public private(set) var latestValue: T?

    public init() {}

    /// Binds a `CurrentValue` stream, invoking the update handler whenever the value changes.
    @discardableResult
    public func bind(
        state: CurrentValue<T>,
        update: @MainActor @escaping (T) -> Void
    ) -> Subscription {
        state.flux.sinkOnMain { [weak self] value in
            guard let self else { return }
            self.latestValue = value
            self.coalescer.schedule {
                update(value)
            }
        }
    }

    /// Binds a `CurrentValueDistinct` stream with automatic deduplication.
    @discardableResult
    public func bind(
        state: CurrentValueDistinct<T>,
        update: @MainActor @escaping (T) -> Void
    ) -> Subscription where T: Equatable {
        state.flux.sinkOnMain { [weak self] value in
            guard let self else { return }
            self.latestValue = value
            self.coalescer.schedule {
                update(value)
            }
        }
    }

    /// Binds any generic `Flux<T>` stream.
    @discardableResult
    public func bind(
        stream: Flux<T>,
        update: @MainActor @escaping (T) -> Void
    ) -> Subscription {
        stream.sinkOnMain { [weak self] value in
            guard let self else { return }
            self.latestValue = value
            self.coalescer.schedule {
                update(value)
            }
        }
    }

    /// Flushes any pending coalesced update immediately on MainActor.
    public func flush() {
        coalescer.flush()
    }
}
