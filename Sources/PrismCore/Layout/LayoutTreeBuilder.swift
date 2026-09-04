import Foundation

/// Constructs a `LayoutNode` hierarchy from a normalized `RenderElement` tree.
public enum LayoutTreeBuilder {
    /// Builds a `LayoutNode` tree corresponding to the given `RenderElement`.
    public static func build(from element: RenderElement) -> LayoutNode {
        let style = resolveLayoutStyle(from: element)
        let measurePolicy = resolveMeasurePolicy(from: element)
        let children = element.children.map { build(from: $0) }

        return LayoutNode(
            id: element.id,
            style: style,
            children: children,
            measurePolicy: measurePolicy
        )
    }

    private static func resolveLayoutStyle(from element: RenderElement) -> LayoutStyle {
        let resolved = element.resolvedStyle
        var style = LayoutStyle()

        // Dimensions
        if let w = resolved.width {
            style.width = .fixed(w)
        }
        if let h = resolved.height {
            style.height = .fixed(h)
        }
        style.minWidth = resolved.minWidth
        style.maxWidth = resolved.maxWidth
        style.minHeight = resolved.minHeight
        style.maxHeight = resolved.maxHeight
        style.padding = resolved.padding
        style.margin = resolved.margin
        style.zIndex = resolved.zIndex

        // Kind-specific flex defaults
        switch element.kind {
        case .stack(let axis, let alignment, let spacing):
            style.direction = axis == .vertical ? .column : .row
            switch alignment {
            case .start: style.alignItems = .start
            case .center: style.alignItems = .center
            case .end: style.alignItems = .end
            case .stretch: style.alignItems = .stretch
            }
            style.gap = spacing
            style.width = resolved.width.map { .fixed($0) } ?? .intrinsic
            style.height = resolved.height.map { .fixed($0) } ?? .intrinsic

        case .spacer(let minLength):
            style.flexGrow = 1.0
            if let min = minLength {
                style.minHeight = min
                style.minWidth = min
            }

        default:
            break
        }

        return style
    }

    private static func resolveMeasurePolicy(from element: RenderElement) -> MeasurePolicy? {
        switch element.kind {
        case .text(let text):
            let fontSize: Double = element.props.custom["fontRole"] == "heading" ? 22 : 16
            let lineLimit = element.props.custom["lineLimit"].flatMap { Int($0) }
            return TextMeasurePolicy(text: text, fontSize: fontSize, lineLimit: lineLimit)

        case .shape(let shapeKind):
            switch shapeKind {
            case .circle:
                return ShapeMeasurePolicy(shapeType: .circle, defaultDiameter: 40)
            case .rectangle:
                return ShapeMeasurePolicy(shapeType: .rectangle, defaultDiameter: 0)
            }

        case .spacer(let minLength):
            return SpacerMeasurePolicy(minLength: minLength ?? 0, axis: .vertical)

        case .icon:
            return ShapeMeasurePolicy(shapeType: .rectangle, defaultDiameter: 24)

        case .stack, .group, .empty, .custom, .portal:
            return nil
        }
    }
}
