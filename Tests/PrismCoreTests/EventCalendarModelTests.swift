import XCTest
@testable import PrismCore

final class EventCalendarModelTests: XCTestCase {
    func testOverlapLayoutAndAllDaySeparation() { let base = Date(timeIntervalSince1970: 1_700_000_000); var model = EventCalendarModel(events: [CalendarEvent(id: "a", title: "A", start: base, end: base.addingTimeInterval(3600)), CalendarEvent(id: "b", title: "B", start: base.addingTimeInterval(1800), end: base.addingTimeInterval(5400)), CalendarEvent(id: "all", title: "All", start: base, end: base, isAllDay: true)]); let frames = model.layout(); XCTAssertEqual(frames.count, 2); XCTAssertGreaterThan(Set(frames.map(\.column)).count, 1); XCTAssertTrue(model.events["all"]!.isAllDay) }
    func testRescheduleCancellationAndRemoval() { let date = Date(); var model = EventCalendarModel(events: [CalendarEvent(id: "e", title: "Event", start: date, end: date.addingTimeInterval(60))]); XCTAssertFalse(model.reschedule(id: "e", start: date, end: date, cancelled: true)); XCTAssertTrue(model.reschedule(id: "e", start: date.addingTimeInterval(120), end: date.addingTimeInterval(180))); model.remove(id: "e"); XCTAssertNil(model.events["e"]) }
}
