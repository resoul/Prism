import Foundation

/// Namespace for Prism's structured diagnostics subsystem.
public enum PrismLogging {
    public static let subsystem = "dev.prism.ui"
}

public enum LogLevel: Int, CaseIterable, Comparable, Sendable, Codable {
    case trace, debug, info, notice, warning, error, fault

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A namespaced category for filtering and routing structured diagnostics.
public struct LogCategory: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.init(rawValue: value) }

    public static let app: Self = "app"
    public static let vrt: Self = "ui.vrt"
    public static let layout: Self = "ui.layout"
    public static let renderer: Self = "ui.renderer"
    public static let events: Self = "ui.events"
    public static let focus: Self = "ui.focus"
    public static let scroll: Self = "ui.scroll"
    public static let performance: Self = "ui.performance"
    public static let http: Self = "data.http"
    public static let webSocket: Self = "data.websocket"
    public static let cache: Self = "storage.cache"
    public static let fileStore: Self = "storage.file"
    public static let navigation: Self = "navigation"
}

public enum LogPrivacy: String, Sendable, Codable {
    case `public`
    case `private`
    case sensitive
}

/// Structured metadata is explicitly classified before it can reach a sink.
public enum LogMetadataValue: Sendable, Codable, Equatable {
    case string(String, privacy: LogPrivacy)
    case integer(Int, privacy: LogPrivacy)
    case double(Double, privacy: LogPrivacy)
    case boolean(Bool, privacy: LogPrivacy)
    case null(privacy: LogPrivacy)

    public static func `public`(_ value: String) -> Self { .string(value, privacy: .public) }
    public static func `public`(_ value: Int) -> Self { .integer(value, privacy: .public) }
    public static func `public`(_ value: Double) -> Self { .double(value, privacy: .public) }
    public static func `public`(_ value: Bool) -> Self { .boolean(value, privacy: .public) }
    public static func `private`(_ value: String) -> Self { .string(value, privacy: .private) }
    public static func `private`(_ value: Int) -> Self { .integer(value, privacy: .private) }
    public static func sensitive(_ value: String) -> Self { .string(value, privacy: .sensitive) }
    public static func url(_ value: URL, privacy: LogPrivacy = .private) -> Self { .string(value.absoluteString, privacy: privacy) }

    public var privacy: LogPrivacy {
        switch self {
        case let .string(_, privacy), let .integer(_, privacy), let .double(_, privacy), let .boolean(_, privacy), let .null(privacy):
            privacy
        }
    }

    fileprivate var publicRepresentation: String {
        switch self {
        case let .string(value, .public): value
        case let .integer(value, .public): String(value)
        case let .double(value, .public): String(value)
        case let .boolean(value, .public): String(value)
        case .null(.public): "null"
        case .string(_, .private), .integer(_, .private), .double(_, .private), .boolean(_, .private), .null(.private): "<private>"
        case .string(_, .sensitive), .integer(_, .sensitive), .double(_, .sensitive), .boolean(_, .sensitive), .null(.sensitive): "<redacted>"
        }
    }
}

public struct LogTraceContext: Hashable, Sendable, Codable {
    public let traceID: UUID
    public let spanID: UUID
    public let parentSpanID: UUID?

    public init(traceID: UUID = UUID(), spanID: UUID = UUID(), parentSpanID: UUID? = nil) {
        self.traceID = traceID
        self.spanID = spanID
        self.parentSpanID = parentSpanID
    }

    public func child() -> Self { .init(traceID: traceID, parentSpanID: spanID) }
}

public enum LogTrace {
    @TaskLocal public static var current: LogTraceContext?

    public static func withTrace<T: Sendable>(
        _ context: LogTraceContext = .init(),
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await $current.withValue(context, operation: operation)
    }
}

public struct LogRecord: Sendable, Codable, Equatable {
    public let timestamp: Date
    public let level: LogLevel
    public let category: LogCategory
    public let message: String
    public let metadata: [String: LogMetadataValue]
    public let trace: LogTraceContext?
    public let source: SourceLocation

    public init(
        timestamp: Date = Date(),
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [String: LogMetadataValue] = [:],
        trace: LogTraceContext? = LogTrace.current,
        source: SourceLocation
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.metadata = metadata
        self.trace = trace
        self.source = source
    }

    /// Safe for console, OSLog and support-file output: private and sensitive data are redacted.
    public func sanitizedLine() -> String {
        let metadataText = metadata.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.publicRepresentation)" }
            .joined(separator: " ")
        let traceText = trace.map { " trace=\($0.traceID.uuidString) span=\($0.spanID.uuidString)" } ?? ""
        let sourceText = " source=\(source.file):\(source.line)"
        return "\(timestamp.ISO8601Format()) [\(level)] [\(category.rawValue)] \(message)\(traceText)\(metadataText.isEmpty ? "" : " \(metadataText)")\(sourceText)"
    }

    func sanitizedJSONData() throws -> Data {
        let payload = SanitizedLogRecord(
            timestamp: timestamp,
            level: String(describing: level),
            category: category.rawValue,
            message: message,
            metadata: metadata.mapValues(\.publicRepresentation),
            traceID: trace?.traceID.uuidString,
            spanID: trace?.spanID.uuidString,
            parentSpanID: trace?.parentSpanID?.uuidString,
            source: "\(source.file):\(source.line)"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }
}

private struct SanitizedLogRecord: Encodable {
    let timestamp: Date
    let level: String
    let category: String
    let message: String
    let metadata: [String: String]
    let traceID: String?
    let spanID: String?
    let parentSpanID: String?
    let source: String
}

public struct SourceLocation: Sendable, Codable, Equatable {
    public let file: String
    public let function: String
    public let line: UInt

    public init(file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.file = file
        self.function = function
        self.line = line
    }
}

/// Compatibility marker for simple event-style producers.
public protocol PrismLogEvent: Sendable {
    var category: String { get }
    var message: String { get }
}
