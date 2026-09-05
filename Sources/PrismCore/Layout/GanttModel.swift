import Foundation

public struct GanttTask: Sendable, Equatable, Identifiable { public let id: String; public let title: String; public var start: Date; public var end: Date; public init(id: String, title: String, start: Date, end: Date) { self.id = id; self.title = title; self.start = start; self.end = max(end, start) } }
public enum GanttError: Error, Sendable, Equatable { case dependencyCycle, unknownTask }
public struct GanttModel: Sendable, Equatable {
    public private(set) var tasks: [String: GanttTask]; public private(set) var dependencies: [String: Set<String>]; public private(set) var zoom: Double; private var origin: GanttTask?
    public init(tasks: [GanttTask] = [], dependencies: [String: Set<String>] = [:], zoom: Double = 1) { self.tasks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) }); self.dependencies = dependencies; self.zoom = min(max(zoom, 0.25), 4) }
    public mutating func setZoom(_ value: Double) { guard value.isFinite else { return }; zoom = min(max(value, 0.25), 4) }
    public func validateDependencies() throws { var visiting = Set<String>(); var visited = Set<String>(); func visit(_ id: String) throws { if visiting.contains(id) { throw GanttError.dependencyCycle }; guard !visited.contains(id) else { return }; guard tasks[id] != nil else { throw GanttError.unknownTask }; visiting.insert(id); for dep in dependencies[id] ?? [] { try visit(dep) }; visiting.remove(id); visited.insert(id) }; for id in tasks.keys { try visit(id) }; for id in dependencies.keys where tasks[id] == nil { throw GanttError.unknownTask } }
    public func visibleTasks(in interval: DateInterval? = nil, offset: Int = 0, limit: Int = .max) -> [GanttTask] { guard limit > 0 else { return [] }; let values = tasks.values.filter { interval == nil || interval!.intersects(DateInterval(start: $0.start, end: $0.end)) }.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }; let start = min(max(offset, 0), values.count); let end = limit == .max ? values.count : min(start + limit, values.count); return Array(values[start..<end]) }
    public mutating func beginReschedule(id: String) { origin = tasks[id] }
    @discardableResult public mutating func reschedule(id: String, start: Date, end: Date, cancelled: Bool = false) -> Bool { guard !cancelled, var task = tasks[id], end >= start else { return false }; task.start = start; task.end = end; tasks[id] = task; return true }
    public mutating func cancelReschedule() { if let origin { tasks[origin.id] = origin }; origin = nil }
    public mutating func commitReschedule() { origin = nil }
    public func accessibilityTable() -> [[String]] { [["task", "start", "end"]] + tasks.values.sorted { $0.start < $1.start }.map { [$0.title, ISO8601DateFormatter().string(from: $0.start), ISO8601DateFormatter().string(from: $0.end)] } }
}
