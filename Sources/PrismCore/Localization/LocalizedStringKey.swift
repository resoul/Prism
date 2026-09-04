import Foundation

/// Type representing a localizable string key supporting string interpolation and arguments.
public struct LocalizedStringKey: Hashable, Sendable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation, CustomStringConvertible {
    public let key: String
    public let arguments: [String]
    public let tableName: String?

    public init(_ key: String, arguments: [String] = [], tableName: String? = nil) {
        self.key = key
        self.arguments = arguments
        self.tableName = tableName
    }

    public init(stringLiteral value: String) {
        self.key = value
        self.arguments = []
        self.tableName = nil
    }

    public init(stringInterpolation: StringInterpolation) {
        self.key = stringInterpolation.formatKey
        self.arguments = stringInterpolation.arguments
        self.tableName = nil
    }

    public var description: String {
        if arguments.isEmpty {
            return key
        }
        return "\(key)(\(arguments.joined(separator: ", ")))"
    }

    public struct StringInterpolation: StringInterpolationProtocol, Sendable {
        public var formatKey: String = ""
        public var arguments: [String] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            formatKey.reserveCapacity(literalCapacity)
            arguments.reserveCapacity(interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            formatKey.append(literal)
        }

        public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T) {
            arguments.append(value.description)
            formatKey.append("%@")
        }

        public mutating func appendInterpolation(_ value: Int) {
            arguments.append(String(value))
            formatKey.append("%lld")
        }

        public mutating func appendInterpolation(_ value: Double, format: String = "%.2f") {
            arguments.append(String(format: format, value))
            formatKey.append("%@")
        }
    }
}
