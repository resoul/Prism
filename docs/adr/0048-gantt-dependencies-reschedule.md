# ADR 0048: Gantt Dependencies and Rescheduling

`GanttModel` stores stable task IDs, dependency edges, zoom, and an origin task for cancellable rescheduling. Dependency validation uses DFS and rejects cycles or unknown tasks before rendering. Visible tasks are interval-filtered and windowed; the same task data feeds an ISO-8601 accessibility table.

Timeline drag/keyboard adapters, timezone policy, export transport, and native rendering remain host/application responsibilities.
