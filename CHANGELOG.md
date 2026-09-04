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
- Architecture Decision Record `ADR 0002: Immutable Design Tokens and Pre-Render Theme Resolution`.
