import Foundation

/// Layout constraints and flex parameters governing element measurement and positioning.
public struct LayoutStyle: Equatable, Sendable, CustomStringConvertible {
    public var width: SizeValue
    public var height: SizeValue
    public var minWidth: Double?
    public var maxWidth: Double?
    public var minHeight: Double?
    public var maxHeight: Double?
    public var padding: DirectionalEdgeInsets
    public var margin: DirectionalEdgeInsets
    public var aspectRatio: Double?
    public var flexGrow: Double
    public var flexShrink: Double
    public var alignSelf: AlignItems?
    public var direction: FlexDirection
    public var justifyContent: JustifyContent
    public var alignItems: AlignItems
    public var flexWrap: FlexWrap
    public var gap: Double
    public var crossGap: Double
    public var positionType: PositionType
    public var offsets: EdgeOffsets
    public var zIndex: Int
    public var overflowPolicy: OverflowPolicy

    public init(
        width: SizeValue = .intrinsic,
        height: SizeValue = .intrinsic,
        minWidth: Double? = nil,
        maxWidth: Double? = nil,
        minHeight: Double? = nil,
        maxHeight: Double? = nil,
        padding: DirectionalEdgeInsets = .zero,
        margin: DirectionalEdgeInsets = .zero,
        aspectRatio: Double? = nil,
        flexGrow: Double = 0.0,
        flexShrink: Double = 0.0,
        alignSelf: AlignItems? = nil,
        direction: FlexDirection = .column,
        justifyContent: JustifyContent = .start,
        alignItems: AlignItems = .start,
        flexWrap: FlexWrap = .noWrap,
        gap: Double = 0.0,
        crossGap: Double = 0.0,
        positionType: PositionType = .flow,
        offsets: EdgeOffsets = EdgeOffsets(),
        zIndex: Int = 0,
        overflowPolicy: OverflowPolicy = .visible
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth.map { max(0, $0) }
        self.maxWidth = maxWidth.map { max(0, $0) }
        self.minHeight = minHeight.map { max(0, $0) }
        self.maxHeight = maxHeight.map { max(0, $0) }
        self.padding = padding
        self.margin = margin
        self.aspectRatio = aspectRatio.map { max(0.001, $0) }
        self.flexGrow = max(0.0, flexGrow)
        self.flexShrink = max(0.0, flexShrink)
        self.alignSelf = alignSelf
        self.direction = direction
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.flexWrap = flexWrap
        self.gap = max(0, gap)
        self.crossGap = max(0, crossGap)
        self.positionType = positionType
        self.offsets = offsets
        self.zIndex = zIndex
        self.overflowPolicy = overflowPolicy
    }

    public static let `default` = LayoutStyle()

    public var description: String {
        var parts: [String] = []
        if width != .intrinsic { parts.append("w: \(width)") }
        if height != .intrinsic { parts.append("h: \(height)") }
        if direction != .column { parts.append("dir: \(direction)") }
        if justifyContent != .start { parts.append("justify: \(justifyContent)") }
        if alignItems != .start { parts.append("align: \(alignItems)") }
        if gap > 0 { parts.append("gap: \(gap)") }
        if positionType != .flow { parts.append("pos: \(positionType)") }
        if let minWidth { parts.append("minW: \(minWidth)") }
        if let maxWidth { parts.append("maxW: \(maxWidth)") }
        if let minHeight { parts.append("minH: \(minHeight)") }
        if let maxHeight { parts.append("maxH: \(maxHeight)") }
        if padding != .zero { parts.append("padding: \(padding)") }
        if margin != .zero { parts.append("margin: \(margin)") }
        return "LayoutStyle(\(parts.joined(separator: ", ")))"
    }
}
