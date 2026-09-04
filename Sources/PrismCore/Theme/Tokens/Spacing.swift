import Foundation
import CoreGraphics

/// Spacing token system providing standard layout offsets and gaps based on a multiplier.
public struct Spacing: Equatable, Sendable {
    public let base: CGFloat
    public let none: CGFloat
    public let xxs: CGFloat
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let xxl: CGFloat

    public init(
        base: CGFloat = 4,
        xxs: CGFloat? = nil,
        xs: CGFloat? = nil,
        sm: CGFloat? = nil,
        md: CGFloat? = nil,
        lg: CGFloat? = nil,
        xl: CGFloat? = nil,
        xxl: CGFloat? = nil
    ) {
        self.base = base
        self.none = 0
        self.xxs = xxs ?? (base * 0.5)
        self.xs = xs ?? (base * 1.0)
        self.sm = sm ?? (base * 2.0)
        self.md = md ?? (base * 4.0)
        self.lg = lg ?? (base * 6.0)
        self.xl = xl ?? (base * 8.0)
        self.xxl = xxl ?? (base * 12.0)
    }

    /// Computes an arbitrary multiple of the base spacing.
    public func value(_ multiplier: CGFloat) -> CGFloat {
        base * multiplier
    }

    /// Validates that no spacing token has a negative value.
    public func validate() throws {
        if base < 0 { throw SpacingValidationError.negativeValue(base) }
        if xxs < 0 { throw SpacingValidationError.negativeValue(xxs) }
        if xs < 0 { throw SpacingValidationError.negativeValue(xs) }
        if sm < 0 { throw SpacingValidationError.negativeValue(sm) }
        if md < 0 { throw SpacingValidationError.negativeValue(md) }
        if lg < 0 { throw SpacingValidationError.negativeValue(lg) }
        if xl < 0 { throw SpacingValidationError.negativeValue(xl) }
        if xxl < 0 { throw SpacingValidationError.negativeValue(xxl) }
    }
}

public enum SpacingValidationError: Error, Equatable, Sendable {
    case negativeValue(CGFloat)
}
