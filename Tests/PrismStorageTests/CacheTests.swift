import XCTest
import Foundation
@testable import PrismStorage

final class CacheTests: XCTestCase {

    // MARK: - MemoryLRUCache Tests

    func testMemoryLRUCacheBasicOperations() {
        let cache = MemoryLRUCache<String, String>(costLimit: 1024, countLimit: 10)

        cache.set("world", for: "hello", cost: 5)
        let val = cache.get("hello")
        XCTAssertEqual(val, "world")

        cache.remove("hello")
        let removed = cache.get("hello")
        XCTAssertNil(removed)
    }

    func testMemoryLRUCacheCountLimitEviction() {
        let cache = MemoryLRUCache<String, Int>(costLimit: 10000, countLimit: 3)

        cache.set(1, for: "k1")
        cache.set(2, for: "k2")
        cache.set(3, for: "k3")

        // Access k1 so it becomes most recently used; k2 is now LRU
        _ = cache.get("k1")

        // Insert k4, should evict k2
        cache.set(4, for: "k4")

        XCTAssertEqual(cache.get("k1"), 1)
        XCTAssertNil(cache.get("k2"))
        XCTAssertEqual(cache.get("k3"), 3)
        XCTAssertEqual(cache.get("k4"), 4)
    }

    func testMemoryLRUCacheCostLimitEviction() {
        let cache = MemoryLRUCache<String, String>(costLimit: 10, countLimit: 100)

        cache.set("aaaaa", for: "k1", cost: 5)
        cache.set("bbbbb", for: "k2", cost: 5)

        // Total cost is 10. Inserting cost 5 must evict k1
        cache.set("ccccc", for: "k3", cost: 5)

        XCTAssertNil(cache.get("k1"))
        XCTAssertEqual(cache.get("k2"), "bbbbb")
        XCTAssertEqual(cache.get("k3"), "ccccc")
    }

    func testMemoryLRUCacheTTLExpiration() async {
        let cache = MemoryLRUCache<String, String>(costLimit: 1000, countLimit: 10)

        cache.set("short_lived", for: "temp", ttl: 0.1)
        XCTAssertEqual(cache.get("temp"), "short_lived")

        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        XCTAssertNil(cache.get("temp"))
    }

    // MARK: - DiskCache Tests

    func testDiskCacheBasicOperations() async throws {
        let dir = FilePath.temporary(subpath: "disk_cache_test_\(UUID().uuidString)")
        let cache = DiskCache(directory: dir, maxByteSize: 1024 * 1024)

        let data = "Disk Cached Content".data(using: .utf8)!
        await cache.set(data, for: "key1")

        let retrieved = await cache.get("key1")
        XCTAssertEqual(retrieved, data)

        await cache.remove("key1")
        let removed = await cache.get("key1")
        XCTAssertNil(removed)

        await cache.removeAll()
    }

    func testDiskCacheTTLExpiration() async throws {
        let dir = FilePath.temporary(subpath: "disk_ttl_test_\(UUID().uuidString)")
        let cache = DiskCache(directory: dir, maxByteSize: 1024 * 1024, defaultTTL: 0.1)

        let data = "Expiring Content".data(using: .utf8)!
        await cache.set(data, for: "key_ttl")

        let initial = await cache.get("key_ttl")
        XCTAssertNotNil(initial)

        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        let expired = await cache.get("key_ttl")
        XCTAssertNil(expired)
        await cache.removeAll()
    }

    // MARK: - HybridCache Tests

    func testHybridCacheTiering() async throws {
        struct Item: Codable, Equatable {
            let id: Int
            let name: String
        }

        let dir = FilePath.temporary(subpath: "hybrid_cache_test_\(UUID().uuidString)")
        let hybrid = HybridCache<String, Item>(
            memoryCostLimit: 1024,
            memoryCountLimit: 10,
            diskSizeLimit: 1024 * 1024,
            diskDirectory: dir
        )

        let item1 = Item(id: 1, name: "Prism Hybrid")
        await hybrid.set(item1, for: "item_1")

        // 1. Memory hit
        let memHit = await hybrid.get("item_1")
        XCTAssertEqual(memHit, item1)

        // 2. Clear memory cache directly to test disk promotion
        hybrid.memoryCache.removeAll()

        // Should fetch from disk cache and promote back to memory cache
        let diskHit = await hybrid.get("item_1")
        XCTAssertEqual(diskHit, item1)

        // Verify it was promoted into memory
        let promotedHit = hybrid.memoryCache.get("item_1")
        XCTAssertEqual(promotedHit, item1)

        // 3. Remove cleans both tiers
        await hybrid.remove("item_1")
        let removedFromHybrid = await hybrid.get("item_1")
        XCTAssertNil(removedFromHybrid)
        let removedFromMem = hybrid.memoryCache.get("item_1")
        XCTAssertNil(removedFromMem)
        let removedFromDisk = await hybrid.diskCache.get("item_1")
        XCTAssertNil(removedFromDisk)

        await hybrid.removeAll()
    }
}
