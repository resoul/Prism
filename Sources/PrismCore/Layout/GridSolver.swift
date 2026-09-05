import Foundation

public enum GridTrack: Sendable, Equatable {
    case fixed(Double)
    case fraction(Double)
    case minmax(min: Double, max: Double)
}

public struct GridPlacement: Sendable, Equatable {
    public let id: String
    public let column: Int
    public let row: Int
    public let columnSpan: Int
    public let rowSpan: Int
    public let intrinsicHeight: Double

    public init(id: String, column: Int, row: Int, columnSpan: Int = 1, rowSpan: Int = 1, intrinsicHeight: Double = 44) {
        self.id = id; self.column = max(0, column); self.row = max(0, row)
        self.columnSpan = max(1, columnSpan); self.rowSpan = max(1, rowSpan)
        self.intrinsicHeight = intrinsicHeight.isFinite ? max(0, intrinsicHeight) : 0
    }
}

public struct GridResolvedItem: Sendable, Equatable {
    public let id: String
    public let frame: LayoutFrame
    public init(id: String, frame: LayoutFrame) { self.id = id; self.frame = frame }
}

public enum GridLayoutSolver {
    public static func resolve(columns: [GridTrack], items: [GridPlacement], width: Double, columnGap: Double = 0, rowGap: Double = 0, rtl: Bool = false) -> [GridResolvedItem] {
        guard !columns.isEmpty, width.isFinite, width >= 0 else { return [] }
        let gap = max(0, columnGap)
        let available = max(0, width - gap * Double(max(0, columns.count - 1)))
        var sizes = columns.map { track -> Double in
            switch track { case .fixed(let v): return max(0, v); case .fraction: return 0; case .minmax(let min, _): return max(0, min) }
        }
        let fixed = sizes.reduce(0, +)
        let fractions = columns.enumerated().reduce(0.0) { partial, pair in partial + ifCaseFraction(pair.element) }
        let remainder = max(0, available - fixed)
        for index in columns.indices {
            switch columns[index] {
            case .fraction(let value): sizes[index] = fractions > 0 ? remainder * max(0, value) / fractions : 0
            case .minmax(let minValue, let maxValue): sizes[index] = Swift.min(Swift.max(0, maxValue), Swift.max(Swift.max(0, minValue), sizes[index]))
            case .fixed: break
            }
        }
        var origins = [Double](repeating: 0, count: sizes.count)
        for i in 1..<sizes.count { origins[i] = origins[i - 1] + sizes[i - 1] + gap }
        let rowHeight = items.map(\.intrinsicHeight).max() ?? 0
        return items.map { item in
            let start = min(item.column, sizes.count - 1)
            let end = min(sizes.count, start + item.columnSpan)
            let x = origins[start]
            let w = sizes[start..<end].reduce(0, +) + gap * Double(max(0, end - start - 1))
            let mirroredX = rtl ? width - x - w : x
            return GridResolvedItem(id: item.id, frame: LayoutFrame(x: mirroredX, y: Double(item.row) * (rowHeight + max(0, rowGap)), width: w, height: rowHeight * Double(item.rowSpan) + max(0, rowGap) * Double(max(0, item.rowSpan - 1))))
        }
    }

    private static func ifCaseFraction(_ track: GridTrack) -> Double {
        if case .fraction(let value) = track { return max(0, value) }; return 0
    }
}
