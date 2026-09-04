# Reconciler & Flux-Driven Reactivity Guide

This guide describes how Prism diffs declarative Virtual Render Trees (VRT), manages persistent `MountedNode`s, synchronizes CALayer hierarchies with zero duplicate layer allocations, and binds reactive state from Flux.

---

## 1. Architectural Overview

```
┌─────────────────────────────────┐
│ Reactive State (Flux)           │ CurrentValue / CurrentValueDistinct
└────────────────┬────────────────┘
                 │ emits update on MainActor
                 ▼
┌─────────────────────────────────┐
│ UpdateCoalescer                 │ Microtask-level update batching
└────────────────┬────────────────┘
                 │ triggers reconcile pass
                 ▼
┌─────────────────────────────────┐
│ Reconciler.diff                 │ Computes minimal NodePatch set
└────────────────┬────────────────┘
                 │ in-place update, insert, remove, move
                 ▼
┌─────────────────────────────────┐
│ MountedNode Tree                │ Persistent nodes with owned CALayer
└────────────────┬────────────────┘
                 │ layout pass & frame assignment
                 ▼
┌─────────────────────────────────┐
│ CALayer Renderers               │ Reused layers updated with zero leaks
└─────────────────────────────────┘
```

---

## 2. MountedNode Lifecycle

A `MountedNode` represents a live, persistent entity in the mounted render tree:

- **Identity**: Retains a stable `ElementID` (`typeName`, `key`, `siblingIndex`).
- **Layer Ownership**: Owns a `LayerRenderer` and its `rootLayer`.
- **Subscriptions**: Retains an isolated `SubscriptionBag`.
- **Lifecycle Methods**:
  - `mount(in:superlayer:)`: Attaches to parent node and inserts `rootLayer` into the superlayer.
  - `update(newElement:frame:context:)`: Updates element props and frame without destroying the `CALayer`.
  - `unmount()`: Automatically cancels all active subscriptions, destroys renderers, and removes layers.

---

## 3. Reconciler Diffing & Patching

### Patch Operations

`Reconciler.diff(current:elements:)` analyzes the current `[MountedNode]` against the new `[RenderElement]` to emit:

- `.update(node, newElement)`: In-place update preserving layer identity.
- `.insert(element, atIndex)`: Instantiates and mounts a new node.
- `.remove(node, fromIndex)`: Tears down and unmounts the deleted node.
- `.move(node, fromIndex, toIndex)`: Repositions an existing node.
- `.replace(oldNode, newElement, atIndex)`: Unmounts the old node and mounts a new node when the element kind changes.

### Keyed vs Unkeyed Siblings

- **Keyed Matching**: When elements have explicit `.key(...)`, the reconciler tracks nodes across reordering, list insertions, and removals.
- **Duplicate Key Warnings**: If sibling elements contain identical keys, `diff.warnings` captures a warning to prevent unexpected reordering behavior.
- **Unkeyed Sibling Fallback**: Unkeyed elements are matched by sequential slot index. Mutations to unkeyed elements emit an unkeyed reorder warning.

---

## 4. Reactive State Binding with Flux

### Binding to CurrentValue / CurrentValueDistinct

Use `node.bind(to:update:)` to observe reactive state holders:

```swift
let counter = CurrentValueDistinct<Int>(0)

// In your mounted component:
node.bind(to: counter) { node, value in
    // Executed strictly on MainActor when counter changes
    let newElement = Text("Count: \(value)")
    node.update(newElement: newElement, frame: node.renderer.rootLayer.frame.asLayoutFrame, context: .default)
}
```

### Rapid Update Coalescing

When hundreds of state updates arrive in a tight loop, `UpdateCoalescer` automatically coalesces them onto the next microtask turn:
- Redundant intermediate render passes are dropped.
- The latest settled value is guaranteed to be applied.
- When the node is unmounted, subscriptions and scheduled updates are cancelled immediately.

---

## 5. Developer Diff Diagnostics

Inspect reconciliation diffs using `ReconcilerDiff`:

```swift
let diff = Reconciler.diff(current: parent.children, elements: newElements)
print(diff)
// Output:
// ReconcilerDiff(mounts: 1, updates: 2, unmounts: 1, moves: 1, reusedLayers: 2):
//   - UPDATE[Text[header]@0] -> Text("Updated Title")
//   - MOVE[Shape[box]@1] from 1 to 2
//   - INSERT[Text[badge]@1] at index 1
//   - REMOVE[Text[old_footer]@2] from index 2
```
