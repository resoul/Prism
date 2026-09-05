# Tree (P3)

Build a stable-ID hierarchy and window visible rows for large trees:

```swift
var model = TreeModel(nodes: nodes, roots: rootIDs)
model.toggle(folderID)
let rows = model.visibleNodes(offset: scrollOffset, limit: 60)
```

Use `LazyTreeLoader` for async children and cancel on unmount or ancestry changes. Keyboard hosts can move to parent/child IDs, while AX adapters expose each node's `level` and expanded state.

## Extending

Keep parent IDs and IDs stable across updates, sort children deterministically, and retain focus by ID. Use bounded windows for 10k-node datasets and make providers cancellation-aware.

## Limitations

No drag/drop, native tree view, persistence, or remote transport is included. Provider errors are intentionally host-mapped rather than logged by the core model.
