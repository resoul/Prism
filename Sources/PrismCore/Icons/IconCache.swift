import Foundation

/// Thread-safe, bounded memory cache for parsed `SVGDocument` instances.
///
/// Automatically tracks and invalidates cache entries when the source file on disk is modified.
public final class IconCache: @unchecked Sendable {
    public static let shared = IconCache()

    private final class CacheEntry {
        let document: SVGDocument
        let modificationDate: Date?

        init(document: SVGDocument, modificationDate: Date?) {
            self.document = document
            self.modificationDate = modificationDate
        }
    }

    private let lock = NSLock()
    private let cache = NSCache<NSString, CacheEntry>()
    public var countLimit: Int {
        get {
            lock.lock()
            defer { lock.unlock() }
            return cache.countLimit
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            cache.countLimit = newValue
        }
    }

    public init(countLimit: Int = 500) {
        self.cache.countLimit = countLimit
    }

    /// Retrieves a cached `SVGDocument` for the given file URL, re-parsing if the file was modified on disk.
    public func document(for url: URL) -> SVGDocument? {
        let filePath = url.standardizedFileURL.path
        let key = filePath as NSString
        let currentDate = (try? FileManager.default.attributesOfItem(atPath: filePath))?[.modificationDate] as? Date

        lock.lock()
        if let entry = cache.object(forKey: key) {
            if let cachedDate = entry.modificationDate, let currentDate = currentDate, cachedDate < currentDate {
                // File modified on disk; invalidate cache entry
                cache.removeObject(forKey: key)
                lock.unlock()
            } else {
                lock.unlock()
                return entry.document
            }
        } else {
            lock.unlock()
        }

        // Parse from disk outside lock to prevent blocking other threads
        guard let data = try? Data(contentsOf: url),
              let doc = try? SVGParser.parse(data: data) else { return nil }

        store(document: doc, for: key as String, modificationDate: currentDate)
        return doc
    }

    /// Retrieves a cached `SVGDocument` by a string identifier.
    public func document(for key: String) -> SVGDocument? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString)?.document
    }

    /// Stores a parsed `SVGDocument` in the cache.
    public func store(document: SVGDocument, for key: String, modificationDate: Date? = nil) {
        let entry = CacheEntry(document: document, modificationDate: modificationDate)
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(entry, forKey: key as NSString)
    }

    /// Evicts all cached documents.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
}
