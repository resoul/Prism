# Prism — Known Limitations

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
