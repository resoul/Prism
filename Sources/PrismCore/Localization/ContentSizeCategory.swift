import Foundation
import CoreGraphics

/// Platform-agnostic accessibility text size category (Dynamic Type).
public enum ContentSizeCategory: String, Hashable, Sendable, CaseIterable, Comparable {
    case extraSmall
    case small
    case medium
    case large                      // Default 1.0 baseline
    case extraLarge
    case extraExtraLarge
    case extraExtraExtraLarge
    case accessibilityMedium
    case accessibilityLarge
    case accessibilityExtraLarge
    case accessibilityExtraExtraLarge
    case accessibilityExtraExtraExtraLarge

    /// Normalized multiplier relative to `.large` baseline.
    public var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.00
        case .extraLarge: return 1.12
        case .extraExtraLarge: return 1.24
        case .extraExtraExtraLarge: return 1.36
        case .accessibilityMedium: return 1.64
        case .accessibilityLarge: return 1.95
        case .accessibilityExtraLarge: return 2.35
        case .accessibilityExtraExtraLarge: return 2.80
        case .accessibilityExtraExtraExtraLarge: return 3.40
        }
    }

    /// Whether this category belongs to the accessibility large text tiers.
    public var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    private var rank: Int {
        switch self {
        case .extraSmall: return 0
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        case .extraLarge: return 4
        case .extraExtraLarge: return 5
        case .extraExtraExtraLarge: return 6
        case .accessibilityMedium: return 7
        case .accessibilityLarge: return 8
        case .accessibilityExtraLarge: return 9
        case .accessibilityExtraExtraLarge: return 10
        case .accessibilityExtraExtraExtraLarge: return 11
        }
    }

    public static func < (lhs: ContentSizeCategory, rhs: ContentSizeCategory) -> Bool {
        lhs.rank < rhs.rank
    }

    /// Clamps category between a minimum and maximum category.
    public func clamped(min: ContentSizeCategory, max: ContentSizeCategory) -> ContentSizeCategory {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}
