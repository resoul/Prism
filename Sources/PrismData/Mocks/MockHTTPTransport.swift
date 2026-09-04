import Foundation

/// In-memory mock HTTP transport for deterministic testing without network calls.
public final class MockHTTPTransport: HTTPTransport, @unchecked Sendable {
    public typealias Handler = @Sendable (HTTPRequest) throws -> HTTPResponse

    private let lock = NSLock()
    private var _recordedRequests: [HTTPRequest] = []
    private var _handler: Handler?
    private var _stubs: [(pattern: String, response: HTTPResponse)] = []

    public var recordedRequests: [HTTPRequest] {
        lock.withLock { _recordedRequests }
    }

    public var sentRequests: [HTTPRequest] {
        lock.withLock { _recordedRequests }
    }

    public var lastRequest: HTTPRequest? {
        lock.withLock { _recordedRequests.last }
    }

    public var customHandler: Handler? {
        get { lock.withLock { _handler } }
        set { lock.withLock { _handler = newValue } }
    }

    public init(handler: Handler? = nil) {
        self._handler = handler
    }

    /// Sets a custom handler for synthesizing responses.
    public func setHandler(_ handler: @escaping Handler) {
        lock.withLock { _handler = handler }
    }

    /// Stubs a specific URL pattern with a predetermined response.
    public func stub(urlPattern: String, response: HTTPResponse) {
        lock.withLock {
            _stubs.append((pattern: urlPattern, response: response))
        }
    }

    /// Convenience for returning JSON payload with a given status code.
    public func respondWithJSON<T: Encodable>(_ object: T, statusCode: Int = 200) {
        setHandler { _ in
            let data = try JSONEncoder().encode(object)
            return HTTPResponse(statusCode: statusCode, headers: ["Content-Type": "application/json"], data: data)
        }
    }

    /// Convenience for returning raw data and status code.
    public func respond(statusCode: Int, data: Data = Data(), headers: [String: String] = [:]) {
        setHandler { _ in
            HTTPResponse(statusCode: statusCode, headers: headers, data: data)
        }
    }

    public func send(request: HTTPRequest) async throws -> HTTPResponse {
        lock.withLock {
            _recordedRequests.append(request)
        }

        let (stubs, handler) = lock.withLock { (_stubs, _handler) }

        for stub in stubs {
            if request.url.absoluteString.contains(stub.pattern) {
                return stub.response
            }
        }

        if let handler {
            return try handler(request)
        }

        return HTTPResponse(statusCode: 200, headers: [:], data: Data())
    }

    public func reset() {
        lock.withLock {
            _recordedRequests.removeAll()
            _stubs.removeAll()
            _handler = nil
        }
    }
}
