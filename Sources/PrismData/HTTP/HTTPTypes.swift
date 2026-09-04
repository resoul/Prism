import Foundation

/// Standard HTTP request methods.
public enum HTTPMethod: String, Sendable, Equatable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// Header sanitization and redaction utility to prevent sensitive credentials from leaking into logs.
public enum HeaderSanitizer {
    public static let sensitiveHeaders: Set<String> = [
        "authorization",
        "x-api-key",
        "api-key",
        "cookie",
        "set-cookie",
        "proxy-authorization"
    ]

    /// Returns a copy of the headers dictionary with sensitive fields redacted.
    public static func sanitize(_ headers: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (k, v) in headers {
            if sensitiveHeaders.contains(k.lowercased()) {
                if v.lowercased().hasPrefix("bearer ") {
                    sanitized[k] = "Bearer *******"
                } else if v.lowercased().hasPrefix("basic ") {
                    sanitized[k] = "Basic *******"
                } else {
                    sanitized[k] = "[REDACTED]"
                }
            } else {
                sanitized[k] = v
            }
        }
        return sanitized
    }
}
