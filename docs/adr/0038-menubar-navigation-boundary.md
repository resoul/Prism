# ADR 0038: Menubar Navigation Boundary

`MenubarModel` owns menu hierarchy, enabled state, highlighted item, and open/closed state. Arrow, Return, and Escape handling is deterministic; shortcut conflicts resolve to the first enabled command in declaration order. `previousFocusID` is retained for host focus restoration. Native menu bars and platform availability remain adapter responsibilities.
