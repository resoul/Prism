import Foundation

/// Measured 2D dimensions produced by the layout measure pass.
///
/// Invariant: width >= 0, height >= 0, finite, non-NaN.
public struct MeasuredSize: Equatable, Sendable, CustomStringConvertible {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        let safeW = width.isFinite ? max(0, width) : 0
        let safeH = height.isFinite ? max(0, height) : 0
        self.width = safeW
        self.height = safeH
    }

    public static let zero = MeasuredSize(width: 0, height: 0)

    public var description: String {
        "MeasuredSize(w: \(width), h: \(height))"
    }
}

/// 2D point in layout coordinates.
public struct LayoutPoint: Equatable, Sendable, CustomStringConvertible {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x.isFinite ? x : 0
        self.y = y.isFinite ? y : 0
    }

    public static let zero = LayoutPoint(x: 0, y: 0)

    public var description: String {
        "LayoutPoint(x: \(x), y: \(y))"
    }
}

/// Assigned frame rectangle produced by the layout pass.
///
/// Invariant: origin and size are finite; width and height are non-negative.
public struct LayoutFrame: Equatable, Sendable, CustomStringConvertible {
    public var origin: LayoutPoint
    public var size: MeasuredSize

    public init(origin: LayoutPoint, size: MeasuredSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double = 0, y: Double = 0, width: Double, height: Double) {
        self.origin = LayoutPoint(x: x, y: y)
        self.size = MeasuredSize(width: width, height: height)
    }

    public static let zero = LayoutFrame(origin: .zero, size: .zero)

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var width: Double { size.width }
    public var height: Double { size.height }

    public var description: String {
        "LayoutFrame(x: \(origin.x), y: \(origin.y), w: \(size.width), h: \(size.height))"
    }
}

/// Inset values on four edges.
public struct EdgeValues: Equatable, Sendable, CustomStringConvertible {
    public var top: Double
    public var leading: Double
    public var bottom: Double
    public var trailing: Double

    public init(top: Double = 0, leading: Double = 0, bottom: Double = 0, trailing: Double = 0) {
        self.top = top.isFinite ? max(0, top) : 0
        self.leading = leading.isFinite ? max(0, leading) : 0
        self.bottom = bottom.isFinite ? max(0, bottom) : 0
        self.trailing = trailing.isFinite ? max(0, trailing) : 0
    }

    public init(all: Double) {
        self.init(top: all, leading: all, bottom: all, trailing: all)
    }

    public static let zero = EdgeValues()

    public var horizontal: Double { leading + trailing }
    public var vertical: Double { top + bottom }

    public func resolved(for direction: LayoutDirection) -> AbsoluteEdgeInsets {
        DirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing).resolved(for: direction)
    }

    public var description: String {
        "EdgeValues(t: \(top), l: \(leading), b: \(bottom), tr: \(trailing))"
    }
}

/// Scale-aware pixel rounding policy to prevent subpixel visual blurriness and hairline gaps.
public struct PixelRoundingPolicy: Equatable, Sendable {
    public let scaleFactor: Double

    public init(scaleFactor: Double = 2.0) {
        self.scaleFactor = max(1.0, scaleFactor)
    }

    public func roundToPixel(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return (value * scaleFactor).rounded(.toNearestOrAwayFromZero) / scaleFactor
    }

    public func ceilToPixel(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return (value * scaleFactor).rounded(.up) / scaleFactor
    }

    public func floorToPixel(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return (value * scaleFactor).rounded(.down) / scaleFactor
    }

    public func roundPoint(_ point: LayoutPoint) -> LayoutPoint {
        LayoutPoint(x: roundToPixel(point.x), y: roundToPixel(point.y))
    }

    public func roundSize(_ size: MeasuredSize) -> MeasuredSize {
        MeasuredSize(width: ceilToPixel(size.width), height: ceilToPixel(size.height))
    }

    public func roundFrame(_ frame: LayoutFrame) -> LayoutFrame {
        let origin = roundPoint(frame.origin)
        let maxX = roundToPixel(frame.maxX)
        let maxY = roundToPixel(frame.maxY)
        let width = max(0, maxX - origin.x)
        let height = max(0, maxY - origin.y)
        return LayoutFrame(origin: origin, size: MeasuredSize(width: width, height: height))
    }
}
