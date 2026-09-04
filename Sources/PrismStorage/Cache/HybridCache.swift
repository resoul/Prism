import Foundation

/// Two-tier composite cache combining high-speed memory LRU with persistent disk caching.
public final class HybridCache<Key: Hashable & Sendable, Value: Codable & Sendable>: CacheProtocol, Sendable {

    public let memoryCache: MemoryLRUCache<Key, Value>
    public let diskCache: DiskCache
    private let keyToString: @Sendable (Key) -> String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        namespace: String = "hybrid",
        memoryCostLimit: Int = 32 * 1024 * 1024,
        memoryCountLimit: Int = 500,
        diskSizeLimit: Int = 100 * 1024 * 1024,
        diskDirectory: FilePath? = nil,
        keyToString: @escaping @Sendable (Key) -> String = { String(describing: $0) }
    ) {
        self.memoryCache = MemoryLRUCache(costLimit: memoryCostLimit, countLimit: memoryCountLimit)
        if let diskDirectory {
            self.diskCache = DiskCache(directory: diskDirectory, maxByteSize: diskSizeLimit)
        } else {
            self.diskCache = DiskCache(namespace: namespace, maxByteSize: diskSizeLimit)
        }
        self.keyToString = keyToString
    }

    public func get(_ key: Key) async -> Value? {
        // 1. Check memory cache hit
        if let memValue = memoryCache.get(key) {
            return memValue
        }

        // 2. Check disk cache
        let stringKey = keyToString(key)
        guard let data = await diskCache.get(stringKey) else {
            return nil
        }

        // 3. Decode and backfill memory cache
        guard let value = try? decoder.decode(Value.self, from: data) else {
            await diskCache.remove(stringKey)
            return nil
        }

        memoryCache.set(value, for: key, cost: data.count)
        return value
    }

    public func set(_ value: Value, for key: Key, cost: Int? = nil, ttl: TimeInterval? = nil) async {
        memoryCache.set(value, for: key, cost: cost, ttl: ttl)

        let stringKey = keyToString(key)
        if let data = try? encoder.encode(value) {
            await diskCache.set(data, for: stringKey, cost: cost ?? data.count, ttl: ttl)
        }
    }

    public func remove(_ key: Key) async {
        memoryCache.remove(key)
        await diskCache.remove(keyToString(key))
    }

    public func removeAll() async {
        memoryCache.removeAll()
        await diskCache.removeAll()
    }

    public func stats() async -> CacheStats {
        let memStats = memoryCache.stats()
        let diskStats = await diskCache.stats()
        return CacheStats(
            hitCount: memStats.hitCount + diskStats.hitCount,
            missCount: memStats.missCount + diskStats.missCount,
            entryCount: diskStats.entryCount,
            totalCostBytes: memStats.totalCostBytes + diskStats.totalCostBytes
        )
    }
}
