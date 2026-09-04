import Foundation

/// Fast, thread-safe in-memory LRU cache supporting byte budgets, entry limits, and item-level TTL.
public final class MemoryLRUCache<Key: Hashable & Sendable, Value: Sendable>: CacheProtocol, @unchecked Sendable {

    private final class Node {
        let key: Key
        var value: Value
        var cost: Int
        var expiresAt: Date?
        var prev: Node?
        var next: Node?

        init(key: Key, value: Value, cost: Int, expiresAt: Date?) {
            self.key = key
            self.value = value
            self.cost = cost
            self.expiresAt = expiresAt
        }
    }

    private let lock = NSLock()
    private var map: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?

    public var costLimit: Int {
        didSet { lock.withLock { enforceLimits() } }
    }

    public var countLimit: Int {
        didSet { lock.withLock { enforceLimits() } }
    }

    public private(set) var totalCost: Int = 0
    private var hits: Int = 0
    private var misses: Int = 0

    public init(costLimit: Int = 32 * 1024 * 1024, countLimit: Int = 500) {
        self.costLimit = costLimit
        self.countLimit = countLimit
    }

    public func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let node = map[key] else {
            misses += 1
            return nil
        }

        if let exp = node.expiresAt, exp < Date() {
            removeNode(node)
            map.removeValue(forKey: key)
            totalCost -= node.cost
            misses += 1
            return nil
        }

        moveToHead(node)
        hits += 1
        return node.value
    }

    public func set(_ value: Value, for key: Key, cost: Int? = nil, ttl: TimeInterval? = nil) {
        let assignedCost = cost ?? 1
        let expiresAt = ttl.map { Date().addingTimeInterval($0) }

        lock.lock()
        defer { lock.unlock() }

        if let existing = map[key] {
            totalCost -= existing.cost
            existing.value = value
            existing.cost = assignedCost
            existing.expiresAt = expiresAt
            totalCost += assignedCost
            moveToHead(existing)
        } else {
            let node = Node(key: key, value: value, cost: assignedCost, expiresAt: expiresAt)
            map[key] = node
            insertHead(node)
            totalCost += assignedCost
        }

        enforceLimits()
    }

    public func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }

        guard let node = map.removeValue(forKey: key) else { return }
        removeNode(node)
        totalCost -= node.cost
    }

    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }

        map.removeAll()
        head = nil
        tail = nil
        totalCost = 0
    }

    public func stats() -> CacheStats {
        lock.lock()
        defer { lock.unlock() }

        return CacheStats(
            hitCount: hits,
            missCount: misses,
            entryCount: map.count,
            totalCostBytes: totalCost
        )
    }

    // MARK: - Internal LRU LinkedList

    private func moveToHead(_ node: Node) {
        guard node !== head else { return }
        removeNode(node)
        insertHead(node)
    }

    private func insertHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: Node) {
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        node.prev = nil
        node.next = nil
    }

    private func enforceLimits() {
        while (totalCost > costLimit || map.count > countLimit), let last = tail {
            map.removeValue(forKey: last.key)
            totalCost -= last.cost
            removeNode(last)
        }
    }
}
