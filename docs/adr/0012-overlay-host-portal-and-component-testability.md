# ADR 0012: OverlayHost, Portal Projection, and Component Testability

## Status
Accepted

## Context
Overlays (modals, dialogs, popovers, tooltips, action sheets, and toasts) are common in modern applications, but often implemented as ad-hoc hacks that manipulate window view hierarchies directly or break the declarative component tree. Specific challenges include:
1. **Clipping escape:** Tooltips and popovers embedded deeply inside scroll areas or clipped cards are clipped by their parent containers unless visually rendered in an unclipped layer.
2. **State and event ownership:** Moving a component's visual layer into an overlay must not sever its logical parentage; state bindings, environment propagation, and event bubbling must follow the logical component hierarchy.
3. **Layer tiers and hit-test precedence:** Named tiers (`content`, `floating`, `modal`, `toast`, `debug`) require strict z-ordering (0, 1000, 2000, 3000, 4000) and reverse-z hit testing. Modals with backdrops must block pointer events to underlying content and floating tiers.
4. **Overlay lifecycle:** Modals require focus transfer (saving previous focus on presentation and restoring it on dismiss), backdrop tap detection, Escape key dismissal, and anchor tracking.
5. **Anchored geometry:** Popovers and tooltips need robust geometric positioning relative to an anchor element (top, bottom, leading, trailing with start/center/end alignment), with automatic invalidation on scroll, resize, and unmount.
6. **Component testability:** Automated UI tests require stable, semantic `.testID(String)` identifiers independent of localized text or platform view hierarchies, with development diagnostics to detect duplicate testIDs.

## Decision
1. **Root OverlayHost (`Sources/PrismCore/Platform/OverlayHost.swift`):**
   - Manages 5 named overlay tiers: `.content` (z: 0), `.floating` (z: 1000), `.modal` (z: 2000), `.toast` (z: 3000), and `.debug` (z: 4000).
   - Overlay containers have `masksToBounds = false` so child popovers and tooltips escape parent clipping boundaries.
   - Overlays are attached lazily to `hostLayer` to keep the base content layer pristine when no overlays are active.
   - Provides modal backdrop layer with semi-transparent background (`CGColor(gray: 0.0, alpha: 0.4)`), automatic focus trapping, and focus restoration upon dismissal.
   - Handles dismiss reasons: `.backdropTap`, `.escapeKey`, `.explicitClose`, `.anchorUnmounted`, and `.timeout`.

2. **Logical vs. Visual Portal Separation (`Sources/PrismCore/VRT/Portal.swift`):**
   - Declarative `Portal(layer:)` component and `.portal(layer:)` modifier.
   - The mounted node remains linked to its logical parent (`node.parent`), preserving environment inheritance, local state access, and event bubbling.
   - The backing `CALayer` is projected directly into `overlayHost.containerLayer(for: targetLayer)`.
   - `ContainerRenderer` skips adding portal root layers to parent containers, preventing layer reparenting back into clipped ancestors.

3. **Anchored Positioning & Invalidation (`Sources/PrismCore/Platform/AnchorPreference.swift`):**
   - Declarative `.anchor(id: String)` modifier assigns anchor identifiers.
   - `AnchorRegistry` tracks active anchor nodes and global frames.
   - `OverlayPositioning.anchored(anchorID:edge:alignment:offset:)` computes clamped viewport-safe coordinates.
   - `engine.invalidateOverlayPositions()` recalculates positions on scroll, resize, and layout changes. If an anchor is unmounted, active overlays anchored to it are automatically dismissed with `.anchorUnmounted`.

4. **Component Testability & Diagnostics (`Sources/PrismCore/VRT/TestIDDiagnostics.swift`):**
   - Public `.testID(String)` on `RenderElement` and `Component`.
   - `TestIDValidator.findConflicts(in:)` detects duplicate testIDs across the tree.
   - `engine.testIDConflicts` exposes development diagnostics for CI assertions.
   - `AccessibilityTree.findElement(byTestID:)` provides fast, localized-string-independent lookup for automated UI testing.

5. **Hit-Testing Integration (`Sources/PrismCore/Events/HitTester.swift`):**
   - `HitTester.hitTest` tests overlay tiers in reverse order (`debug` -> `toast` -> `modal` -> `floating` -> `content`).
   - Modal backdrop with `blocksBackgroundPointer = true` absorbs taps, preventing click-through to underlying floating and content tiers.
   - Backdrop tap triggers `overlayHost.handleBackdropTap()`.

## Consequences
- **Positive:** Modals, dialogs, popovers, tooltips, and toasts now share a single, unified overlay infrastructure rather than inventing custom layer hacks.
- **Positive:** Portals escape scroll area and card clipping while keeping 100% of event bubbling, themes, and Flux state intact.
- **Positive:** Automated tests use stable semantic testIDs that never break across localization changes or CALayer refactoring.
- **Positive:** Focus is safely managed across modal presentations and automatically restored upon dismiss.
- **Trade-off:** Anchored overlays require explicit invalidation calls on scroll or layout shifts to synchronize coordinates.
