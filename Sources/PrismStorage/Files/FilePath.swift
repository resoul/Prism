import Foundation

/// Semantic file location descriptors resolving to sandbox directory URLs.
public enum FilePath: Sendable, Hashable {
    case documents(subpath: String)
    case caches(subpath: String)
    case applicationSupport(subpath: String)
    case temporary(subpath: String)
    case custom(URL)

    /// Resolves the absolute URL on the local filesystem.
    public var url: URL {
        let fileManager = FileManager.default
        switch self {
        case .documents(let subpath):
            let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            return base.appendingPathComponent(subpath)

        case .caches(let subpath):
            let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            return base.appendingPathComponent(subpath)

        case .applicationSupport(let subpath):
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            return base.appendingPathComponent(subpath)

        case .temporary(let subpath):
            let base = URL(fileURLWithPath: NSTemporaryDirectory())
            return base.appendingPathComponent(subpath)

        case .custom(let url):
            return url
        }
    }

    /// The parent directory URL containing this file.
    public var directoryURL: URL {
        url.deletingLastPathComponent()
    }

    /// The filename component.
    public var lastPathComponent: String {
        url.lastPathComponent
    }
}
