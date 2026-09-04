import Foundation

/// Modifiers applied to Virtual Render Tree elements.
public enum ElementModifier: Equatable, Sendable, CustomStringConvertible {
    case width(Double)
    case height(Double)
    case minWidth(Double)
    case maxWidth(Double)
    case minHeight(Double)
    case maxHeight(Double)
    case padding(DirectionalEdgeInsets)
    case margin(DirectionalEdgeInsets)
    case background(Color)
    case opacity(Double)
    case zIndex(Int)
    case explicitKey(String)
    case testID(String)

    public var description: String {
        switch self {
        case .width(let w): return "width(\(w))"
        case .height(let h): return "height(\(h))"
        case .minWidth(let w): return "minWidth(\(w))"
        case .maxWidth(let w): return "maxWidth(\(w))"
        case .minHeight(let h): return "minHeight(\(h))"
        case .maxHeight(let h): return "maxHeight(\(h))"
        case .padding(let insets):
            return "padding(t: \(insets.top), l: \(insets.leading), b: \(insets.bottom), tr: \(insets.trailing))"
        case .margin(let insets):
            return "margin(t: \(insets.top), l: \(insets.leading), b: \(insets.bottom), tr: \(insets.trailing))"
        case .background(let color): return "background(\(color))"
        case .opacity(let o): return "opacity(\(o))"
        case .zIndex(let z): return "zIndex(\(z))"
        case .explicitKey(let k): return "key(\"\(k)\")"
        case .testID(let id): return "testID(\"\(id)\")"
        }
    }
}

/// Resolved layout and visual style folded from an array of ElementModifiers.
public struct ResolvedStyle: Equatable, Sendable, CustomStringConvertible {
    public var width: Double?
    public var height: Double?
    public var minWidth: Double?
    public var maxWidth: Double?
    public var minHeight: Double?
    public var maxHeight: Double?
    public var padding: DirectionalEdgeInsets
    public var margin: DirectionalEdgeInsets
    public var background: Color?
    public var opacity: Double
    public var zIndex: Int

    public init(
        width: Double? = nil,
        height: Double? = nil,
        minWidth: Double? = nil,
        maxWidth: Double? = nil,
        minHeight: Double? = nil,
        maxHeight: Double? = nil,
        padding: DirectionalEdgeInsets = .zero,
        margin: DirectionalEdgeInsets = .zero,
        background: Color? = nil,
        opacity: Double = 1.0,
        zIndex: Int = 0
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.padding = padding
        self.margin = margin
        self.background = background
        self.opacity = opacity
        self.zIndex = zIndex
    }

    /// Resolves an array of modifiers using deterministic precedence rules:
    /// - Dimensions: later overrides earlier.
    /// - Padding: accumulates (outer + inner).
    /// - Margin: accumulates (outer + inner).
    /// - Opacity: multiplicative (outer * inner, clamped to [0.0, 1.0]).
    /// - Background: later overrides earlier.
    /// - zIndex: later overrides earlier.
    public static func resolve(from modifiers: [ElementModifier]) -> ResolvedStyle {
        var style = ResolvedStyle()

        for modifier in modifiers {
            switch modifier {
            case .width(let w):
                style.width = w
            case .height(let h):
                style.height = h
            case .minWidth(let w):
                style.minWidth = w
            case .maxWidth(let w):
                style.maxWidth = w
            case .minHeight(let h):
                style.minHeight = h
            case .maxHeight(let h):
                style.maxHeight = h
            case .padding(let insets):
                style.padding = DirectionalEdgeInsets(
                    top: style.padding.top + insets.top,
                    leading: style.padding.leading + insets.leading,
                    bottom: style.padding.bottom + insets.bottom,
                    trailing: style.padding.trailing + insets.trailing
                )
            case .margin(let insets):
                style.margin = DirectionalEdgeInsets(
                    top: style.margin.top + insets.top,
                    leading: style.margin.leading + insets.leading,
                    bottom: style.margin.bottom + insets.bottom,
                    trailing: style.margin.trailing + insets.trailing
                )
            case .background(let color):
                style.background = color
            case .opacity(let o):
                style.opacity = max(0.0, min(1.0, style.opacity * o))
            case .zIndex(let z):
                style.zIndex = z
            case .explicitKey, .testID:
                break
            }
        }

        return style
    }

    public var description: String {
        var parts: [String] = []
        if let width { parts.append("width: \(width)") }
        if let height { parts.append("height: \(height)") }
        if padding != .zero { parts.append("padding: \(padding)") }
        if margin != .zero { parts.append("margin: \(margin)") }
        if let background { parts.append("background: \(background)") }
        if opacity < 1.0 { parts.append("opacity: \(opacity)") }
        if zIndex != 0 { parts.append("zIndex: \(zIndex)") }
        return parts.joined(separator: ", ")
    }
}
