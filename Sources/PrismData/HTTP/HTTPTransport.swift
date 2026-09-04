import Foundation

/// Transport layer protocol abstracting actual network transmission for testability.
public protocol HTTPTransport: Sendable {
    func send(request: HTTPRequest) async throws -> HTTPResponse
}

/// Production transport backed by Foundation's `URLSession`.
public final class URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(request: HTTPRequest) async throws -> HTTPResponse {
        let urlReq = try request.makeURLRequest()

        do {
            let (data, response) = try await session.data(for: urlReq)
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.transportError(URLError(.badServerResponse))
            }

            var headers: [String: String] = [:]
            for (k, v) in httpResponse.allHeaderFields {
                headers[String(describing: k)] = String(describing: v)
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                headers: headers,
                data: data
            )
        } catch is CancellationError {
            throw HTTPError.cancelled
        } catch let err as URLError {
            if err.code == .cancelled {
                throw HTTPError.cancelled
            } else if err.code == .timedOut {
                throw HTTPError.timeout
            } else if err.code == .notConnectedToInternet {
                throw HTTPError.offline
            }
            throw HTTPError.transportError(err)
        } catch {
            throw HTTPError.transportError(error)
        }
    }
}
