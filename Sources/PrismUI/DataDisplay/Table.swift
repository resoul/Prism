import Foundation
@_exported import PrismCore

/// Descriptor for a table column with title, optional explicit width, and content alignment.
public struct TableColumn: Equatable, Sendable {
    public let title: String
    public let width: Double?
    public let alignment: HorizontalAlignment

    public init(
        title: String,
        width: Double? = nil,
        alignment: HorizontalAlignment = .leading
    ) {
        self.title = title
        self.width = width
        self.alignment = alignment
    }
}

/// A single row within a `Table`.
public struct TableRow: Identifiable, Sendable {
    public let id: String
    public let cells: [String]

    public init(id: String = UUID().uuidString, cells: [String]) {
        self.id = id
        self.cells = cells
    }
}

/// Static multi-column tabular data presentation component.
///
/// Designed for in-memory datasets up to ~1,000 rows.
/// For massive virtualized datasets (10,000+ rows) with dynamic sorting and infinite scroll,
/// use `LazyList` or P3 `DataGrid`.
public struct Table: Component {
    public let columns: [TableColumn]
    public let rows: [TableRow]
    public let isStriped: Bool
    public let showBorders: Bool

    public init(
        columns: [TableColumn],
        rows: [TableRow],
        isStriped: Bool = true,
        showBorders: Bool = true
    ) {
        self.columns = columns
        self.rows = rows
        self.isStriped = isStriped
        self.showBorders = showBorders
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight

        return VStack(alignment: .stretch, spacing: 0) {
            // Header Row
            HStack(alignment: .center, spacing: 16) {
                for col in columns {
                    Text(col.title)
                        .font(.heading)
                        .foregroundColor(colors.mutedForeground)
                        .alignment(col.alignment)
                        .accessibilityElement(label: col.title, role: "columnheader")
                }
            }
            .padding(DirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .background(colors.secondary)
            .accessibilityElement(label: "Table Header", role: "row")

            Divider()

            // Data Rows
            VStack(alignment: .stretch, spacing: 0) {
                for (rowIndex, row) in rows.enumerated() {
                    let isEven = rowIndex % 2 == 0
                    let bg = (isStriped && !isEven) ? colors.secondary.opacity(0.5) : colors.background

                    HStack(alignment: .center, spacing: 16) {
                        for (colIndex, cellText) in row.cells.enumerated() {
                            let alignment = colIndex < columns.count ? columns[colIndex].alignment : .leading
                            Text(cellText)
                                .font(.body)
                                .foregroundColor(colors.foreground)
                                .alignment(alignment)
                                .accessibilityElement(label: cellText, role: "cell")
                        }
                    }
                    .padding(DirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(bg)
                    .accessibilityElement(label: "Row \(rowIndex + 1)", role: "row")

                    if showBorders && rowIndex < rows.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .background(colors.background)
        .sdfRoundedRect(
            cornerRadius: 8,
            borderWidth: showBorders ? 1 : 0,
            borderColor: colors.border,
            fill: colors.background
        )
        .accessibilityElement(label: "Table with \(columns.count) columns and \(rows.count) rows", role: "table")
        .render(in: context)
    }
}
