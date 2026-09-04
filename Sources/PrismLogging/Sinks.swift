import Foundation
#if canImport(os)
import os
#endif

public actor ConsoleSink: LogSink {
    private let filter: LogFilter

    public init(minimumLevel: LogLevel = .info, categories: Set<LogCategory>? = nil) {
        filter = .init(minimumLevel: minimumLevel, categories: categories)
    }

    public func emit(_ record: LogRecord) async {
        guard filter.accepts(record) else { return }
        print(record.sanitizedLine())
    }
}

/// Uses Apple's unified logging where available. The submitted string is already privacy-sanitized.
public actor OSLogSink: LogSink {
    private let subsystem: String
    private let filter: LogFilter
#if canImport(os)
    private var loggers: [String: os.Logger] = [:]
#endif

    public init(subsystem: String = PrismLogging.subsystem, minimumLevel: LogLevel = .info, categories: Set<LogCategory>? = nil) {
        self.subsystem = subsystem
        filter = .init(minimumLevel: minimumLevel, categories: categories)
    }

    public func emit(_ record: LogRecord) async {
        guard filter.accepts(record) else { return }
#if canImport(os)
        let logger = loggers[record.category.rawValue] ?? os.Logger(subsystem: subsystem, category: record.category.rawValue)
        loggers[record.category.rawValue] = logger
        logger.log(level: osLevel(for: record.level), "\(record.sanitizedLine(), privacy: .public)")
#else
        print(record.sanitizedLine())
#endif
    }

#if canImport(os)
    private func osLevel(for level: LogLevel) -> OSLogType {
        switch level {
        case .trace, .debug: .debug
        case .info, .notice: .info
        case .warning: .default
        case .error: .error
        case .fault: .fault
        }
    }
#endif
}

public enum LogRotation: Sendable {
    case keepFiles(count: Int, maximumBytes: Int)

    fileprivate var count: Int {
        switch self { case let .keepFiles(count, _): max(1, count) }
    }

    fileprivate var maximumBytes: Int {
        switch self { case let .keepFiles(_, maximumBytes): max(1, maximumBytes) }
    }
}

/// Opt-in, newline-delimited JSON support log sink. It stores only sanitized records.
public actor FileSink: LogSink {
    private let directory: URL
    private let filter: LogFilter
    private let rotation: LogRotation
    private let fileManager: FileManager
    private let fileName = "prism.ndjson"

    public init(
        directory: URL,
        minimumLevel: LogLevel = .info,
        categories: Set<LogCategory>? = nil,
        rotation: LogRotation = .keepFiles(count: 5, maximumBytes: 5_000_000),
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        filter = .init(minimumLevel: minimumLevel, categories: categories)
        self.rotation = rotation
        self.fileManager = fileManager
    }

    public func emit(_ record: LogRecord) async {
        guard filter.accepts(record) else { return }
        do {
            var data = try record.sanitizedJSONData()
            data.append(0x0A)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try rotateIfNeeded(adding: data.count)
            let url = currentURL
            if !fileManager.fileExists(atPath: url.path) { fileManager.createFile(atPath: url.path, contents: nil) }
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            // Logging failures are isolated: never surface from a caller's UI/data operation.
        }
    }

    public func exportedLines() throws -> [String] {
        let urls = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return try urls.filter { $0.lastPathComponent.hasPrefix("prism") }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            .flatMap { url in String(decoding: try Data(contentsOf: url), as: UTF8.self).split(separator: "\n").map(String.init) }
    }

    private var currentURL: URL { directory.appendingPathComponent(fileName) }

    private func rotateIfNeeded(adding bytes: Int) throws {
        let currentSize = (try? currentURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard currentSize + bytes > rotation.maximumBytes else { return }
        for index in stride(from: rotation.count - 1, through: 1, by: -1) {
            let source = directory.appendingPathComponent("prism.\(index).ndjson")
            let destination = directory.appendingPathComponent("prism.\(index + 1).ndjson")
            if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
            if fileManager.fileExists(atPath: source.path) { try fileManager.moveItem(at: source, to: destination) }
        }
        let first = directory.appendingPathComponent("prism.1.ndjson")
        if fileManager.fileExists(atPath: first.path) { try fileManager.removeItem(at: first) }
        if fileManager.fileExists(atPath: currentURL.path) { try fileManager.moveItem(at: currentURL, to: first) }
    }
}
