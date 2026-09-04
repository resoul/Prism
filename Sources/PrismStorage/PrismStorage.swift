import Foundation
import Flux
import PrismLogging

/// Persistence and storage layer for Prism SDK.
///
/// Provides Preferences, SecureStore, FileStore, and Cache contracts.
/// Note: PrismStorage does NOT depend on PrismUI or networking APIs.
public enum PrismStorage {
    public static let layerDescription = "Persistence, SecureStore, FileStore, and Cache"
}

/// Marker protocol for persistence operations.
public protocol StorageContract: Sendable {}
