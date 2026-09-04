import Foundation
@_exported import PrismCore

/// Declarative component rendering a multi-color 2D mesh gradient using Metal shaders,
/// with automatic linear gradient fallback on unsupported devices.
public struct MeshGradient: Component {
    public let grid: MeshGradientGrid
    public var width: Double?
    public var height: Double?

    public init(
        grid: MeshGradientGrid,
        width: Double? = nil,
        height: Double? = nil
    ) {
        self.grid = grid
        self.width = width
        self.height = height
    }

    /// Convenience initializer defining a grid of dimensions (columns x rows) with corresponding colors.
    public init(
        columns: Int,
        rows: Int,
        colors: [Color],
        width: Double? = nil,
        height: Double? = nil
    ) {
        let cols = max(2, columns)
        let rws = max(2, rows)
        var points: [MeshGradientPoint] = []

        for r in 0..<rws {
            for c in 0..<cols {
                let x = Double(c) / Double(cols - 1)
                let y = Double(r) / Double(rws - 1)
                let idx = r * cols + c
                let color = idx < colors.count ? colors[idx] : .clear
                points.append(MeshGradientPoint(x: x, y: y, color: color))
            }
        }

        self.grid = MeshGradientGrid(width: cols, height: rws, points: points)
        self.width = width
        self.height = height
    }

    public func body(context: ComponentContext) -> RenderElement {
        var modifiers: [ElementModifier] = [.meshGradient(grid)]
        if let width {
            modifiers.append(.width(width))
        }
        if let height {
            modifiers.append(.height(height))
        }

        return RenderElement(
            id: ElementID(typeName: "MeshGradient"),
            kind: .custom("MeshGradient"),
            modifiers: modifiers
        )
    }
}
