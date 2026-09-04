# ADR 0008: Platform Host Views, Host Engine, and Cross-Platform Smoke Verification

## Status
Accepted

## Context
Prism components are pure declarative values (`Component`, `RenderElement`) rendered onto `CALayer`s via a two-pass layout engine. To embed Prism trees within existing iOS, tvOS, and macOS applications, thin platform host views are required to provide window attachment, display scale factors, safe area insets, and system trait notifications (such as light/dark appearance changes) without contaminating public Component APIs or leaking UIKit/AppKit types to consumer models.

## Decision
1. **Platform-Agnostic Host Engine (`PrismHostEngine`):**
   - Encapsulates the entire lifecycle: element tree normalization, `LayoutTreeBuilder` conversion to `LayoutNode`, measure pass (`SizeConstraint`), layout pass (`PixelRoundingPolicy`), and CALayer synchronization via `ContainerRenderer`.
   - Strictly confined to `@MainActor`.
   - Runs in headless/test environments without requiring active platform windows or UI framework runtimes.
2. **Thin Platform Host Adapters:**
   - **iOS / tvOS:** `HostUIView: UIView, PrismHost` backed by its root `layer`. Listens to `layoutSubviews`, `safeAreaInsetsDidChange`, and `traitCollectionDidChange` to forward updates into the engine.
   - **macOS:** `HostNSView: NSView, PrismHost` with `wantsLayer = true`. Listens to `layout`, `setFrameSize`, `viewDidChangeBackingProperties`, and `viewDidChangeEffectiveAppearance`.
   - **Universal Consumer Facade:** `PrismHostView` typealiased in `PrismUI` to provide a single platform view entry point.
3. **Single Layer Attachment Guarantee:**
   - The engine attaches its root `CALayer` once on mount and detaches cleanly on teardown.
   - Repeated host creation and destruction cycles (20+ passes) verify zero retained layers, zero leaks, and immediate resource release.
4. **Developer Diagnostics & Layout Overlay:**
   - `isInspectorOverlayEnabled` attaches a debug overlay layer rendering semi-transparent layout bounding boxes for every active `LayoutNode`.
   - `dumpDiagnostics()` produces a unified string dump containing bounds, scale, safe area, VRT element tree, layout trace, and layer tree counts.
5. **Cross-Platform Smoke Scene (`SmokeScene`):**
   - Provides a unified P0 verification scene exercising theme background, vertical `Stack`, `Text`, vector shapes (`Rectangle`, `Circle`), `Spacer`, and `Icon`.

## Consequences
- **Positive:** Single consumer entry point for embedding Prism in any UIKit or AppKit view hierarchy.
- **Positive:** Zero platform framework leakage into public component models.
- **Positive:** Comprehensive developer diagnostics with visual layout wireframes and text dumps.
- **Trade-off:** Host views require an initial non-zero frame or subsequent layout pass to trigger layer mounting.
