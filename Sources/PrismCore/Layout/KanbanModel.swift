import Foundation

public struct KanbanCard: Sendable, Equatable { public let id: String; public var columnID: String; public var title: String; public init(id: String, columnID: String, title: String) { self.id = id; self.columnID = columnID; self.title = title } }
public struct KanbanModel: Sendable, Equatable {
    public private(set) var columns: [String]; public private(set) var cards: [KanbanCard]; public private(set) var isMoving: Bool
    private var origin: [KanbanCard]?
    public init(columns: [String], cards: [KanbanCard] = []) { self.columns = columns; self.cards = cards.filter { columns.contains($0.columnID) }; self.isMoving = false }
    public func visibleCards(in column: String, offset: Int = 0, limit: Int = .max) -> [KanbanCard] { guard limit > 0 else { return [] }; let values = cards.filter { $0.columnID == column }; let start = min(max(offset, 0), values.count); return Array(values[start..<min(start + limit, values.count)]) }
    public mutating func beginMove(cardID: String) { guard cards.contains(where: { $0.id == cardID }) else { return }; origin = cards; isMoving = true }
    @discardableResult public mutating func move(cardID: String, toColumn column: String, index: Int) -> Bool { guard isMoving, columns.contains(column), let current = cards.firstIndex(where: { $0.id == cardID }) else { return false }; var card = cards.remove(at: current); card.columnID = column; let destination = cards.enumerated().filter { $0.element.columnID == column }.map(\.offset); let target = destination.indices.contains(index) ? destination[index] : (destination.last.map { $0 + 1 } ?? cards.count); cards.insert(card, at: min(target, cards.count)); return true }
    public mutating func applyDataUpdate(_ newCards: [KanbanCard]) { cards = newCards.filter { columns.contains($0.columnID) }; if let origin { self.origin = origin.filter { card in cards.contains(where: { $0.id == card.id }) } } }
    public mutating func commitMove() { origin = nil; isMoving = false }
    public mutating func cancelMove() { if let origin { cards = origin }; origin = nil; isMoving = false }
}
