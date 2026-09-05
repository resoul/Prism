# ADR 0027: Experimental Drag Session and Pointer Capture

`DragSession` is a platform-neutral state machine for pointer and keyboard
dragging. It captures a stable `ElementID`, negotiates accepted targets,
reports scroll arbitration deltas at viewport edges, and cancels on drop without
a target or on item unmount. Consumer state remains owned by the screen/store;
hosts translate native pointer events into coordinates. No file permissions or
platform capture handles are part of this API.
