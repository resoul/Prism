import Foundation

/// Strongly typed element key for stable identity in collections and conditional branches.
public struct ElementKey: Hashable, Sendable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, CustomStringConvertible, Codable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(stringLiteral value: String) {
        self.value = value
    }

    public init(integerLiteral value: Int) {
        self.value = String(value)
    }

    public var description: String {
        value
    }
}
