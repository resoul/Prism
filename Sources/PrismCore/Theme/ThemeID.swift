import Foundation

/// Extensible identifier for named themes.
public struct ThemeID: Hashable, Equatable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    public static func == (lhs: ThemeID, rhs: ThemeID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    // MARK: - Predefined Themes
    public static let light = ThemeID("light")
    public static let dark = ThemeID("dark")
    public static let midnight = ThemeID("midnight")

    // MARK: - Factory for custom themes
    public static func brand(_ name: String) -> ThemeID {
        ThemeID("brand-\(name)")
    }
}
