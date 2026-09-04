# ADR 0010: Component State, Two-Way Binding, and Lifecycle-Scoped EffectScope

## Status
Accepted

## Context
Prism components are declarative, lightweight, immutable value descriptions (`Component`, `RenderElement`). While global and screen-level application state lives in Flux stores (`CurrentValue`, `CurrentValueDistinct`), UI components frequently need:
1. Ephemeral, local component state (e.g., expanded/collapsed toggles, transient form field draft text, hover states).
2. Two-way bindings (`Binding<Value>`) that bridge parent state or local component state to child inputs with lens-like projections and feedback loop prevention.
3. Asynchronous lifecycle-scoped tasks and side-effects (`.task(id:)`, `.onAppear`, `.onDisappear`) that automatically launch on mount and safely cancel on unmount or key replacement without leaking tasks or memory.
4. Clear architectural partitioning between state ownership tiers to prevent anti-patterns such as using local component state for application domain data or global stores for temporary UI toggles.

## Decision
1. **Component State Storage (`ComponentStateStore`):**
   - Retained per `MountedNode` identity using `(ElementID, stateKey)`.
   - Thread-safe underlying dictionary with `@MainActor`-isolated accessors.
   - Initial value computation runs once upon initial state access (`node.state(name:default:)`).
   - State survives parent re-renders when element identity is preserved.
   - Automatically purges when the `MountedNode` is unmounted or when its key/type changes during reconciliation.
2. **Two-Way Binding Abstraction (`Binding<Value>`):**
   - Encapsulates getter `() -> Value` and setter `(Value) -> Void`.
   - Supports `@dynamicMemberLookup` key-path projections (`binding.field`).
   - Supports transformation maps (`binding.map(get:set:)`), optional default fallbacks (`binding[default:]`), and collection subscripting (`binding[index]`).
   - Prevents recursive feedback loops via `setIfChanged(_:)` which validates `wrappedValue != newValue` before invoking mutation blocks.
3. **Lifecycle-Scoped Effects (`EffectScope`):**
   - Managed on each `MountedNode`.
   - Supports async tasks (`task(id:priority:operation:)`), executing them in structured Swift concurrency.
   - Automatic cancellation: Cancels previous tasks sharing the same ID with reason `.idChanged`.
   - Mount/Unmount hooks: Invokes `.onAppear` handlers during `MountedNode.mount()` and `.onDisappear` handlers during `MountedNode.unmount()`.
   - Unmount cleanup: Cancels all active tasks with reason `.unmounted` upon `MountedNode.unmount()`.
   - Unhandled async errors are captured and routed via `errorHandler`.
4. **State Ownership Tiers (`StateOwnershipTier`):**
   - Tier 1: `appStore` (Flux / domain state across routes).
   - Tier 2: `screenState` (Route / screen navigation container state via `ComponentContext.screenState`).
   - Tier 3: `componentState` (MountedNode local UI state via `ComponentStateStore`).
   - Tier 4: `keyedListItemState` (Stable-keyed virtualized list row state).
5. **State Diagnostics (`StateInspector`):**
   - Provides diagnostic introspection dumping active subscriptions, running async effects, and local component state keys for debug builds and test diagnostics.

## Consequences
- **Positive:** Components can manage local UI state cleanly without boilerplate Flux store declarations.
- **Positive:** Two-way bindings provide idiomatic property mutations while protecting against ping-pong update cycles.
- **Positive:** Asynchronous tasks are guaranteed to cancel on view departure, preventing memory leaks and orphaned background network calls.
- **Trade-off:** Component state is tied to `MountedNode` lifecycle and will reset if an element is unmounted or its explicit key changes.
