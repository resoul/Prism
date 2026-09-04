import XCTest
import Foundation
@testable import PrismData

final class HTTPClientTests: XCTestCase {

    struct UserDTO: Codable, Equatable {
        let id: String
        let name: String
    }

    func testSuccessfulGETRequestAndDecoding() async throws {
        let mockTransport = MockHTTPTransport()
        let expectedUser = UserDTO(id: "u_123", name: "Alice")
        let userData = try JSONEncoder().encode(expectedUser)

        mockTransport.stub(
            urlPattern: "api.example.com/users/u_123",
            response: HTTPResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: userData)
        )

        let client = HTTPClient(baseURL: URL(string: "https://api.example.com")!, transport: mockTransport)
        let request = HTTPRequest(path: "/users/u_123")

        let user: UserDTO = try await client.send(request)
        XCTAssertEqual(user, expectedUser)
    }

    func testBearerTokenInterceptor() async throws {
        let mockTransport = MockHTTPTransport()
        let client = HTTPClient(
            baseURL: URL(string: "https://api.example.com")!,
            transport: mockTransport,
            interceptors: [BearerTokenInterceptor(tokenProvider: { "secret_jwt_token" })]
        )

        mockTransport.stub(
            urlPattern: "api.example.com/secure",
            response: HTTPResponse(statusCode: 200, headers: [:], body: Data())
        )

        let request = HTTPRequest(path: "/secure")
        _ = try await client.send(request)

        XCTAssertEqual(mockTransport.sentRequests.count, 1)
        let sentReq = mockTransport.sentRequests[0]
        XCTAssertEqual(sentReq.headers["Authorization"], "Bearer secret_jwt_token")
    }

    func testHeaderRedactionDoesNotLeakSecretsInLogs() {
        let headers: [String: String] = [
            "Authorization": "Bearer super_sensitive_token_12345",
            "X-API-Key": "my_secret_key",
            "Cookie": "session_id=abcdef123456",
            "Content-Type": "application/json"
        ]

        let sanitized = HeaderSanitizer.sanitize(headers)
        XCTAssertEqual(sanitized["Authorization"], "Bearer *******")
        XCTAssertEqual(sanitized["X-API-Key"], "[REDACTED]")
        XCTAssertEqual(sanitized["Cookie"], "[REDACTED]")
        XCTAssertEqual(sanitized["Content-Type"], "application/json")
    }

    func testStatusErrorHandling() async {
        let mockTransport = MockHTTPTransport()
        mockTransport.stub(
            urlPattern: "api.example.com/missing",
            response: HTTPResponse(statusCode: 404, headers: [:], body: "Not found".data(using: .utf8)!)
        )

        let client = HTTPClient(baseURL: URL(string: "https://api.example.com")!, transport: mockTransport)
        let request = HTTPRequest(path: "/missing")

        do {
            let _: UserDTO = try await client.send(request)
            XCTFail("Expected 404 status error")
        } catch let error as HTTPError {
            if case .statusError(let code, _) = error {
                XCTAssertEqual(code, 404)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected non-HTTP error: \(error)")
        }
    }

    func testRetryPolicyOnTransientFailures() async throws {
        final class SafeCounter: @unchecked Sendable {
            private let lock = NSLock()
            private var count = 0
            func next() -> Int {
                lock.withLock {
                    count += 1
                    return count
                }
            }
            var current: Int { lock.withLock { count } }
        }

        let mockTransport = MockHTTPTransport()
        let counter = SafeCounter()
        let user = UserDTO(id: "retry_id", name: "Bob")
        let data = try JSONEncoder().encode(user)

        mockTransport.customHandler = { req in
            let attempt = counter.next()
            if attempt < 3 {
                return HTTPResponse(statusCode: 503, headers: [:], body: Data())
            } else {
                return HTTPResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: data)
            }
        }

        let retryPolicy = RetryPolicy(maxAttempts: 3, initialDelay: 0.01, maxDelay: 0.1, backoffMultiplier: 1.5, jitter: false)
        let client = HTTPClient(
            baseURL: URL(string: "https://api.example.com")!,
            transport: mockTransport,
            retryPolicy: retryPolicy
        )

        let resolved: UserDTO = try await client.send(HTTPRequest(path: "/retry-endpoint"))
        XCTAssertEqual(resolved, user)
        XCTAssertEqual(counter.current, 3)
    }
}
