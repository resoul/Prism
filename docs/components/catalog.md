# Component Catalog

`PrismCatalog.entries` is the executable catalog index. Each P0/P1/P2 entry declares its tier, category, isolated example identity, state matrix, and the owning documentation page. `PrismCatalogScreen` exposes tier, Dynamic Type size, Reduce Motion, and the animation inspector for host integration.

| Tier | Coverage | State matrix |
|---|---|---|
| P0 | Primitives | default, theme, large text |
| P1 | Display, forms, feedback, navigation, overlays, layout | default, disabled/error/focus, loading, contrast/motion where applicable |
| P2 | Extended display, entry, feedback, navigation, overlays | boundary, keyboard, presented/dismissed, accessibility |

Run `swift test --filter CatalogReleaseTests` to ensure all catalog entries have documentation and state coverage. The catalog source is at `Sources/PrismUI/Demo/PrismCatalog.swift`; specialized runnable fixtures are `P1DemoScreen`, `P2DemoScreen`, `P2DataEntryDemoScreen`, `P2OverlayFeedbackNavigationDemoScreen`, and `AccessibilityAuditScreen`.
