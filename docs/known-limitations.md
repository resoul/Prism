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

4. **Observability:**
   - `PrismLogging` provides local Console, OSLog and opt-in file diagnostics only. Crash reporting, analytics and remote support-log upload are intentionally not implemented.
   - File logging is best-effort and may drop records under sustained sink pressure to protect UI responsiveness.

5. **Theme & Typography:**
   - Custom font families must be registered via `FontLoader.register` prior to resolving CTFont instances. Unregistered families gracefully fall back to the system UI font with matching weights and traits.
   - Theme configuration is immutable after resolution. Dynamic token mutation requires instantiating an updated `PrismConfig` or providing a local subtree theme override.

6. **Localization & RTL:**
   - Supported string file formats: standard `Localizable.strings`, `Localizable.stringsdict`, and registered in-memory tables. Advanced `.xcstrings` catalog resolution delegates to the host app bundle.
   - RTL mirroring is applied to directional layouts (`leading`/`trailing`). Non-directional absolute offsets (`left`/`right`) remain fixed in physical space.
