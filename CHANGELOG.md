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
