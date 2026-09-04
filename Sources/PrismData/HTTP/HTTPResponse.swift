import Foundation

/// Value type representing a completed HTTP response.
public struct HTTPResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let data: Data

    public init(statusCode: Int, headers: [String: String] = [:], data: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
    }

    public init(statusCode: Int, headers: [String: String] = [:], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = body
    }

    public var body: Data {
        data
    }

    /// True if the HTTP status code is within 200...299.
    public var isSuccess: Bool {
        (200..<300).contains(statusCode)
    }

    /// Headers with credentials safely redacted for diagnostic output.
    public var sanitizedHeaders: [String: String] {
        HeaderSanitizer.sanitize(headers)
    }

    /// Decodes the response body into a target Decodable type.
    public func decode<T: Decodable>(_ type: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let err as DecodingError {
            throw HTTPError.decodingError(err, data)
        } catch {
            throw error
        }
    }
}
