import Foundation

public enum ChartKind: String, Sendable { case line, bar, pie }
public struct ChartPoint: Sendable, Equatable { public let x: Double; public let y: Double; public init(x: Double, y: Double) { self.x = x; self.y = y } }
public struct ChartSeries: Sendable, Equatable { public let id: String; public let label: String; public let points: [ChartPoint]; public init(id: String, label: String, points: [ChartPoint]) { self.id = id; self.label = label; self.points = points } }
public struct ChartModel: Sendable, Equatable {
    public let kind: ChartKind; public let series: [ChartSeries]
    public init(kind: ChartKind, series: [ChartSeries]) { self.kind = kind; self.series = series }
    public func normalized() -> ChartModel { ChartModel(kind: kind, series: series.map { ChartSeries(id: $0.id, label: $0.label, points: $0.points.filter { $0.x.isFinite && $0.y.isFinite }) }) }
    public func decimated(maxPoints: Int) -> ChartModel { guard maxPoints > 1 else { return ChartModel(kind: kind, series: series.map { ChartSeries(id: $0.id, label: $0.label, points: Array($0.points.prefix(maxPoints))) }) }; return ChartModel(kind: kind, series: normalized().series.map { s in guard s.points.count > maxPoints else { return s }; let stride = Double(s.points.count - 1) / Double(maxPoints - 1); return ChartSeries(id: s.id, label: s.label, points: (0..<maxPoints).map { s.points[Int((Double($0) * stride).rounded())] }) }) }
    public func hitTest(x: Double, y: Double, tolerance: Double = .infinity) -> ChartPoint? { normalized().series.flatMap(\.points).min { hypot($0.x - x, $0.y - y) < hypot($1.x - x, $1.y - y) }.flatMap { hypot($0.x - x, $0.y - y) <= tolerance ? $0 : nil } }
    public func accessibilityTable() -> [[String]] { [["series", "x", "y"]] + series.flatMap { s in s.points.map { [s.label, String($0.x), String($0.y)] } } }
    public func csv() -> String { accessibilityTable().map { $0.joined(separator: ",") }.joined(separator: "\n") }
}
