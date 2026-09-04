import Foundation

/// Primary flex axis direction.
public enum FlexDirection: String, Equatable, Sendable, CustomStringConvertible, Codable {
    case row
    case column
    case rowReverse
    case columnReverse

    public var isRow: Bool {
        self == .row || self == .rowReverse
    }

    public var isColumn: Bool {
        self == .column || self == .columnReverse
    }

    public var isReverse: Bool {
        self == .rowReverse || self == .columnReverse
    }

    public var description: String { rawValue }
}

/// Alignment along the main axis.
public enum JustifyContent: String, Equatable, Sendable, CustomStringConvertible, Codable {
    case start
    case center
    case end
    case spaceBetween
    case spaceAround
    case spaceEvenly

    public var description: String { rawValue }
}

/// Alignment along the cross axis.
public enum AlignItems: String, Equatable, Sendable, CustomStringConvertible, Codable {
    case start
    case center
    case end
    case stretch
    case baseline

    public var description: String { rawValue }
}

/// Wrapping behavior when flex items exceed main axis space.
public enum FlexWrap: String, Equatable, Sendable, CustomStringConvertible, Codable {
    case noWrap
    case wrap
    case wrapReverse

    public var description: String { rawValue }
}

/// Positioning model of a layout node.
public enum PositionType: String, Equatable, Sendable, CustomStringConvertible, Codable {
    /// Normal flow positioning; participates in flex sizing and flow.
    case flow

    /// Positioned relative to the nearest containing block; excluded from flow sizing.
    case absolute

    /// Positioned relative to the viewport/window; excluded from flow sizing.
    case fixed

    public var description: String { rawValue }
}

/// Inset offsets for `.absolute` and `.fixed` positioned elements.
public struct EdgeOffsets: Equatable, Sendable, CustomStringConvertible {
    public var top: Double?
    public var leading: Double?
    public var bottom: Double?
    public var trailing: Double?

    public init(top: Double? = nil, leading: Double? = nil, bottom: Double? = nil, trailing: Double? = nil) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static let zero = EdgeOffsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    public var description: String {
        var parts: [String] = []
        if let top { parts.append("t: \(top)") }
        if let leading { parts.append("l: \(leading)") }
        if let bottom { parts.append("b: \(bottom)") }
        if let trailing { parts.append("tr: \(trailing)") }
        return parts.isEmpty ? "none" : parts.joined(separator: ", ")
    }
}

/// Behavior when child content exceeds container bounds.
public enum OverflowPolicy: String, Equatable, Sendable, CustomStringConvertible, Codable {
    case visible
    case hidden
    case scroll

    public var description: String { rawValue }
}
