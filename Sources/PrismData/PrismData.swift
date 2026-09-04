import Foundation
import Flux
import PrismStorage
import PrismLogging

/// Data layer for Prism SDK.
///
/// Provides HTTP, WebSocket, Repository, FetchStrategy, and Store contracts.
/// Note: PrismData depends on PrismStorage for Cache contracts, but does NOT depend on PrismUI.
public enum PrismData {
    public static let layerDescription = "HTTP, WebSocket, Repository, and Store contracts"
}

/// Marker protocol for data fetch operations.
public protocol DataRepositoryContract: Sendable {}
