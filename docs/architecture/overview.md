# Architecture Overview

Prism components produce immutable `RenderElement` values. The reconciler compares those values to a mounted tree, runs two-pass layout, and mutates CALayers only on the MainActor. Platform host views and native text-input adapters remain internal boundaries.

```text
PrismUI component → RenderElement → Reconciler → LayoutTree → CALayer / optional Metal
                                     │
                              Focus + AX + OverlayHost
```

`PrismUI` depends only on Core/SVG/Logging, never Data or Storage. Data and storage communicate with views through explicit inputs or Flux state. Extension points must preserve semantic roles, stable identity, and MainActor layer ownership; see the relevant ADR before changing module or lifecycle boundaries.
