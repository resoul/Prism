import Foundation

/// Interceptor for modifying outgoing requests (e.g. injecting auth tokens).
public protocol HTTPRequestInterceptor: Sendable {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
}

/// Simple Bearer token injector implementing `HTTPRequestInterceptor`.
public struct BearerTokenInterceptor: HTTPRequestInterceptor {
    public let tokenProvider: @Sendable () async throws -> String?

    public init(tokenProvider: @escaping @Sendable () async throws -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        guard let token = try await tokenProvider() else { return request }
        return request.header("Authorization", "Bearer \(token)")
    }
}

/// Exponential backoff retry policy for resilient HTTP requests.
public struct RetryPolicy: Sendable, Equatable {
    public var maxAttempts: Int
    public var initialDelay: TimeInterval
    public var maxDelay: TimeInterval
    public var backoffMultiplier: Double
    public var jitter: Bool

    public init(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 0.2,
        maxDelay: TimeInterval = 2.0,
        backoffMultiplier: Double = 2.0,
        jitter: Bool = true
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.initialDelay = max(0.01, initialDelay)
        self.maxDelay = max(initialDelay, maxDelay)
        self.backoffMultiplier = max(1.0, backoffMultiplier)
        self.jitter = jitter
    }

    public static let `default` = RetryPolicy()
    public static let none = RetryPolicy(maxAttempts: 1)

    /// Computes sleep delay for a given 0-indexed attempt with slight jitter.
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let exponential = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        let capped = min(maxDelay, exponential)
        if jitter {
            let j = Double.random(in: 0.9...1.1)
            return capped * j
        }
        return capped
    }
}

/// Configurable, resilient HTTP client featuring request interceptors, automatic retries, and decoding.
public final class HTTPClient: Sendable {
    public let baseURL: URL?
    public let transport: any HTTPTransport
    public let defaultHeaders: [String: String]
    public let interceptors: [any HTTPRequestInterceptor]
    public let retryPolicy: RetryPolicy

    public init(
        baseURL: URL? = nil,
        transport: any HTTPTransport = URLSessionTransport(),
        defaultHeaders: [String: String] = [:],
        interceptors: [any HTTPRequestInterceptor] = [],
        retryPolicy: RetryPolicy = .default
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.defaultHeaders = defaultHeaders
        self.interceptors = interceptors
        self.retryPolicy = retryPolicy
    }

    /// Executes an HTTP request with interceptors and retry policies.
    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        var req = request

        // Merge base URL if request URL is relative
        if let baseURL {
            if req.url.scheme == "relative" || req.url.scheme == nil {
                let path = req.url.path
                let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
                req.url = baseURL.appendingPathComponent(cleanPath)
            }
        }

        // Apply default headers (request-specific headers override defaults)
        for (k, v) in defaultHeaders where req.headers[k] == nil {
            req.headers[k] = v
        }

        // Apply interceptors
        for interceptor in interceptors {
            req = try await interceptor.intercept(req)
        }

        var attempt = 0
        var lastError: any Error = HTTPError.badURL(req.url.absoluteString)

        while attempt < retryPolicy.maxAttempts {
            attempt += 1

            do {
                let response = try await transport.send(request: req)

                // Check status code success
                if response.isSuccess {
                    return response
                }

                let statusErr = HTTPError.statusError(statusCode: response.statusCode, response: response)
                if statusErr.isRetryable && attempt < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay(forAttempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    throw statusErr
                }
            } catch let error as HTTPError {
                lastError = error
                if error.isRetryable && attempt < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay(forAttempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            } catch {
                lastError = error
                if attempt < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay(forAttempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw HTTPError.transportError(error)
            }
        }

        throw lastError
    }

    /// Executes an HTTP request and decodes the response body into the expected Decodable type.
    public func request<T: Decodable>(
        _ req: HTTPRequest,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response = try await execute(req)
        return try response.decode(T.self, decoder: decoder)
    }

    /// Executes an HTTP request and returns the raw HTTPResponse.
    public func send(_ req: HTTPRequest) async throws -> HTTPResponse {
        try await execute(req)
    }

    /// Executes an HTTP request and decodes the response body into the expected Decodable type.
    public func send<T: Decodable>(
        _ req: HTTPRequest,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await request(req, decoder: decoder)
    }
}
