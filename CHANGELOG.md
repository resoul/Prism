# Changelog

All notable changes to Prism will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Swift Package structure supporting iOS 16+, macOS 14+, and tvOS 17+.
- Modular target structure: `PrismCore`, `PrismUI`, `PrismStorage`, `PrismData`, `PrismLogging`, and umbrella `Prism`.
- Remote package dependency to `Flux` (v1.1.0).
- Architectural contracts: `MODULE_CONTRACT.md`, `API_DECISIONS.md`.
- Architecture Decision Record `ADR 0001: Encapsulation of Platform UI Frameworks Behind Pure Prism Abstractions`.
- Element identity foundation (`ElementID`) supporting type, explicit key, and sibling position.
- Selective import guarantees and package verification test suites.
- `PrismLogging`: structured Console, OSLog and opt-in rotating NDJSON file sinks with category filters, privacy redaction, trace context and bounded asynchronous delivery.
- Design Token System (`Color`, `Spacing`, `Radius`, `Shadow`, `Motion`, `ThemeColors`, `Colors`).
- `PrismConfig` and `BaseTokens` declarative result-builder DSL with pre-render validation (inheritance cycles, duplicate IDs, missing parents, negative metrics, empty families, and invalid hexes).
- Theme resolution and multi-level inheritance supporting `ThemeID` (`.light`, `.dark`, `.midnight`, `.brand(...)`) with complete token resolution.
- Three-tier theme priority resolution separating `ColorScheme` and `ThemeSelection` with subtree overrides.
- Typography engine: `FontRole`, `FontWeight`, `TypeScale`, `TextStyle`, `FontResolver` with thread-safe `CTFont` caching and system fallbacks, and `FontLoader` for bundle and URL registration.
- Architecture Decision Record `ADR 0003: Immutable Design Tokens and Pre-Render Theme Resolution`.
- Fail-fast theme construction and environment resolution: invalid configurations and unknown selected themes now throw typed `ConfigValidationError`s instead of silently substituting a fallback theme.
- `FontResolver` now exposes an optional `FontResolutionDiagnostic` callback when it uses a system-font fallback.
- Localization and adaptive text engine (`Locale`, `LayoutDirection`, `ContentSizeCategory`, `LocalizationEnvironment`).
- `LocalizedStringKey` with parameter interpolation and `LocalizationBundle` supporting in-memory tables, plural cardinality rules, development missing-key markers, and pseudo-localization.
- Typography scaling with Dynamic Type multiplier and `DynamicTypeConfig` min/max clamping.
- Direction-aware layout semantics: `DirectionalEdgeInsets` (`leading`/`trailing`) and `HorizontalAlignment` with automatic physical coordinate resolution.
- Thread-safe zero-allocation formatter cache: `LocaleFormatterCache` for date, number, and currency formatters.
- Architecture Decision Record `ADR 0003: Unified Localization, Dynamic Type and Directional Layout`.
- Immutable Virtual Render Tree (VRT): pure value types `RenderElement`, `ElementKind`, `ElementProps`, and `ElementID` (`typeName`, `key`, `siblingIndex`) completely decoupled from `CALayer` and host platform views.
- Declarative Component API: `Component` protocol, `ComponentContext`, and `@resultBuilder ComponentBuilder` supporting empty blocks, optionals, conditionals (`if/else`), and loops.
- Structural primitives: `Group` (inlined children with zero intermediate container nodes) and `Empty` (zero layout/visual footprint).
- Keyed `ForEach` enforcing stable entity identifiers for dynamic data, with identity preservation across reordering.
- P0 declarative component facade: `Text`, `Stack`, `HStack`, `VStack`, `Spacer`, `Rectangle`, `Circle`, and semantic placeholder `Icon`.
- Copy-on-write modifier pipeline (`width`, `height`, `frame`, `padding`, `margin`, `background`, `opacity`, `zIndex`, `key`, `testID`) with deterministic accumulation and overriding precedence rules.
- Visual tree debug serialization (`dumpTree()`) for developer diagnostics and test snapshot assertions.
- Architecture Decision Record `ADR 0004: Virtual Render Tree (VRT) & Declarative Component API` and getting started guide.
- Two-pass layout engine foundation: `LayoutNode`, `LayoutStyle`, `SizeValue` (`fixed`, `fraction`, `intrinsic`, `fill`, `range`), `SizeConstraint` (`unspecified`, `atMost`, `exactly`), `MeasuredSize`, `LayoutFrame`, and `EdgeValues`.
- Dimension constraints resolver with min/max clamping, conflicting constraint arbitration (`min > max` where min takes precedence), and prohibition of NaN, negative sizes, and infinite dimensions.
- CoreText leaf measurement engine (`TextMeasurePolicy`) with multi-line wrapping, line limits, custom line heights, and Unicode/emoji support.
- Shape (`Rectangle`/`Circle`) and `Spacer` leaf measurement policies.
- Scale-aware `PixelRoundingPolicy` for subpixel antialiasing and hairline gap prevention.
- Explicit invalidation lifecycle (`.clean`, `.layoutInvalidated`, `.measureInvalidated`) and developer diagnostic data (`LayoutDebugData`).
- Architecture Decision Record `ADR 0005: Two-Pass Layout Engine Architecture & Constraint Resolution` and layout constraints guide.
