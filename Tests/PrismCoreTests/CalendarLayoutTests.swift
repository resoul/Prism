import XCTest
@testable import PrismCore

final class CalendarLayoutTests: XCTestCase {
    func testMonthBoundaryAndSelectedDate() throws { let service = CalendarService(timeZone: TimeZone(secondsFromGMT: 0)!); let date = try service.date(from: DateComponents(year: 2024, month: 2, day: 15)); let layout = CalendarLayout(mode: .month, referenceDate: date, selectedDate: date, service: service); XCTAssertEqual(layout.cells.filter(\.isInDisplayedMonth).count, 29); XCTAssertEqual(layout.cells.filter(\.isSelected).count, 1) }
    func testWeekDayAndRTLMetadata() throws { let service = CalendarService(locale: Locale(identifier: "ar"), timeZone: TimeZone(secondsFromGMT: 0)!); let date = try service.date(from: DateComponents(year: 2024, month: 3, day: 10)); let week = CalendarLayout(mode: .week, referenceDate: date, service: service, isRTL: true); XCTAssertEqual(week.cells.count, 7); XCTAssertEqual(week.weekdaySymbols.count, 7); let day = CalendarLayout(mode: .day, referenceDate: date, service: service); XCTAssertEqual(day.cells.count, 1) }
}
