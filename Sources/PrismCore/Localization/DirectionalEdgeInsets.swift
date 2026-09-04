import Foundation
import CoreGraphics

/// Direction-agnostic resolved insets with concrete physical coordinates.
public struct AbsoluteEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public static let zero = AbsoluteEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public var horizontal: CGFloat { left + right }
    public var vertical: CGFloat { top + bottom }
}

/// Semantic edge insets that respect reading direction (leading/trailing).
public struct DirectionalEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public init(all: CGFloat) {
        self.init(top: all, leading: all, bottom: all, trailing: all)
    }

    public init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    public static let zero = DirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    /// Resolves leading/trailing into physical left/right insets based on the given layout direction.
    public func resolved(for direction: LayoutDirection) -> AbsoluteEdgeInsets {
        switch direction {
        case .leftToRight:
            return AbsoluteEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        case .rightToLeft:
            return AbsoluteEdgeInsets(top: top, left: trailing, bottom: bottom, right: leading)
        }
    }
}

/// Semantic horizontal alignment honoring layout direction.
public enum HorizontalAlignment: String, Sendable, CaseIterable {
    case leading
    case center
    case trailing

    /// Resolves to a physical horizontal alignment for the given layout direction.
    public func absolute(for direction: LayoutDirection) -> AbsoluteHorizontalAlignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return direction == .rightToLeft ? .right : .left
        case .trailing:
            return direction == .rightToLeft ? .left : .right
        }
    }
}

/// Physical horizontal alignment in coordinate space.
public enum AbsoluteHorizontalAlignment: String, Sendable, CaseIterable {
    case left
    case center
    case right
}
