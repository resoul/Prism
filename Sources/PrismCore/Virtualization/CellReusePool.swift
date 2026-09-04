import Foundation

/// Pool for recycling and reusing virtualized nodes and render elements,
/// preventing excessive memory allocations and GPU layer churn during fast scrolling.
public final class CellReusePool: @unchecked Sendable {
    private let lock = NSLock()
    private var poolByReuseID: [String: [RenderElement]] = [:]

    public private(set) var allocatedCount: Int = 0
    public private(set) var recycledCount: Int = 0
    public private(set) var reusedCount: Int = 0

    public init() {}

    /// Enqueues an element for future reuse.
    ///
    /// - Parameters:
    ///   - element: The element to recycle.
    ///   - reuseID: Identifier classifying identical structural templates.
    public func recycle(_ element: RenderElement, reuseID: String) {
        lock.withLock {
            var sanitized = element
            // Reset transient attributes to prevent state bleed
            sanitized.props.custom.removeValue(forKey: "isSelected")
            sanitized.props.custom.removeValue(forKey: "isHighlighted")

            poolByReuseID[reuseID, default: []].append(sanitized)
            recycledCount += 1
        }
    }

    /// Attempts to dequeue a recycled element matching the given reuse identifier.
    ///
    /// - Parameter reuseID: The structural template identifier.
    /// - Returns: A recycled element if available, or `nil` if a new one must be allocated.
    public func dequeue(reuseID: String) -> RenderElement? {
        lock.withLock {
            guard var items = poolByReuseID[reuseID], !items.isEmpty else {
                allocatedCount += 1
                return nil
            }
            let item = items.removeLast()
            poolByReuseID[reuseID] = items
            reusedCount += 1
            return item
        }
    }

    /// Clears all recycled elements from memory (e.g. on memory pressure).
    public func drain() {
        lock.withLock {
            poolByReuseID.removeAll()
        }
    }

    /// Returns the number of currently idle recycled elements in the pool.
    public var idleCount: Int {
        lock.withLock {
            poolByReuseID.values.reduce(0) { $0 + $1.count }
        }
    }
}
