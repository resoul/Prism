# P2 Overlay, Feedback, and Navigation Guide

`ToastCenter` owns a bounded, main-actor queue. Reuse a `deduplicationKey` for repeated events; visible toasts emit a polite accessibility announcement and queued items promote after dismissal.

```swift
let notices = ToastCenter()
notices.enqueue(ToastItem(title: "Saved", variant: .success, deduplicationKey: "save"))
Toast(notices.visible[0])
```

Use `Progress(value:total:)` for determinate work and `Progress()` for an indeterminate operation. Both expose a `progressbar` role and normalized 0...1 value where known.

`Breadcrumb`, `Pagination`, and `NavigationMenu` work with the existing `Navigator` or an explicit `Binding`; they do not own a parallel navigation stack.

```swift
Pagination(page: currentPage, pageCount: 12)
NavigationMenu(items: items, selection: selectedSection, navigator: navigator)
```

`AlertDialog`, `Sheet`, and `Drawer` are modal-tier components. The host permits exactly one active modal: presenting another dismisses the prior modal and restores focus before assigning focus to the new one. `Popover`, `DropdownMenu`, and `ContextMenu` render in the floating tier and use anchor invalidation when applicable. Escape and backdrop dismissal are routed by `OverlayHost`.

`P2OverlayFeedbackNavigationDemoScreen` is the runnable catalog fixture covering network feedback, navigation selection, and each overlay surface. It is intentionally a composition fixture; hosts supply their own bindings and route actions.
