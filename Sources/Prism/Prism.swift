@_exported import PrismUI
@_exported import PrismData
@_exported import PrismStorage
@_exported import PrismLogging
@_exported import Flux

/// Prism umbrella module.
///
/// Importing `Prism` provides access to the complete Prism SDK:
/// - PrismUI (Declarative Component API, Primitives, VRT, Layout, Themes)
/// - PrismData (HTTP, WebSocket, Repository, Store contracts)
/// - PrismStorage (Preferences, FileStore, SecureStore, Cache)
/// - PrismLogging (Structured Logging and Observability)
/// - Flux (Reactive state primitives: CurrentValue, Pipe, etc.)
public enum PrismSDK {
    public static let version = "0.1.0"
}
