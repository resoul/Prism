import Foundation

/// Real-time statistics for cache efficiency and resource usage.
public struct CacheStats: Sendable, Equatable {
    public var hitCount: Int
    public var missCount: Int
    public var entryCount: Int
    public var totalCostBytes: Int

    public init(
        hitCount: Int = 0,
        missCount: Int = 0,
        entryCount: Int = 0,
        totalCostBytes: Int = 0
    ) {
        self.hitCount = hitCount
        self.missCount = missCount
        self.entryCount = entryCount
        self.totalCostBytes = totalCostBytes
    }

    /// Aggregate requests received.
    public var totalRequests: Int {
        hitCount + missCount
    }

    /// Hit ratio percentage between 0.0 and 1.0.
    public var hitRatio: Double {
        totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
    }
}

/// Abstract contract for asynchronous cache implementations.
public protocol CacheProtocol: Sendable {
    associatedtype Key: Hashable & Sendable
    associatedtype Value: Sendable

    /// Retrieves an entry from cache if present and unexpired.
    func get(_ key: Key) async -> Value?

    /// Stores an entry in cache with optional byte cost and TTL duration.
    func set(_ value: Value, for key: Key, cost: Int?, ttl: TimeInterval?) async

    /// Removes a specific key from the cache.
    func remove(_ key: Key) async

    /// Purges all entries from the cache.
    func removeAll() async

    /// Obtains current operational telemetry and statistics.
    func stats() async -> CacheStats
}
