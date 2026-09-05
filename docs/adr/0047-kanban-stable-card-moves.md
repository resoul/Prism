# ADR 0047: Kanban Stable Card Moves

`KanbanModel` owns stable card/column IDs and an origin snapshot for cancellable cross-column moves. Controlled consumers commit the resulting card order; concurrent updates filter invalid columns and retain only still-present origin cards for cancellation. `visibleCards(in:offset:limit:)` bounds host rendering for large columns.

Drag, keyboard, focus, persistence, and native board rendering remain host/application responsibilities.
