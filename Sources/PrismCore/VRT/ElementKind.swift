import Foundation

/// Shape kinds for vector primitives in the Virtual Render Tree.
public enum ShapeKind: Hashable, Sendable, CustomStringConvertible, Codable {
    case rectangle(cornerRadius: Double)
    case circle

    public var description: String {
        switch self {
        case .rectangle(let radius):
            return "rectangle(radius: \(radius))"
        case .circle:
            return "circle"
        }
    }
}

/// Axis for stack layouts.
public enum LayoutAxis: String, Hashable, Sendable, CustomStringConvertible, Codable {
    case horizontal
    case vertical

    public var description: String { rawValue }
}

/// Cross-axis alignment for stack layouts.
public enum StackAlignment: String, Hashable, Sendable, CustomStringConvertible, Codable {
    case start
    case center
    case end
    case stretch

    public var description: String { rawValue }
}

/// Structural and visual element kinds in the Virtual Render Tree.
public enum ElementKind: Hashable, Sendable, CustomStringConvertible {
    case stack(axis: LayoutAxis, alignment: StackAlignment, spacing: Double)
    case text(String)
    case shape(ShapeKind)
    case spacer(minLength: Double?)
    case icon(source: IconSource)
    case group
    case empty
    case custom(String)
    case portal(targetLayer: OverlayLayer)

    public static func icon(name: String, bundle: String? = nil) -> ElementKind {
        if let bundle {
            return .icon(source: .svg(named: name, bundle: bundle))
        }
        return .icon(source: .sf(name: name))
    }

    public var description: String {
        switch self {
        case .stack(let axis, let alignment, let spacing):
            return "Stack(axis: \(axis), alignment: \(alignment), spacing: \(spacing))"
        case .text(let text):
            return "Text(\"\(text)\")"
        case .shape(let shape):
            return "Shape(\(shape))"
        case .spacer(let minLength):
            if let minLength {
                return "Spacer(minLength: \(minLength))"
            }
            return "Spacer"
        case .icon(let source):
            return "Icon(\(source))"
        case .group:
            return "Group"
        case .empty:
            return "Empty"
        case .custom(let name):
            return "Custom(\(name))"
        case .portal(let targetLayer):
            return "Portal(targetLayer: \(targetLayer.rawValue))"
        }
    }
}
