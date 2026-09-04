import Foundation

public protocol LogSink: Sendable {
    func emit(_ record: LogRecord) async
}

public struct LogFilter: Sendable {
    public var minimumLevel: LogLevel
    public var categories: Set<LogCategory>?

    public init(minimumLevel: LogLevel = .trace, categories: Set<LogCategory>? = nil) {
        self.minimumLevel = minimumLevel
        self.categories = categories
    }

    public func accepts(_ record: LogRecord) -> Bool {
        record.level >= minimumLevel && (categories?.contains(record.category) ?? true)
    }
}

public struct LoggingConfiguration: Sendable {
    public var maximumPendingRecords: Int

    public init(maximumPendingRecords: Int = 1_024) {
        self.maximumPendingRecords = max(1, maximumPendingRecords)
    }
}

@resultBuilder
public enum LoggingBuilder {
    public static func buildBlock(_ components: any LogSink...) -> [any LogSink] { components }
    public static func buildOptional(_ component: [any LogSink]?) -> [any LogSink] { component ?? [] }
    public static func buildEither(first component: [any LogSink]) -> [any LogSink] { component }
    public static func buildEither(second component: [any LogSink]) -> [any LogSink] { component }
    public static func buildArray(_ components: [[any LogSink]]) -> [any LogSink] { components.flatMap { $0 } }
}

/// Owns bounded asynchronous delivery. Calling a logger never awaits a sink or blocks MainActor.
public final class LoggingSystem: @unchecked Sendable {
    private let pipeline: LogPipeline

    public init(
        configuration: LoggingConfiguration = .init(),
        @LoggingBuilder _ sinks: () -> [any LogSink]
    ) {
        pipeline = LogPipeline(configuration: configuration, sinks: sinks())
    }

    public func logger(category: LogCategory) -> Logger { Logger(category: category, system: self) }

    fileprivate func submit(_ record: LogRecord) {
        Task { await pipeline.enqueue(record) }
    }

    public func metrics() async -> LoggingMetrics { await pipeline.metrics() }
}

public struct Logger: Sendable {
    public let category: LogCategory
    private let system: LoggingSystem

    fileprivate init(category: LogCategory, system: LoggingSystem) {
        self.category = category
        self.system = system
    }

    public func log(
        _ level: LogLevel,
        _ message: String,
        metadata: [String: LogMetadataValue] = [:],
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        system.submit(.init(level: level, category: category, message: message, metadata: metadata, source: .init(file: file, function: function, line: line)))
    }

    public func trace(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.trace, message, metadata: metadata, file: file, function: function, line: line) }
    public func debug(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.debug, message, metadata: metadata, file: file, function: function, line: line) }
    public func info(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.info, message, metadata: metadata, file: file, function: function, line: line) }
    public func warning(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.warning, message, metadata: metadata, file: file, function: function, line: line) }
    public func error(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.error, message, metadata: metadata, file: file, function: function, line: line) }
    public func fault(_ message: String, metadata: [String: LogMetadataValue] = [:], file: String = #fileID, function: String = #function, line: UInt = #line) { log(.fault, message, metadata: metadata, file: file, function: function, line: line) }

    public func log(_ event: some PrismLogEvent, level: LogLevel = .info) {
        log(level, event.message, metadata: ["eventCategory": .public(event.category)])
    }
}

public struct LoggingMetrics: Sendable, Equatable {
    public let pendingRecords: Int
    public let droppedRecords: Int

    init(pendingRecords: Int, droppedRecords: Int) {
        self.pendingRecords = pendingRecords
        self.droppedRecords = droppedRecords
    }
}

private actor LogPipeline {
    private let configuration: LoggingConfiguration
    private let sinks: [any LogSink]
    private var pending: [LogRecord] = []
    private var isDraining = false
    private var droppedRecords = 0

    init(configuration: LoggingConfiguration, sinks: [any LogSink]) {
        self.configuration = configuration
        self.sinks = sinks
    }

    func enqueue(_ record: LogRecord) {
        guard pending.count < configuration.maximumPendingRecords else {
            droppedRecords += 1
            if record.level >= .error { emergencyWrite(record) }
            return
        }
        pending.append(record)
        guard !isDraining else { return }
        isDraining = true
        Task { await drain() }
    }

    func metrics() -> LoggingMetrics { .init(pendingRecords: pending.count, droppedRecords: droppedRecords) }

    private func drain() async {
        while !pending.isEmpty {
            let record = pending.removeFirst()
            for sink in sinks {
                await sink.emit(record)
            }
        }
        isDraining = false
    }

    /// Last-resort diagnostic for an error dropped by a saturated asynchronous queue.
    /// Metadata is deliberately excluded; messages are required to be safe public summaries.
    private func emergencyWrite(_ record: LogRecord) {
        let line = "[PrismLogging] dropped \(record.level) [\(record.category.rawValue)] \(record.message)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}
