import Foundation

public struct GridAxisMetrics: Sendable, Equatable {
    public let count: Int; public let defaultExtent: Double; private var overrides: [Int: Double]
    public init(count: Int, defaultExtent: Double = 40) { self.count = max(0, count); self.defaultExtent = max(1, defaultExtent); self.overrides = [:] }
    public mutating func setExtent(_ extent: Double, at index: Int) { guard index >= 0, index < count, extent.isFinite, extent > 0 else { return }; overrides[index] = extent }
    public func extent(at index: Int) -> Double { overrides[index] ?? defaultExtent }
    public func offset(of index: Int) -> Double { (0..<min(max(index, 0), count)).reduce(0) { $0 + extent(at: $1) } }
    public func index(at offset: Double) -> Int { guard count > 0 else { return 0 }; var total = 0.0; for index in 0..<count { total += extent(at: index); if total > max(0, offset) { return index } }; return count - 1 }
}
public struct DataGridViewport: Sendable, Equatable {
    public let rows: Int; public let columns: Int; public private(set) var rowMetrics: GridAxisMetrics; public private(set) var columnMetrics: GridAxisMetrics
    public private(set) var mountedCells: [(row: Int, column: Int)]; public private(set) var scrollAnchor: (row: Int, column: Int)
    public init(rows: Int, columns: Int, rowExtent: Double = 32, columnExtent: Double = 120) { self.rows = max(0, rows); self.columns = max(0, columns); self.rowMetrics = GridAxisMetrics(count: rows, defaultExtent: rowExtent); self.columnMetrics = GridAxisMetrics(count: columns, defaultExtent: columnExtent); self.mountedCells = []; self.scrollAnchor = (0, 0) }
    public mutating func resizeRow(_ row: Int, extent: Double) { rowMetrics.setExtent(extent, at: row) }
    public mutating func resizeColumn(_ column: Int, extent: Double) { columnMetrics.setExtent(extent, at: column) }
    public mutating func updateViewport(offsetX: Double, offsetY: Double, width: Double, height: Double, overscan: Int = 1, pinnedRows: Int = 1, pinnedColumns: Int = 1) {
        guard rows > 0, columns > 0 else { mountedCells = []; return }; let firstRow = max(0, rowMetrics.index(at: offsetY) - overscan); let lastRow = min(rows - 1, rowMetrics.index(at: offsetY + height) + overscan); let firstCol = max(0, columnMetrics.index(at: offsetX) - overscan); let lastCol = min(columns - 1, columnMetrics.index(at: offsetX + width) + overscan)
        var cells: [(row: Int, column: Int)] = []; for row in firstRow...lastRow { for column in firstCol...lastCol { cells.append((row, column)) } }; for row in 0..<min(pinnedRows, rows) { for column in firstCol...lastCol where !cells.contains(where: { $0.row == row && $0.column == column }) { cells.append((row, column)) } }; for column in 0..<min(pinnedColumns, columns) { for row in firstRow...lastRow where !cells.contains(where: { $0.row == row && $0.column == column }) { cells.append((row, column)) } }; mountedCells = cells; scrollAnchor = (firstRow, firstCol)
    }
    public func accessibilityCoordinate(row: Int, column: Int) -> String { "row \(row + 1), column \(column + 1)" }
    public static func == (lhs: DataGridViewport, rhs: DataGridViewport) -> Bool {
        lhs.rows == rhs.rows && lhs.columns == rhs.columns && lhs.rowMetrics == rhs.rowMetrics && lhs.columnMetrics == rhs.columnMetrics && lhs.mountedCells.map { "\($0.row):\($0.column)" } == rhs.mountedCells.map { "\($0.row):\($0.column)" } && lhs.scrollAnchor.row == rhs.scrollAnchor.row && lhs.scrollAnchor.column == rhs.scrollAnchor.column
    }
}
