# ADR 0037: Sortable Stable-ID Reorder

`SortableListModel` owns an ordered stable-ID array and an origin snapshot for cancellable reorders. Controlled consumers apply committed IDs to their binding; concurrent data updates replace the working IDs and naturally remove deleted items. Keyboard moves use the same reorder primitive, while `visibleIDs(offset:limit:)` bounds host rendering and autoscroll work.

Drag gestures, focus adapters, and persistence remain host/application responsibilities. No item content or platform view type is exposed.
