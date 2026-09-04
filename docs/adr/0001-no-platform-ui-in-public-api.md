# ADR 0001: Encapsulation of Platform UI Frameworks Behind Pure Prism Abstractions

## Status
Accepted

## Context
Prism targets Apple platforms (iOS 16+, macOS 14+, tvOS 17+). In standard Apple multi-platform development, UI code frequently leaks platform-conditional imports (`#if canImport(UIKit)` / `#if canImport(AppKit)`) into user views, creating coupling to platform lifecycle, different event paradigms, and layout inconsistencies.

Furthermore, relying on SwiftUI in the public API restricts low-level control over the rendering pipeline, layer tree diffing, and fine-grained scheduling.

## Decision
1. **Zero Platform UI in Public Surface:** No public API in `Prism`, `PrismUI`, `PrismCore`, `PrismData`, `PrismStorage`, or `PrismLogging` will expose types from `UIKit` (`UIView`, `UIViewController`), `AppKit` (`NSView`, `NSViewController`), or `SwiftUI` (`View`).
2. **Internal Platform Adapters:** Platform-specific bridging (`UIView` for iOS/tvOS, `NSView` for macOS) is encapsulated strictly within internal classes under `PrismCore/Platform/` and renderer internals.
3. **Unified Abstractions:** Input events (`Event`), focus navigation (`FocusEngine`), layout (`LayoutNode`), and render descriptions (`RenderElement`) are unified across all supported platforms.

## Alternatives Considered
- **SwiftUI wrapper layer:** Rejected due to lack of control over rendering passes, text editing engine, and direct CALayer/Metal pipelines.
- **Leaking `UIView`/`NSView` in host modifiers:** Rejected because it forces application developers to maintain platform branches and breaks universal component composition.

## Consequences
- **Positive:** UI components run identically on iOS, macOS, and tvOS with zero conditional platform directives in application code.
- **Positive:** Public API stability is protected from platform framework churn.
- **Trade-off:** Custom platform controls (e.g. system text fields or map views) require explicit native bridge adapters inside `Platform/` rather than ad-hoc embedding.
