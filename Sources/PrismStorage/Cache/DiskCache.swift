import Foundation

/// Actor-backed persistent disk cache with TTL eviction, size-budget accounting, and atomic writes.
///
/// Invariant: Scoped strictly to the isolated Prism cache sandbox directory.
public actor DiskCache: CacheProtocol {
    public typealias Key = String
    public typealias Value = Data

    public let directory: FilePath
    public let maxByteSize: Int
    public let defaultTTL: TimeInterval

    private var hits: Int = 0
    private var misses: Int = 0
    private let fileManager = FileManager.default

    public init(
        namespace: String = "default",
        maxByteSize: Int = 100 * 1024 * 1024,
        defaultTTL: TimeInterval = 86400 * 7 // 7 days
    ) {
        let dir = FilePath.caches(subpath: "Prism/DiskCache/\(namespace)")
        self.directory = dir
        self.maxByteSize = maxByteSize
        self.defaultTTL = defaultTTL

        if !FileManager.default.fileExists(atPath: dir.url.path) {
            try? FileManager.default.createDirectory(at: dir.url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    public init(
        directory: FilePath,
        maxByteSize: Int = 100 * 1024 * 1024,
        defaultTTL: TimeInterval = 86400 * 7
    ) {
        self.directory = directory
        self.maxByteSize = maxByteSize
        self.defaultTTL = defaultTTL

        if !FileManager.default.fileExists(atPath: directory.url.path) {
            try? FileManager.default.createDirectory(at: directory.url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // MARK: - CacheProtocol

    public func get(_ key: String) -> Data? {
        let fileURL = entryURL(for: key)
        let metaURL = metaURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            misses += 1
            return nil
        }

        // Check expiration
        if let meta = readMeta(at: metaURL) {
            if let exp = meta.expiresAt, exp < Date() {
                try? fileManager.removeItem(at: fileURL)
                try? fileManager.removeItem(at: metaURL)
                misses += 1
                return nil
            }
        }

        do {
            let data = try Data(contentsOf: fileURL)
            // Update last accessed time
            touch(metaURL: metaURL)
            hits += 1
            return data
        } catch {
            try? fileManager.removeItem(at: fileURL)
            try? fileManager.removeItem(at: metaURL)
            misses += 1
            return nil
        }
    }

    public func set(_ value: Data, for key: String, cost: Int? = nil, ttl: TimeInterval? = nil) {
        ensureDirectory()
        let fileURL = entryURL(for: key)
        let metaURL = metaURL(for: key)
        let effectiveTTL = ttl ?? defaultTTL
        let expiresAt = Date().addingTimeInterval(effectiveTTL)

        let meta = DiskMeta(cost: cost ?? value.count, expiresAt: expiresAt, lastAccessed: Date())

        do {
            // Atomic write using temp file
            try value.write(to: fileURL, options: .atomic)
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: metaURL, options: .atomic)
            enforceSizeLimit()
        } catch {
            // Failed write is non-fatal
        }
    }

    public func remove(_ key: String) {
        let fileURL = entryURL(for: key)
        let metaURL = metaURL(for: key)
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metaURL)
    }

    public func removeAll() {
        let dirURL = directory.url
        guard fileManager.fileExists(atPath: dirURL.path) else { return }
        try? fileManager.removeItem(at: dirURL)
        ensureDirectory()
    }

    public func stats() -> CacheStats {
        let files = (try? fileManager.contentsOfDirectory(at: directory.url, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        var totalBytes = 0
        var count = 0

        for f in files where !f.pathExtension.contains("meta") {
            count += 1
            if let attrs = try? fileManager.attributesOfItem(atPath: f.path),
               let size = attrs[.size] as? Int {
                totalBytes += size
            }
        }

        return CacheStats(
            hitCount: hits,
            missCount: misses,
            entryCount: count,
            totalCostBytes: totalBytes
        )
    }

    // MARK: - Internal Helpers

    private struct DiskMeta: Codable {
        let cost: Int
        let expiresAt: Date?
        var lastAccessed: Date
    }

    private func entryURL(for key: String) -> URL {
        let hashed = keyHashed(key)
        return directory.url.appendingPathComponent("\(hashed).data")
    }

    private func metaURL(for key: String) -> URL {
        let hashed = keyHashed(key)
        return directory.url.appendingPathComponent("\(hashed).meta")
    }

    private func keyHashed(_ key: String) -> String {
        let safe = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        if safe.count > 100 {
            return String(safe.prefix(100)) + "_\(key.hashValue)"
        }
        return safe
    }

    private func ensureDirectory() {
        let url = directory.url
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func readMeta(at url: URL) -> DiskMeta? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DiskMeta.self, from: data)
    }

    private func touch(metaURL: URL) {
        guard var meta = readMeta(at: metaURL) else { return }
        meta.lastAccessed = Date()
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: metaURL, options: .atomic)
        }
    }

    private func enforceSizeLimit() {
        let files = (try? fileManager.contentsOfDirectory(at: directory.url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])) ?? []
        var dataEntries: [(url: URL, metaURL: URL, lastAccessed: Date, size: Int)] = []
        var currentTotal = 0

        for f in files where f.pathExtension == "data" {
            let metaU = f.deletingPathExtension().appendingPathExtension("meta")
            let meta = readMeta(at: metaU)
            let lastAccess = meta?.lastAccessed ?? (try? fileManager.attributesOfItem(atPath: f.path)[.modificationDate] as? Date) ?? Date.distantPast
            let size = (try? fileManager.attributesOfItem(atPath: f.path)[.size] as? Int) ?? 0
            currentTotal += size
            dataEntries.append((f, metaU, lastAccess, size))
        }

        guard currentTotal > maxByteSize else { return }

        dataEntries.sort { $0.lastAccessed < $1.lastAccessed }

        for entry in dataEntries {
            try? fileManager.removeItem(at: entry.url)
            try? fileManager.removeItem(at: entry.metaURL)
            currentTotal -= entry.size
            if currentTotal <= Int(Double(maxByteSize) * 0.8) {
                break
            }
        }
    }
}
