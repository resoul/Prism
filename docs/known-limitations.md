# Prism — Known Limitations

## Release-gate platform gaps

- Automated package tests run on macOS. iOS/iPadOS/tvOS host interaction, snapshots, full VoiceOver, Switch Control, and Instruments evidence must be completed in the release checklist before a tagged release.
- The catalog verifies example/state/documentation coverage at the render-tree level. Pixel snapshots and native accessibility adapters remain host-level validation.

## Phase 05 / Task 20

- Toast timeout scheduling and native screen-reader delivery are owned by the host; `ToastCenter` provides deterministic queue and announcement state only.
- Native long-press/right-click dispatch, safe-area insets, and visual transition snapshots require iOS/macOS host UI test environments.
- The one-active-modal policy intentionally replaces an existing modal; nested modal stacks are not supported.

## Phase 05 / Task 19

- `Select` currently models a single, non-searchable selection. Searchable menus and general multi-select popovers are planned P3 work.
- `NativeSelect` is a semantic host-adapter request; a platform host may fall back to the standard Prism menu until its native adapter is available.
- Range, step, keyboard, and accessibility semantics are covered at the render-tree level. End-to-end pointer drag and native undo/redo verification require iOS/macOS host UI test environments.

## Phase 01 / Task 01 Status

The following limitations are known and expected during the package foundation phase:

1. **Package Skeleton Phase:**
   - Targets define foundation contracts, module boundaries, markers, and selective import rules.
   - Concrete rendering implementations (`CALayerRenderer`, `MetalRenderer`) and concrete UI widgets (`Text`, `Stack`, `Button`) are introduced in subsequent Phase 1 and Phase 2 tasks.

2. **Platform Deployment Targets:**
   - Supported platforms: iOS 16.0+, macOS 14.0+, tvOS 17.0+.
   - watchOS and Linux are intentionally out of scope for the Prism UI engine.

3. **Selective Imports:**
   - `PrismUI` strictly isolates `PrismData` and `PrismStorage`. Networking (`PrismData`) and Persistence (`PrismStorage`) must be explicitly imported or accessed via the umbrella `Prism` package.

4. **Observability:**
   - `PrismLogging` provides local Console, OSLog and opt-in file diagnostics only. Crash reporting, analytics and remote support-log upload are intentionally not implemented.
   - File logging is best-effort and may drop records under sustained sink pressure to protect UI responsiveness.

5. **Theme & Typography:**
   - Custom font families must be registered via `FontLoader.register` prior to resolving CTFont instances. Unregistered families gracefully fall back to the system UI font with matching weights and traits.
   - Theme configuration is immutable after resolution. Dynamic token mutation requires instantiating an updated `PrismConfig` or providing a local subtree theme override.

6. **Localization & RTL:**
   - Supported string file formats: standard `Localizable.strings`, `Localizable.stringsdict`, and registered in-memory tables. Advanced `.xcstrings` catalog resolution delegates to the host app bundle.
   - RTL mirroring is applied to directional layouts (`leading`/`trailing`). Non-directional absolute offsets (`left`/`right`) remain fixed in physical space.

7. **Optional Metal Renderer & Visual Effects (Phase 04):**
   - Metal rendering is an optional acceleration backend. On environments where `MTLDevice` is not available (e.g. headless CI runners, simulators without Metal support, or when simulated-unsupported is toggled), Prism automatically falls back to standard `CALayer` approximations:
     - SDF Rounded Rectangles fall back to standard `CALayer.cornerRadius` and `borderWidth`.
     - Glassmorphism falls back to a tinted semi-transparent overlay.
     - Mesh Gradients fall back to multi-stop `CAGradientLayer`s.
   - Dynamic complex geometry mesh gradients are clamped to $N \times M$ control grids and evaluated via bilinear interpolation.
