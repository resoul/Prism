# DataGrid Interactions (P3)

Keep selection keyed by stable row IDs while changing descriptors:

```swift
var model = DataGridInteractionModel(rowIDs: rowIDs)
model.toggleSelection(rowID)
model.setSort([GridSortDescriptor(key: "name")])
model.setFilters([GridFilterDescriptor(key: "status", value: "active")])
```

Use `DataGridInteractionProvider` for cancellable loads; stale responses are dropped by generation. Selection survives reorder and is removed only when a row ID disappears.

## Extending

Translate descriptors in the repository layer, preserve IDs across pages, and map keyboard/AX navigation to IDs. Cancel providers on unmount or query replacement.

## Limitations

No inline editing, backend predicate execution, pagination policy, or native grid view is included.
