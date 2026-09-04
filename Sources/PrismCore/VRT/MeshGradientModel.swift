import Foundation

/// A single control point in a 2D mesh gradient.
public struct MeshGradientPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var color: Color

    public init(x: Double, y: Double, color: Color) {
        self.x = max(0.0, min(1.0, x))
        self.y = max(0.0, min(1.0, y))
        self.color = color
    }
}

/// A structured 2D grid of control points for multi-color mesh gradient rendering.
public struct MeshGradientGrid: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let points: [MeshGradientPoint]

    public init(width: Int, height: Int, points: [MeshGradientPoint]) {
        self.width = max(2, width)
        self.height = max(2, height)
        let expectedCount = self.width * self.height
        if points.count == expectedCount {
            self.points = points
        } else if points.count < expectedCount {
            // Pad with transparent or fallback points
            var filled = points
            while filled.count < expectedCount {
                let idx = filled.count
                let col = Double(idx % self.width) / Double(max(1, self.width - 1))
                let row = Double(idx / self.width) / Double(max(1, self.height - 1))
                filled.append(MeshGradientPoint(x: col, y: row, color: .clear))
            }
            self.points = filled
        } else {
            self.points = Array(points.prefix(expectedCount))
        }
    }

    /// Point subscript at grid coordinate (col, row).
    public subscript(column: Int, row: Int) -> MeshGradientPoint {
        let clampedCol = max(0, min(width - 1, column))
        let clampedRow = max(0, min(height - 1, row))
        return points[clampedRow * width + clampedCol]
    }
}
