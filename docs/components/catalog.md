# Component Catalog

`PrismCatalog.entries` is the executable catalog index. Each P0/P1/P2 entry declares its tier, category, isolated example identity, state matrix, and the owning documentation page. `PrismCatalogHost` is the runnable iOS/macOS composition: it provides stable `testID`s for tier navigation, theme/contrast/motion controls, example selection, and tree/layout/animation inspectors. Pass one `PrismCatalogStore` to preserve selection and controls across rebuilds.

```swift
let catalogStore = PrismCatalogStore()
let catalog = PrismCatalogHost(store: catalogStore)
catalogStore.select(id: "button")
// Re-rendering `catalog` keeps the selected Button example and control state.
```

| Tier | Coverage | State matrix |
|---|---|---|
| P0 | Primitives | default, theme, large text |
| P1 | Display, forms, feedback, navigation, overlays, layout | default, disabled/error/focus, loading, contrast/motion where applicable |
| P2 | Extended display, entry, feedback, navigation, overlays | boundary, keyboard, presented/dismissed, accessibility |

Run `swift test --filter CatalogReleaseTests` to ensure all catalog entries have documentation, state coverage, and persistence scenarios. The catalog source is at `Sources/PrismUI/Demo/PrismCatalog.swift`; specialized runnable fixtures are `P1DemoScreen`, `P2DemoScreen`, `P2DataEntryDemoScreen`, `P2OverlayFeedbackNavigationDemoScreen`, and `AccessibilityAuditScreen`.
