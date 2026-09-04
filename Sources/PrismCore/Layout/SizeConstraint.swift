import Foundation

/// Constraint applied to a single layout dimension during the measure pass.
public enum DimensionConstraint: Equatable, Sendable, CustomStringConvertible {
    /// Parent offers unbounded available space (e.g. inside a scroll view or intrinsic sizing).
    /// Distinct from `.exactly(0)`!
    case unspecified

    /// Parent specifies an upper bound. The child can choose any size up to this limit.
    case atMost(Double)

    /// Parent enforces an exact size.
    case exactly(Double)

    public var maxAvailable: Double? {
        switch self {
        case .unspecified:
            return nil
        case .atMost(let v), .exactly(let v):
            return max(0, v)
        }
    }

    public var description: String {
        switch self {
        case .unspecified: return "unspecified"
        case .atMost(let v): return "atMost(\(v))"
        case .exactly(let v): return "exactly(\(v))"
        }
    }
}

/// 2D space constraint offered by a parent during the layout measure pass.
public struct SizeConstraint: Equatable, Sendable, CustomStringConvertible {
    public var width: DimensionConstraint
    public var height: DimensionConstraint

    public init(width: DimensionConstraint = .unspecified, height: DimensionConstraint = .unspecified) {
        self.width = width
        self.height = height
    }

    public static let unconstrained = SizeConstraint(width: .unspecified, height: .unspecified)

    public static func atMost(width: Double? = nil, height: Double? = nil) -> SizeConstraint {
        SizeConstraint(
            width: width.map { .atMost(max(0, $0)) } ?? .unspecified,
            height: height.map { .atMost(max(0, $0)) } ?? .unspecified
        )
    }

    public static func exactly(width: Double? = nil, height: Double? = nil) -> SizeConstraint {
        SizeConstraint(
            width: width.map { .exactly(max(0, $0)) } ?? .unspecified,
            height: height.map { .exactly(max(0, $0)) } ?? .unspecified
        )
    }

    public var description: String {
        "SizeConstraint(w: \(width), h: \(height))"
    }
}
