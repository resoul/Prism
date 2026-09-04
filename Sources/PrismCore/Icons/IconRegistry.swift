import Foundation
import CoreGraphics

/// Collision policy when registering an icon or pack that shares an existing identifier.
public enum IconCollisionPolicy: Sendable, Hashable {
    /// Overwrites existing registration silently.
    case overwrite
    /// Retains existing registration and ignores the new entry.
    case ignore
    /// Throws an `IconRegistryError.collision` error.
    case error
}

/// Errors raised during icon pack registration and lookup.
public enum IconRegistryError: Error, LocalizedError, Sendable, Equatable {
    case collision(String)
    case directoryNotFound(URL)
    case iconNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .collision(let name):
            return "Icon pack or asset collision for '\(name)'"
        case .directoryNotFound(let url):
            return "Icon directory not found at '\(url.path)'"
        case .iconNotFound(let name):
            return "Icon asset '\(name)' not found in registered packs or bundles"
        }
    }
}

/// Central registry managing named icon packs, bundle subdirectories, and direct vector registrations.
public final class IconRegistry: @unchecked Sendable {
    public static let shared = IconRegistry()

    private let lock = NSLock()
    private var registeredPacks: [String: (bundle: Bundle, subdirectory: String?)] = [:]
    private var registeredDirectories: [String: URL] = [:]
    private var registeredSources: [String: IconSource] = [:]

    public init() {}

    /// Registers an icon pack located in a bundle.
    public func register(
        pack: String,
        from bundle: Bundle,
        subdirectory: String? = nil,
        collisionPolicy: IconCollisionPolicy = .error
    ) throws {
        lock.lock()
        defer { lock.unlock() }

        if registeredPacks[pack] != nil || registeredDirectories[pack] != nil {
            switch collisionPolicy {
            case .error:
                throw IconRegistryError.collision(pack)
            case .ignore:
                return
            case .overwrite:
                break
            }
        }

        registeredPacks[pack] = (bundle, subdirectory)
    }

    /// Registers an icon pack located at a directory URL on disk.
    public func register(
        pack: String,
        directoryURL: URL,
        collisionPolicy: IconCollisionPolicy = .error
    ) throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw IconRegistryError.directoryNotFound(directoryURL)
        }

        lock.lock()
        defer { lock.unlock() }

        if registeredPacks[pack] != nil || registeredDirectories[pack] != nil {
            switch collisionPolicy {
            case .error:
                throw IconRegistryError.collision(pack)
            case .ignore:
                return
            case .overwrite:
                break
            }
        }

        registeredDirectories[pack] = directoryURL
    }

    /// Registers an in-memory `IconSource` directly by name.
    public func register(
        name: String,
        source: IconSource,
        collisionPolicy: IconCollisionPolicy = .overwrite
    ) throws {
        lock.lock()
        defer { lock.unlock() }

        if registeredSources[name] != nil {
            switch collisionPolicy {
            case .error:
                throw IconRegistryError.collision(name)
            case .ignore:
                return
            case .overwrite:
                break
            }
        }

        registeredSources[name] = source
    }

    /// Convenience alias to register an in-memory `IconSource`.
    public func register(
        source: IconSource,
        for name: String,
        collisionPolicy: IconCollisionPolicy = .overwrite
    ) throws {
        try register(name: name, source: source, collisionPolicy: collisionPolicy)
    }

    /// Convenience lookup for a registered icon source.
    public func source(for name: String) -> IconSource? {
        resolve(named: name)
    }

    /// Resolves an icon name into an `IconSource`.
    public func resolve(named name: String, bundle: String? = nil) -> IconSource? {
        lock.lock()
        if let direct = registeredSources[name] {
            lock.unlock()
            return direct
        }

        // Check pack prefix (e.g. "heroicons/check-circle")
        if let slashIdx = name.firstIndex(of: "/") {
            let packName = String(name[..<slashIdx])
            let iconFile = String(name[name.index(after: slashIdx)...])

            if let dirURL = registeredDirectories[packName] {
                lock.unlock()
                let fileURL = dirURL.appendingPathComponent(iconFile).appendingPathExtension("svg")
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    return .svgURL(fileURL)
                }
                return nil
            }

            if let pack = registeredPacks[packName] {
                lock.unlock()
                let targetBundle = pack.bundle
                let sub = pack.subdirectory
                if let url = targetBundle.url(forResource: iconFile, withExtension: "svg", subdirectory: sub) {
                    return .svgURL(url)
                }
                return nil
            }
        }

        lock.unlock()

        // Fallback: look in explicit bundle or Bundle.main
        let targetBundle: Bundle
        if let bundleName = bundle, let b = Bundle(identifier: bundleName) {
            targetBundle = b
        } else {
            targetBundle = Bundle.main
        }

        if let url = targetBundle.url(forResource: name, withExtension: "svg") {
            return .svgURL(url)
        }

        return nil
    }

    /// Clears all registered packs and in-memory sources.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        registeredPacks.removeAll()
        registeredDirectories.removeAll()
        registeredSources.removeAll()
    }
}
