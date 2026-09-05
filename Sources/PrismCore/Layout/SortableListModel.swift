import Foundation

public struct SortableListModel<ID: Hashable & Sendable>: Sendable, Equatable {
    public private(set) var ids: [ID]
    public private(set) var isReordering: Bool
    private var origin: [ID]?
    public init(ids: [ID]) { self.ids = ids; self.isReordering = false }
    public mutating func begin(id: ID) { guard ids.contains(id) else { return }; origin = ids; isReordering = true }
    @discardableResult public mutating func move(id: ID, to index: Int) -> Bool {
        guard isReordering, let current = ids.firstIndex(of: id) else { return false }
        ids.remove(at: current); ids.insert(id, at: min(max(index, 0), ids.count)); return true
    }
    public mutating func keyboardMove(id: ID, by offset: Int) { guard let index = ids.firstIndex(of: id) else { return }; _ = move(id: id, to: index + offset) }
    public mutating func applyDataUpdate(_ newIDs: [ID]) { ids = newIDs; if let origin { self.origin = origin.filter { newIDs.contains($0) } } }
    public mutating func commit() { origin = nil; isReordering = false }
    public mutating func cancel() { if let origin { ids = origin }; self.origin = nil; isReordering = false }
    public func visibleIDs(offset: Int, limit: Int) -> [ID] { guard limit > 0 else { return [] }; let start = min(max(offset, 0), ids.count); return Array(ids[start..<min(start + limit, ids.count)]) }
}
