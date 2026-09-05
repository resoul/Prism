# Experimental Drag and Drop (P3)

Use `DragSession` to coordinate pointer or keyboard movement with stable item
IDs. Feed target frames to `update(location:targets:viewport:)`; accepted target
IDs are returned by `drop()`. A missing target, unmount, or explicit cancel ends
the session without an orphan capture. Hosts remain responsible for native
gesture translation and must record iOS/macOS/tvOS availability separately.
