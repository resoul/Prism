import Foundation

public struct CalendarEvent: Sendable, Equatable, Identifiable { public let id: String; public let title: String; public var start: Date; public var end: Date; public let isAllDay: Bool; public init(id: String, title: String, start: Date, end: Date, isAllDay: Bool = false) { self.id = id; self.title = title; self.start = start; self.end = max(end, start); self.isAllDay = isAllDay } }
public struct EventLayoutFrame: Sendable, Equatable { public let eventID: String; public let column: Int; public let columnCount: Int; public init(eventID: String, column: Int, columnCount: Int) { self.eventID = eventID; self.column = column; self.columnCount = columnCount } }
public struct EventCalendarModel: Sendable, Equatable {
    public private(set) var events: [String: CalendarEvent]
    public init(events: [CalendarEvent] = []) { self.events = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) }) }
    public mutating func upsert(_ event: CalendarEvent) { events[event.id] = event }
    public mutating func remove(id: String) { events[id] = nil }
    public func layout(viewport: DateInterval? = nil) -> [EventLayoutFrame] {
        let timed = events.values.filter { !$0.isAllDay && (viewport == nil || viewport!.intersects(DateInterval(start: $0.start, end: $0.end))) }.sorted { $0.start < $1.start }
        var frames: [EventLayoutFrame] = []; var columns: [Date] = []
        for event in timed { if let index = columns.firstIndex(where: { $0 <= event.start }) { columns[index] = event.end; frames.append(EventLayoutFrame(eventID: event.id, column: index, columnCount: max(columns.count, 1))) } else { columns.append(event.end); frames.append(EventLayoutFrame(eventID: event.id, column: columns.count - 1, columnCount: columns.count)) } }
        return frames.map { frame in let count = frames.filter { $0.column == frame.column || (events[$0.eventID]!.start < events[frame.eventID]!.end && events[$0.eventID]!.end > events[frame.eventID]!.start) }.map(\.column).max().map { $0 + 1 } ?? 1; return EventLayoutFrame(eventID: frame.eventID, column: frame.column, columnCount: max(frame.columnCount, count)) }
    }
    @discardableResult public mutating func reschedule(id: String, start: Date, end: Date, cancelled: Bool = false) -> Bool { guard !cancelled, var event = events[id], end >= start else { return false }; event.start = start; event.end = end; events[id] = event; return true }
}
