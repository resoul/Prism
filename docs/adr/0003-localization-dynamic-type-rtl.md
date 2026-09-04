# ADR 0003: Unified Localization, Dynamic Type and Directional Layout

## Status
Accepted

## Context
Standard UI development often leaks platform-specific queries (`UIFontMetrics`, `UIApplication.shared.preferredContentSizeCategory`, `NSLocale`) directly into component layout logic, breaking cross-platform reusability and introducing performance penalties when formatters or font descriptors are allocated inside render loops.

## Decision
1. **Environment Inputs over Platform Lookups:**
   `Locale`, `LayoutDirection`, and `ContentSizeCategory` are passed down via `LocalizationEnvironment`. Components never query UIKit or AppKit directly for text size or locale.
2. **Directional Semantics:**
   Insets and alignments use `DirectionalEdgeInsets` (`leading`/`trailing`) and `HorizontalAlignment` (`.leading`/`.trailing`). Physical conversion occurs during the layout phase based on the active `LayoutDirection`.
3. **Clamped Dynamic Type Scaling:**
   Typography scaling supports configurable `DynamicTypeConfig` (`minScale`/`maxScale`) to maintain visual hierarchy while honoring user accessibility preferences.
4. **Zero-Allocation Formatter Cache:**
   `LocaleFormatterCache` provides thread-safe reuse of Foundation `DateFormatter` and `NumberFormatter` instances keyed by configuration parameters.
5. **Visible Missing Key Fallbacks:**
   Translation keys return visible `[MISSING: "key"]` placeholders in development mode and graceful fallbacks in production.

## Consequences
- **Positive:** Components render correctly across LTR and RTL locales without code branches.
- **Positive:** No runtime allocations of date/number formatters in render cycles.
- **Trade-off:** Component developers must use `leading`/`trailing` rather than absolute `left`/`right` in all margin and padding signatures.
