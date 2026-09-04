import Foundation

/// Specification of element dimensions in LayoutStyle.
public enum SizeValue: Equatable, Sendable, CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// Exact fixed point dimension.
    case fixed(Double)

    /// Fraction of available parent dimension (e.g. 0.5 for 50%).
    case fraction(Double)

    /// Sized intrinsically according to content.
    case intrinsic

    /// Expands to fill available space in parent.
    case fill

    /// Range constraint with optional lower and upper bounds.
    case range(min: Double?, max: Double?)

    public init(integerLiteral value: Int) {
        self = .fixed(Double(value))
    }

    public init(floatLiteral value: Double) {
        self = .fixed(value)
    }

    public var isFixed: Bool {
        if case .fixed = self { return true }
        return false
    }

    public var fixedValue: Double? {
        if case .fixed(let v) = self { return v }
        return nil
    }

    public var description: String {
        switch self {
        case .fixed(let v): return "fixed(\(v))"
        case .fraction(let f): return "fraction(\(f))"
        case .intrinsic: return "intrinsic"
        case .fill: return "fill"
        case .range(let minVal, let maxVal):
            let minStr = minVal != nil ? "\(minVal!)" : "nil"
            let maxStr = maxVal != nil ? "\(maxVal!)" : "nil"
            return "range(min: \(minStr), max: \(maxStr))"
        }
    }
}
