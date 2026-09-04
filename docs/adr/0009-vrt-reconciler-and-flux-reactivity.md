# ADR 0009: VRT Reconciler, MountedNode Lifecycle, and Flux-Driven Reactivity

## Status
Accepted

## Context
Prism builds declarative user interfaces out of pure, immutable `RenderElement` value trees. Rebuilding and tearing down the underlying `CALayer` display tree on every state update is inefficient, causes visual flickering, and leaks animation state. A reconciliation subsystem is required to diff immutable element trees, perform minimal surgical updates on persistent `MountedNode`s, preserve CALayer identities, and connect seamlessly to Flux state holders (`CurrentValue`, `CurrentValueDistinct`) with automatic lifecycle-scoped cancellation.

## Decision
1. **Persistent `MountedNode` Hierarchy:**
   - Lives on `@MainActor` and acts as the bridge between immutable `RenderElement` definitions and mutable `LayerRenderer`/`CALayer` instances.
   - Retains element identity (`ElementID`), parent/child relationships, and an isolated `SubscriptionBag` for Flux subscriptions.
   - Guaranteed lifecycle: `mount(in:)`, `update(newElement:frame:context:)`, and `unmount()`.
2. **Minimal Patch Diffing (`Reconciler.diff`):**
   - **Keyed Sibling Matching:** Elements with identical `ElementID.key` are matched across reorders. If the structural element kind matches, it produces `.update` (and `.move` if index changed), reusing the underlying `CALayer` without recreation. If element kind differs, it produces `.replace`.
   - **Unkeyed Sibling Fallback:** Matched sequentially by sibling index. Emits a diagnostic warning if unkeyed mutations/reordering occur.
   - **Duplicate Key Detection:** Scans sibling elements for duplicate keys and reports diagnostic warnings to prevent undefined reconciliation behavior.
   - **Removals and Insertions:** Unmatched old nodes produce `.remove` (calling `unmount()`), while new elements produce `.insert`.
3. **Topological Order of Patch Execution:**
   - Removals executed first (`unmount()`, `cancelAll()`, and layer detachment).
   - Replacements and updates executed in-place with layer reuse.
   - Insertions mounted and attached.
   - Two-pass layout engine resolves updated layout frames.
   - Final frames committed to renderers inside `RenderTransaction.perform(disableActions: true)`.
4. **Flux State Binding & Update Coalescing:**
   - `MountedNode.bind(to:)` binds `CurrentValue<T>` or `CurrentValueDistinct<T>` using `sinkOnMain`, automatically registering subscriptions into `node.subscriptionBag`.
   - High-frequency rapid state mutations are coalesced via `UpdateCoalescer` onto the next microtask/turn, ensuring that 100 rapid state updates execute in a single render pass while strictly preserving the final settled value.
   - When a node is unmounted, all retained subscriptions in `subscriptionBag` and pending coalescer actions are cancelled immediately.

## Consequences
- **Positive:** In-place CALayer reuse across state updates prevents layer count inflation and unnecessary object allocations.
- **Positive:** Zero subscription or layer leaks when elements enter and exit the mounted tree.
- **Positive:** Resilient against high-frequency state updates through microtask coalescing.
- **Trade-off:** Diffing keyed lists requires building index lookups, adding a minor CPU pass for large dynamic sibling arrays.
