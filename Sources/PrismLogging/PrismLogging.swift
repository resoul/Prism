import Foundation

/// Structured diagnostics and observability contract for Prism SDK.
public enum PrismLogging {
    public static let subsystem = "dev.prism.ui"
}

/// Marker protocol for structured loggable events in Prism.
public protocol PrismLogEvent: Sendable {
    var category: String { get }
    var message: String { get }
}
