# Gantt (P3)

Create tasks, validate dependencies, and reschedule through a cancellable lifecycle:

```swift
var gantt = GanttModel(tasks: tasks, dependencies: edges)
try gantt.validateDependencies()
gantt.beginReschedule(id: taskID)
_ = gantt.reschedule(id: taskID, start: newStart, end: newEnd)
gantt.commitReschedule() // or cancelReschedule()
let rows = gantt.visibleTasks(in: viewport, limit: 80)
```

Zoom is clamped to 0.25…4. Dependency cycles and unknown references fail validation. AX/export consumers can use `accessibilityTable()`.

## Extending

Apply timezone/DST policy through CalendarService before creating dates, map keyboard and drag operations to stable task IDs, and render only bounded visible rows. Keep persistence and export transport outside the model.

## Limitations

No native timeline renderer, recurring tasks, critical-path analysis, persistence backend, or streaming provider is included.
