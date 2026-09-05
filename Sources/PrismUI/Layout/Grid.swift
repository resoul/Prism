import Foundation
import PrismCore

/// A stable, independently renderable cell in an experimental `Grid`.
public struct GridCell: Sendable {
    public let placement: GridPlacement
    public let content: RenderElement

    public init(id: String, column: Int, row: Int, columnSpan: Int = 1, rowSpan: Int = 1, intrinsicHeight: Double = 44, content: RenderElement) {
        self.placement = GridPlacement(id: id, column: column, row: row, columnSpan: columnSpan, rowSpan: rowSpan, intrinsicHeight: intrinsicHeight)
        self.content = content
    }

    public init<C: ComponentConvertible>(id: String, column: Int, row: Int, columnSpan: Int = 1, rowSpan: Int = 1, intrinsicHeight: Double = 44, content: C) {
        self.init(id: id, column: column, row: row, columnSpan: columnSpan, rowSpan: rowSpan, intrinsicHeight: intrinsicHeight, content: content.asRenderElements().first ?? RenderElement(id: ElementID(typeName: "Empty"), kind: .empty))
    }
}

/// Experimental deterministic grid container. Use `GridLayoutSolver` directly
/// when a host needs frames without constructing a render tree.
public struct Grid: Component {
    public let columns: [GridTrack]
    public let cells: [GridCell]
    public let width: Double
    public let columnGap: Double
    public let rowGap: Double
    public let rtl: Bool

    public init(columns: [GridTrack], cells: [GridCell], width: Double, columnGap: Double = 0, rowGap: Double = 0, rtl: Bool = false) {
        self.columns = columns; self.cells = cells; self.width = width; self.columnGap = columnGap; self.rowGap = rowGap; self.rtl = rtl
    }

    public func body(context: ComponentContext) -> RenderElement {
        let placements = cells.map(\.placement)
        let resolved = GridLayoutSolver.resolve(columns: columns, items: placements, width: width, columnGap: columnGap, rowGap: rowGap, rtl: rtl)
        let byID = Dictionary(uniqueKeysWithValues: resolved.map { ($0.id, $0.frame) })
        let rows = Dictionary(grouping: cells, by: { $0.placement.row }).keys.sorted()
        let rowElements = rows.map { row in
            HStack(spacing: columnGap) {
                for cell in cells where cell.placement.row == row {
                    let frame = byID[cell.placement.id] ?? .zero
                    cell.content.frame(width: frame.width, height: frame.height).key(cell.placement.id)
                }
            }.render(in: context)
        }
        var element = VStack(alignment: .stretch, spacing: rowGap) {
            for row in rowElements { row }
        }.render(in: context)
        element.props.custom["gridColumns"] = String(columns.count)
        element.props.custom["gridCells"] = String(cells.count)
        element.props.custom["gridWidth"] = String(width)
        element.props.custom["gridRTL"] = rtl ? "true" : "false"
        return element
    }
}
