# ADR 0003: Immutable Design Tokens and Pre-Render Theme Resolution

## Status
Accepted

## Context
Cross-platform applications often suffer from theme fragmentation, missing token fallbacks during drawing passes, and inconsistent theme overrides across screens. Additionally, leaking platform-specific types (`UIColor` / `NSColor` / `UIFont` / `NSFont`) into theme tokens breaks cross-platform compatibility.

## Decision
1. **Platform-Neutral Value Tokens:**
   All design tokens (`Color`, `Spacing`, `Radius`, `Shadow`, `Motion`, `Typography`) are immutable value types independent of UIKit and AppKit.
2. **Pre-Render Validation and Completeness:**
   `PrismConfig` resolves token inheritance and validates integrity before the rendering pass. After resolution, every `Theme` is guaranteed complete. Missing parents, duplicate IDs, negative spacing/radius values, and inheritance cycles fail fast with typed `ConfigValidationError`s; construction and environment resolution are explicitly throwing operations.
3. **Three-Tier Priority Hierarchy:**
   Theme resolution prioritizes (1) local subtree overrides, (2) explicit user selection, and (3) system mapping evaluated against system `ColorScheme`.
4. **Thread-Safe Font Resolution with Fallbacks:**
   `FontResolver` maps `(FontRole, TextStyle)` to `CTFont` with full-key caching. If a specified custom family is unavailable, it gracefully degrades to system font traits without throwing and sends a `FontResolutionDiagnostic` through its injected handler.

## Consequences
- **Positive:** UI components receive fully resolved, immutable tokens without runtime lookups or missing-value fallbacks.
- **Positive:** Themes can be instantiated and tested in unit tests without a platform window or host view.
- **Trade-off:** New themes must be declared through the validated config pipeline rather than ad-hoc runtime mutation.
