import Foundation
import PrismCore

/// Declarative UI component for rendering the lifecycle states of a `Loadable<Value>`.
///
/// Handles idle, loading, loaded, refreshing, and failure states with customizable builders,
/// retry action triggers, and accessibility attributes without owning network operations.
public struct Resource<Value: Sendable>: Component {
    private let loadable: Loadable<Value>
    private let retry: (@Sendable () -> Void)?
    private let contentBuilder: @Sendable (Value) -> RenderElement
    private let loadingBuilder: (@Sendable (Value?) -> RenderElement)?
    private let failureBuilder: (@Sendable (LoadableError, (@Sendable () -> Void)?) -> RenderElement)?
    private let emptyBuilder: (@Sendable () -> RenderElement)?

    /// Creates a `Resource` component with explicit state builders.
    ///
    /// - Parameters:
    ///   - loadable: The current `Loadable` state value.
    ///   - retry: Optional retry closure invoked upon user retry action.
    ///   - loading: Optional custom builder for the loading state (receives optional previous value).
    ///   - failure: Optional custom builder for failure state (receives error and retry closure).
    ///   - empty: Optional custom builder for the idle/empty state.
    ///   - content: Builder invoked when data is successfully loaded or refreshing.
    public init(
        _ loadable: Loadable<Value>,
        retry: (@Sendable () -> Void)? = nil,
        loading: (@Sendable (Value?) -> RenderElement)? = nil,
        failure: (@Sendable (LoadableError, (@Sendable () -> Void)?) -> RenderElement)? = nil,
        empty: (@Sendable () -> RenderElement)? = nil,
        content: @escaping @Sendable (Value) -> RenderElement
    ) {
        self.loadable = loadable
        self.retry = retry
        self.contentBuilder = content
        self.loadingBuilder = loading
        self.failureBuilder = failure
        self.emptyBuilder = empty
    }

    public func body(context: ComponentContext) -> RenderElement {
        switch loadable {
        case .idle:
            if let emptyBuilder = emptyBuilder {
                return emptyBuilder()
            }
            if let loadingBuilder = loadingBuilder {
                return loadingBuilder(nil)
            }
            return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)

        case .loading(let previous):
            if let loadingBuilder = loadingBuilder {
                return loadingBuilder(previous)
            }
            if let previous = previous {
                // Default: display stale content dimmed with accessibility hint
                return contentBuilder(previous)
                    .opacity(0.6)
                    .accessibilityHint("Reloading content")
            }
            // Default loading placeholder
            return VStack(spacing: 8) {
                Text("Loading...")
            }
            .render()
            .accessibilityLabel("Loading")
            .accessibilityTraits(.updatesFrequently)

        case .loaded(let value):
            return contentBuilder(value)

        case .refreshing(let previous):
            // By default, preserve the loaded content seamlessly during refresh
            return contentBuilder(previous)

        case .failure(let error, _):
            if let failureBuilder = failureBuilder {
                return failureBuilder(error, retry)
            }
            // Default failure view with retry button
            return VStack(spacing: 12) {
                Text("Error: \(error.message)")
                if let retry = retry {
                    Button("Retry", variant: .secondary) {
                        retry()
                    }
                }
            }
            .render()
            .accessibilityLabel("Error: \(error.message)")
        }
    }
}
