# Sortable (P3)

Use `SortableListModel` with stable IDs and commit the resulting order to your controlled binding:

```swift
var model = SortableListModel(ids: itemIDs)
model.begin(id: draggedID)
_ = model.move(id: draggedID, to: destinationIndex)
model.commit() // or cancel() on gesture cancellation/unmount
let window = model.visibleIDs(offset: 0, limit: 50)
```

`applyDataUpdate` handles items removed while a reorder is active. Keyboard alternatives call `keyboardMove(id:by:)`; focus retention is keyed by the stable ID in the host adapter.

## Extending

Wrap the model in a host list that persists committed IDs, routes pointer/keyboard events, and autoscrolls only within the bounded visible window. Never use array offsets as identity.

## Limitations

This contract does not render item content, provide a persistence backend, or implement platform drag APIs. Cross-list transfers and server-side ordering are out of scope.
