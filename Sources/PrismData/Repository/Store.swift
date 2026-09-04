import Foundation
import struct Flux.Flux
import class Flux.Pipe

/// Base reactive store contract decoupling domain state management from UI presentation layers.
///
/// Invariant: Emits state changes strictly via Flux streams and never imports or invokes UI components.
public actor Store<State: Sendable> {
    private var _state: State
    private let pipe = Pipe<State>(bufferingPolicy: .bufferingNewest(32))

    public var state: State {
        _state
    }

    /// Reactive Flux stream emitting all subsequent state mutations.
    public nonisolated var stateFlux: Flux<State> {
        pipe.flux
    }

    public init(initialState: State) {
        self._state = initialState
    }

    /// Sets an entirely new state and notifies all active observers.
    public func update(_ newState: State) {
        self._state = newState
        pipe.send(newState)
    }

    /// Mutates the current state in-place and notifies observers.
    public func mutate(_ mutation: (inout State) -> Void) {
        mutation(&self._state)
        pipe.send(self._state)
    }
}
