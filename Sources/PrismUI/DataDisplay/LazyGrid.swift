import Foundation
import PrismCore

/// Column configuration specification for grid layouts.
public enum GridColumns: Sendable, Equatable {
    case fixed(Int)
    case adaptive(minWidth: Double)
}

/// Keyed virtualized grid layout organizing large collections into responsive columns.
public struct LazyGrid<Data: RandomAccessCollection & Sendable, Content: ComponentConvertible>: Component {
    private let columns: GridColumns
    private let data: Data
    private let idKeyPath: KeyPath<Data.Element, String> & Sendable
    private let spacing: Double
    private let estimatedRowHeight: Double
    private let prefetchDistance: Int?
    private let prefetchAction: (@Sendable () -> Void)?
    private let contentBuilder: @Sendable (Data.Element) -> Content

    public init(
        columns: GridColumns,
        data: Data,
        id: KeyPath<Data.Element, String> & Sendable,
        spacing: Double = 8.0,
        estimatedRowHeight: Double = 100.0,
        @ComponentBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.columns = columns
        self.data = data
        self.idKeyPath = id
        self.spacing = spacing
        self.estimatedRowHeight = estimatedRowHeight
        self.prefetchDistance = nil
        self.prefetchAction = nil
        self.contentBuilder = content
    }

    private init(
        columns: GridColumns,
        data: Data,
        idKeyPath: KeyPath<Data.Element, String> & Sendable,
        spacing: Double,
        estimatedRowHeight: Double,
        prefetchDistance: Int?,
        prefetchAction: (@Sendable () -> Void)?,
        contentBuilder: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.columns = columns
        self.data = data
        self.idKeyPath = idKeyPath
        self.spacing = spacing
        self.estimatedRowHeight = estimatedRowHeight
        self.prefetchDistance = prefetchDistance
        self.prefetchAction = prefetchAction
        self.contentBuilder = contentBuilder
    }

    /// Attaches an automatic prefetch trigger when scrolling near the end of the grid.
    public func prefetch(distance: Int = 12, action: @escaping @Sendable () -> Void) -> LazyGrid {
        LazyGrid(
            columns: columns,
            data: data,
            idKeyPath: idKeyPath,
            spacing: spacing,
            estimatedRowHeight: estimatedRowHeight,
            prefetchDistance: distance,
            prefetchAction: action,
            contentBuilder: contentBuilder
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        let totalCount = data.count
        let colCount: Int
        switch columns {
        case .fixed(let count):
            colCount = max(1, count)
        case .adaptive(let minWidth):
            colCount = max(1, Int(floor(800.0 / max(1.0, minWidth))))
        }

        let totalRows = (totalCount + colCount - 1) / colCount

        let window = VirtualizationWindow.compute(
            totalCount: totalRows,
            viewportLength: 800.0,
            scrollOffset: 0.0,
            estimatedItemLength: estimatedRowHeight + spacing
        )

        // Check prefetch
        if let dist = prefetchDistance, totalCount > 0, totalRows > 0 {
            let thresholdRow = max(0, totalRows - (dist / colCount) - 1)
            if window.renderedRange.upperBound >= thresholdRow {
                prefetchAction?()
            }
        }

        let itemsArray = Array(data)
        var rowElements: [RenderElement] = []

        for rowIndex in window.renderedRange {
            let startIdx = rowIndex * colCount
            let endIdx = min(itemsArray.count, startIdx + colCount)
            guard startIdx < endIdx else { break }

            var rowCells: [RenderElement] = []
            for itemIdx in startIdx..<endIdx {
                let item = itemsArray[itemIdx]
                let key = item[keyPath: idKeyPath]
                let cells = contentBuilder(item).asRenderElements(in: context)

                for cell in cells {
                    var keyedCell = cell
                    keyedCell.id = ElementID(typeName: cell.id.typeName, key: key, siblingIndex: itemIdx)
                    rowCells.append(keyedCell)
                }
            }

            let rowElement = RenderElement(
                id: ElementID(typeName: "GridRow", siblingIndex: rowIndex),
                kind: .stack(axis: .horizontal, alignment: .start, spacing: spacing),
                props: ElementProps(),
                modifiers: [],
                children: rowCells
            )
            rowElements.append(rowElement)
        }

        var props = ElementProps()
        props.custom["totalItems"] = String(totalCount)
        props.custom["columns"] = String(colCount)
        props.custom["mountedRows"] = String(rowElements.count)

        return RenderElement(
            id: ElementID(typeName: "LazyGrid"),
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: spacing),
            props: props,
            modifiers: [],
            children: rowElements
        )
    }
}
