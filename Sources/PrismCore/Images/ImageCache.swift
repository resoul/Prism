import Foundation
import CoreGraphics

/// Cache key uniquely identifying an image source along with target resolution requirements.
public struct ImageCacheKey: Hashable, Sendable {
    public let source: ImageSource
    public let targetWidth: Int
    public let targetHeight: Int
    public let scale: Int

    public init(source: ImageSource, targetSize: CGSize, scaleFactor: Double) {
        self.source = source
        self.targetWidth = Int(targetSize.width.rounded())
        self.targetHeight = Int(targetSize.height.rounded())
        self.scale = Int((scaleFactor * 10).rounded())
    }
}

/// Thread-safe in-memory LRU cache for downsampled `CGImage` instances with byte-budget accounting.
public final class ImageMemoryCache: @unchecked Sendable {
    public static let shared = ImageMemoryCache()

    private let lock = NSLock()
    private var entries: [ImageCacheKey: Entry] = [:]
    private var lruHead: Node?
    private var lruTail: Node?

    /// Maximum aggregate bytes allowed in memory (default: 64 MB).
    public var costLimit: Int {
        didSet { enforceCostLimit() }
    }

    /// Current memory usage in bytes.
    public private(set) var totalCost: Int = 0

    public init(costLimit: Int = 64 * 1024 * 1024) {
        self.costLimit = costLimit
    }

    /// Retrieves an image from the cache if present, updating its LRU position.
    public func image(for key: ImageCacheKey) -> CGImage? {
        lock.withLock {
            guard let entry = entries[key] else { return nil }
            moveToHead(entry.node)
            return entry.image
        }
    }

    /// Inserts an image into the cache, evicting older items if the cost limit is exceeded.
    public func store(_ image: CGImage, for key: ImageCacheKey) {
        let cost = image.bytesPerRow * image.height
        lock.withLock {
            if let existing = entries[key] {
                totalCost -= existing.cost
                removeNode(existing.node)
            }

            let node = Node(key: key)
            let entry = Entry(image: image, cost: cost, node: node)
            entries[key] = entry
            totalCost += cost
            addToHead(node)

            enforceCostLimitLocked()
        }
    }

    /// Purges all items from the cache.
    public func clear() {
        lock.withLock {
            entries.removeAll()
            lruHead = nil
            lruTail = nil
            totalCost = 0
        }
    }

    // MARK: - Private LRU Maintenance

    private final class Node {
        let key: ImageCacheKey
        var prev: Node?
        var next: Node?
        init(key: ImageCacheKey) { self.key = key }
    }

    private struct Entry {
        let image: CGImage
        let cost: Int
        let node: Node
    }

    private func enforceCostLimit() {
        lock.withLock { enforceCostLimitLocked() }
    }

    private func enforceCostLimitLocked() {
        while totalCost > costLimit, let tail = lruTail {
            if let entry = entries.removeValue(forKey: tail.key) {
                totalCost -= entry.cost
            }
            removeNode(tail)
        }
    }

    private func addToHead(_ node: Node) {
        node.next = lruHead
        node.prev = nil
        lruHead?.prev = node
        lruHead = node
        if lruTail == nil {
            lruTail = node
        }
    }

    private func removeNode(_ node: Node) {
        if node === lruHead { lruHead = node.next }
        if node === lruTail { lruTail = node.prev }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        node.prev = nil
        node.next = nil
    }

    private func moveToHead(_ node: Node) {
        guard node !== lruHead else { return }
        removeNode(node)
        addToHead(node)
    }
}
