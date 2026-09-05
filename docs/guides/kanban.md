# Kanban (P3)

Move stable-ID cards across controlled columns:

```swift
var board = KanbanModel(columns: ["todo", "done"], cards: cards)
board.beginMove(cardID: cardID)
_ = board.move(cardID: cardID, toColumn: "done", index: 0)
board.commitMove() // or cancelMove()
let visible = board.visibleCards(in: "done", offset: 0, limit: 50)
```

`applyDataUpdate` reconciles cards arriving or disappearing during a move. Commit only after the host drag/keyboard operation succeeds; cancel on unmount or pointer cancellation.

## Extending

Persist card order by stable IDs, map keyboard/AX operations to the same move API, and render bounded windows per column. Keep transfer side effects in the application layer.

## Limitations

No native drag/drop, persistence backend, swimlanes, server synchronization, or card editing UI is included.
