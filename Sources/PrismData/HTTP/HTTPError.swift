import Foundation

/// Typed domain errors for HTTP networking.
public enum HTTPError: LocalizedError, Sendable {
    case badURL(String)
    case transportError(any Error)
    case statusError(statusCode: Int, response: HTTPResponse)
    case decodingError(DecodingError, Data)
    case timeout
    case cancelled
    case offline

    public var errorDescription: String? {
        switch self {
        case .badURL(let str):
            return "Malformed URL: \(str)"
        case .transportError(let err):
            return "Network transport failure: \(err.localizedDescription)"
        case .statusError(let code, _):
            return "HTTP request failed with status \(code)"
        case .decodingError(let err, _):
            return "Failed to decode response: \(err.localizedDescription)"
        case .timeout:
            return "Network request timed out"
        case .cancelled:
            return "Network request was cancelled"
        case .offline:
            return "The internet connection appears to be offline"
        }
    }

    /// Whether this error represents a transient failure eligible for automatic retry.
    public var isRetryable: Bool {
        switch self {
        case .timeout, .offline:
            return true
        case .statusError(let code, _):
            return [408, 429, 500, 502, 503, 504].contains(code)
        case .transportError(let err):
            let nsErr = err as NSError
            return nsErr.domain == NSURLErrorDomain && [
                NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorNotConnectedToInternet
            ].contains(nsErr.code)
        default:
            return false
        }
    }
}
