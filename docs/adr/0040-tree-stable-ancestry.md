# ADR 0040: Tree Stable Ancestry

`TreeModel` stores stable IDs, parent IDs, levels, and expansion state. Visible rows are flattened in deterministic depth-first order and can be windowed with `visibleNodes(offset:limit:)`. `LazyTreeLoader` owns cancellable provider tasks and only applies completed children to the matching parent, leaving host focus keyed by ID.

Tree content and platform accessibility adapters remain outside the core model; drag-and-drop is intentionally deferred.
