import Foundation

/// Semantic text input type defining keyboard behavior, autocapitalization, and masking.
public enum TextInputMode: String, Hashable, Sendable, CaseIterable {
    /// Standard plain text input.
    case text
    /// Email address input with email-optimized keyboard.
    case email
    /// Secure password input with masked character bullets.
    case password
    /// Search query input with search action button.
    case search
    /// Numeric text input (digits, decimal separator).
    case number
    /// Web URL address input.
    case url

    /// Whether characters should be masked with bullets (e.g. for passwords).
    public var isSecure: Bool {
        self == .password
    }

    /// Bullet character used for masked text representation.
    public static let maskBullet: Character = "•"

    /// Masks a string replacing every character with the mask bullet, preserving empty strings.
    public static func mask(text: String) -> String {
        String(repeating: maskBullet, count: text.count)
    }
}
