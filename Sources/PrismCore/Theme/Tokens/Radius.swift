import Foundation
import CoreGraphics

/// Corner radius tokens for rounded rectangles and surfaces.
public struct Radius: Equatable, Sendable {
    public let none: CGFloat
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let full: CGFloat

    public init(
        xs: CGFloat = 2,
        sm: CGFloat = 6,
        md: CGFloat = 10,
        lg: CGFloat = 16,
        xl: CGFloat = 24,
        full: CGFloat = 9_999
    ) {
        self.none = 0
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.full = full
    }

    /// Validates that no radius token has a negative value.
    public func validate() throws {
        if xs < 0 { throw RadiusValidationError.negativeValue(xs) }
        if sm < 0 { throw RadiusValidationError.negativeValue(sm) }
        if md < 0 { throw RadiusValidationError.negativeValue(md) }
        if lg < 0 { throw RadiusValidationError.negativeValue(lg) }
        if xl < 0 { throw RadiusValidationError.negativeValue(xl) }
        if full < 0 { throw RadiusValidationError.negativeValue(full) }
    }
}

public enum RadiusValidationError: Error, Equatable, Sendable {
    case negativeValue(CGFloat)
}
