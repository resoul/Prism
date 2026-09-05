# Visual and Accessibility Baselines

`VisualAccessibilityAuditTests` provides a deterministic render-tree baseline
matrix for light/large/LTR, compact/LTR, and dark/accessibility-large/RTL with
Reduce Motion and increased contrast enabled. It also executes a real
`AccessibilityAction` and proves that invalidated elements cannot be activated.

Run:

```sh
swift test --filter VisualAccessibilityAuditTests
```

These are platform-neutral contract baselines. Pixel screenshots, VoiceOver,
keyboard traversal, IME, long-press/right-click, and native overlay dismissal
remain host-level checks and must be run on iOS/iPadOS/macOS before release.
Unavailable host runtimes are recorded as unverified rather than passed.
