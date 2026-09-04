import Foundation

/// Pure, immutable value representation of an outgoing HTTP request.
public struct HTTPRequest: Sendable, Equatable {
    public var url: URL
    public var method: HTTPMethod
    public var headers: [String: String]
    public var queryItems: [URLQueryItem]
    public var body: Data?
    public var timeout: TimeInterval
    public var cachePolicy: URLRequest.CachePolicy

    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        timeout: TimeInterval = 30.0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }

    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        timeout: TimeInterval = 30.0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let dummyURL = URL(string: path.hasPrefix("/") ? "relative:\(path)" : "relative:/\(path)") ?? URL(string: "about:blank")!
        self.init(
            url: dummyURL,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: body,
            timeout: timeout,
            cachePolicy: cachePolicy
        )
    }

    public init(
        string: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        timeout: TimeInterval = 30.0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let url = URL(string: string) ?? URL(string: "about:blank")!
        self.init(
            url: url,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: body,
            timeout: timeout,
            cachePolicy: cachePolicy
        )
    }

    /// Headers with credentials, tokens, and cookies safely redacted for logging.
    public var sanitizedHeaders: [String: String] {
        HeaderSanitizer.sanitize(headers)
    }

    // MARK: - Fluent Builders

    public func header(_ name: String, _ value: String) -> HTTPRequest {
        var copy = self
        copy.headers[name] = value
        return copy
    }

    public func queryItem(_ name: String, _ value: String?) -> HTTPRequest {
        var copy = self
        copy.queryItems.append(URLQueryItem(name: name, value: value))
        return copy
    }

    public func body(_ data: Data?) -> HTTPRequest {
        var copy = self
        copy.body = data
        return copy
    }

    public func jsonBody<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws -> HTTPRequest {
        var copy = self
        copy.body = try encoder.encode(value)
        copy.headers["Content-Type"] = "application/json"
        return copy
    }

    public func timeout(_ interval: TimeInterval) -> HTTPRequest {
        var copy = self
        copy.timeout = interval
        return copy
    }

    /// Resolves this request into a Foundation `URLRequest`.
    public func makeURLRequest() throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw HTTPError.badURL(url.absoluteString)
        }

        if !queryItems.isEmpty {
            var existing = components.queryItems ?? []
            existing.append(contentsOf: queryItems)
            components.queryItems = existing
        }

        guard let finalURL = components.url else {
            throw HTTPError.badURL(url.absoluteString)
        }

        var req = URLRequest(url: finalURL)
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = headers
        req.httpBody = body
        req.timeoutInterval = timeout
        req.cachePolicy = cachePolicy
        return req
    }
}
