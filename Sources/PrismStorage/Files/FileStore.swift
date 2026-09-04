import Foundation
import struct Flux.Flux
import class Flux.Pipe

/// Typed errors for filesystem storage operations.
public enum FileStoreError: LocalizedError, Sendable {
    case fileNotFound(URL)
    case directoryCreationFailed(URL, any Error)
    case writeFailed(URL, any Error)
    case readFailed(URL, any Error)
    case permissionDenied(URL)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found at: \(url.path)"
        case .directoryCreationFailed(let url, let err):
            return "Failed to create directory at \(url.path): \(err.localizedDescription)"
        case .writeFailed(let url, let err):
            return "Failed to write file at \(url.path): \(err.localizedDescription)"
        case .readFailed(let url, let err):
            return "Failed to read file at \(url.path): \(err.localizedDescription)"
        case .permissionDenied(let url):
            return "Permission denied accessing \(url.path)"
        }
    }
}

/// Actor managing thread-safe, atomic filesystem operations with directory management and corruption recovery.
public actor FileStore {
    public static let shared = FileStore()

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Reads data from the specified path.
    public func read(at path: FilePath) throws -> Data {
        let url = path.url
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileStoreError.fileNotFound(url)
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FileStoreError.readFailed(url, error)
        }
    }

    /// Writes data to disk atomically, creating intermediate directories if needed.
    public func write(_ data: Data, to path: FilePath) throws {
        let url = path.url
        let dir = path.directoryURL

        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw FileStoreError.directoryCreationFailed(dir, error)
            }
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileStoreError.writeFailed(url, error)
        }
    }

    /// Writes a UTF-8 string to disk atomically.
    public func writeString(_ string: String, to path: FilePath) throws {
        guard let data = string.data(using: .utf8) else {
            throw FileStoreError.writeFailed(path.url, NSError(domain: "PrismStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "String encoding failed"]))
        }
        try write(data, to: path)
    }

    /// Reads UTF-8 string content from the specified path.
    public func readString(at path: FilePath) throws -> String {
        let data = try read(at: path)
        guard let string = String(data: data, encoding: .utf8) else {
            throw FileStoreError.readFailed(path.url, NSError(domain: "PrismStorage", code: -2, userInfo: [NSLocalizedDescriptionKey: "String decoding failed"]))
        }
        return string
    }

    /// Deletes a file at the specified path if it exists.
    public func delete(at path: FilePath) throws {
        let url = path.url
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw FileStoreError.writeFailed(url, error)
        }
    }

    /// Checks if a file exists at the given path.
    public func exists(at path: FilePath) -> Bool {
        fileManager.fileExists(atPath: path.url.path)
    }

    /// Deletes all files strictly within the specified container directory.
    public func deleteAll(in directory: FilePath) throws {
        let url = directory.url
        guard fileManager.fileExists(atPath: url.path) else { return }

        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }
}

/// Events emitted during file observation.
public enum FileChangeEvent: Sendable, Equatable {
    case modified
    case deleted
    case renamed
}

/// Real-time file system observer publishing modification events via a Flux stream.
public final class FileWatcher: @unchecked Sendable {
    private let path: FilePath
    private var source: (any DispatchSourceFileSystemObject)?
    private let subject = Pipe<FileChangeEvent>()
    private let lock = NSLock()
    private var fileDescriptor: CInt = -1

    public var flux: Flux<FileChangeEvent> {
        subject.flux
    }

    public init(path: FilePath) {
        self.path = path
        startObserving()
    }

    deinit {
        stopObserving()
    }

    private func startObserving() {
        lock.lock()
        defer { lock.unlock() }

        let fd = open(path.url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global(qos: .utility)
        )

        src.setEventHandler { [weak self, weak src] in
            guard let self, let data = src?.data else { return }
            if data.contains(.delete) {
                self.subject.send(.deleted)
            } else if data.contains(.rename) {
                self.subject.send(.renamed)
            } else if data.contains(.write) {
                self.subject.send(.modified)
            }
        }

        src.setCancelHandler {
            close(fd)
        }

        src.resume()
        self.source = src
    }

    public func stopObserving() {
        lock.lock()
        defer { lock.unlock() }

        if let src = source {
            src.cancel()
            source = nil
        }
    }
}
