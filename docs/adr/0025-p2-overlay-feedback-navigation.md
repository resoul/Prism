# ADR 0025: P2 Overlay, Feedback, and Navigation

## Status
Accepted

## Decision

- Keep transient feedback in a `ToastCenter` main-actor queue with a bounded visible set, deduplication keys, and polite announcements.
- Expose `Progress` as determinate or indeterminate render-tree semantics.
- Build breadcrumb, pagination, and navigation menu controls on existing `Navigator` or `Binding` state.
- Keep public overlays platform-neutral. `AlertDialog`, `Sheet`, and `Drawer` request the modal tier; `Popover`, `DropdownMenu`, and `ContextMenu` request the floating tier.
- `OverlayHost` has deterministic presentation order and a one-active-modal policy, eliminating ambiguous focus traps, backdrops, and AX ownership.

## Consequences

Public UI APIs remain free of UIKit/AppKit/SwiftUI. Host-level native gesture handling and visual transition rendering remain host responsibilities, while queue, ordering, focus restoration, anchor invalidation, and semantic roles are testable without platform UI frameworks.
