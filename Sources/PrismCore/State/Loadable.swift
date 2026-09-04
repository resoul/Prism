import Foundation

/// Represents a value whose loading lifecycle may be in progress, completed, or failed.
///
/// `Loadable` explicitly distinguishes between initial unstarted (`.idle`), active initial fetch (`.loading`),
/// successful completion (`.loaded`), background revalidation (`.refreshing`), and failure (`.failure`),
/// while preserving the previously loaded value where applicable so UI components can display stale content
/// during reloads or error states.
public enum Loadable<Value: Sendable>: Sendable {
    /// Initial state before any load has been initiated.
    case idle

    /// An initial load is in progress.
    /// If an optional previous value exists (e.g. after a reset), it is retained here.
    case loading(previous: Value? = nil)

    /// The value was successfully loaded.
    case loaded(Value)

    /// Background refresh or revalidation is in progress while keeping the current valid value visible.
    case refreshing(previous: Value)

    /// The load or refresh operation failed with a typed error, preserving any previously loaded value.
    case failure(error: LoadableError, previous: Value? = nil)

    // MARK: - Convenient Static Constructors

    /// Convenient constructor for initial loading with no previous value.
    public static var loading: Self {
        .loading(previous: nil)
    }

    /// Convenient constructor for failure with no previous value.
    public static func failure(_ error: LoadableError) -> Self {
        .failure(error: error, previous: nil)
    }

    // MARK: - Accessors

    /// The latest successfully loaded or previous value, if available.
    public var value: Value? {
        switch self {
        case .idle:
            return nil
        case .loading(let prev):
            return prev
        case .loaded(let val):
            return val
        case .refreshing(let prev):
            return prev
        case .failure(_, let prev):
            return prev
        }
    }

    /// The previous value before the current in-flight load, refresh, or failure.
    public var previousValue: Value? {
        switch self {
        case .idle:
            return nil
        case .loading(let prev):
            return prev
        case .loaded:
            return nil
        case .refreshing(let prev):
            return prev
        case .failure(_, let prev):
            return prev
        }
    }

    /// The error associated with a failure state, if any.
    public var error: LoadableError? {
        switch self {
        case .failure(let error, _):
            return error
        default:
            return nil
        }
    }

    /// Indicates whether an initial load or refresh is currently active.
    public var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }

    /// Indicates whether a background revalidation/refresh is active while preserving previous content.
    public var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }

    /// Indicates whether the loadable is in the idle state.
    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Indicates whether the value has completed loading successfully.
    public var isSuccess: Bool {
        if case .loaded = self { return true }
        return false
    }

    /// Indicates whether the current state is failure.
    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    // MARK: - Transformations

    /// Transforms the loaded or previous value using a closure.
    public func map<U>(_ transform: (Value) -> U) -> Loadable<U> {
        switch self {
        case .idle:
            return .idle
        case .loading(let prev):
            return .loading(previous: prev.map(transform))
        case .loaded(let val):
            return .loaded(transform(val))
        case .refreshing(let prev):
            return .refreshing(previous: transform(prev))
        case .failure(let error, let prev):
            return .failure(error: error, previous: prev.map(transform))
        }
    }

    /// Transforms the loaded value into another `Loadable`.
    public func flatMap<U>(_ transform: (Value) -> Loadable<U>) -> Loadable<U> {
        switch self {
        case .idle:
            return .idle
        case .loading(let prev):
            return .loading(previous: prev.flatMap { transform($0).value })
        case .loaded(let val):
            return transform(val)
        case .refreshing(let prev):
            let next = transform(prev)
            if let nextVal = next.value {
                return .refreshing(previous: nextVal)
            }
            return .loading(previous: nil)
        case .failure(let error, let prev):
            return .failure(error: error, previous: prev.flatMap { transform($0).value })
        }
    }
}

// MARK: - Equatable Conformance

extension Loadable: Equatable where Value: Equatable {
    public static func == (lhs: Loadable<Value>, rhs: Loadable<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let lPrev), .loading(let rPrev)):
            return lPrev == rPrev
        case (.loaded(let lVal), .loaded(let rVal)):
            return lVal == rVal
        case (.refreshing(let lPrev), .refreshing(let rPrev)):
            return lPrev == rPrev
        case (.failure(let lErr, let lPrev), .failure(let rErr, let rPrev)):
            return lErr == rErr && lPrev == rPrev
        default:
            return false
        }
    }
}

// MARK: - LoadableError

/// A strongly typed, privacy-preserving error representing loadable operation failures.
public struct LoadableError: Error, Equatable, Sendable, CustomStringConvertible {
    /// High-level failure classification codes.
    public enum Code: String, Sendable, Equatable, Codable {
        case network
        case timeout
        case unauthorized
        case forbidden
        case notFound
        case serverError
        case decoding
        case cancelled
        case unknown
    }

    /// The classification code of this failure.
    public let code: Code

    /// A human-readable, safe error message suitable for UI display.
    public let message: String

    /// Optional debug description of underlying cause (e.g. NSError domain/code), sanitized for logging.
    public let debugDetails: String?

    public init(
        code: Code = .unknown,
        message: String,
        debugDetails: String? = nil
    ) {
        self.code = code
        self.message = message
        self.debugDetails = debugDetails
    }

    /// Initializes a `LoadableError` by categorizing an arbitrary Swift error.
    public init(from error: any Error) {
        if let loadable = error as? LoadableError {
            self = loadable
        } else if error is CancellationError {
            self = LoadableError(code: .cancelled, message: "The operation was cancelled.")
        } else {
            let nsError = error as NSError
            let code: Code
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    code = .timeout
                case NSURLErrorCancelled:
                    code = .cancelled
                case NSURLErrorUserAuthenticationRequired:
                    code = .unauthorized
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                    code = .network
                default:
                    code = .network
                }
            } else {
                code = .unknown
            }
            self = LoadableError(
                code: code,
                message: error.localizedDescription,
                debugDetails: "\(nsError.domain):\(nsError.code)"
            )
        }
    }

    public var description: String {
        if let details = debugDetails {
            return "[\(code.rawValue)] \(message) (\(details))"
        }
        return "[\(code.rawValue)] \(message)"
    }
}
