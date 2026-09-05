import XCTest
@testable import PrismUI

final class DateSelectorTests: XCTestCase {
    func testBoundsKeyboardNavigationAndSelection() {
        var value = Date(timeIntervalSince1970: 1_700_000_000)
        let binding = Binding(get: { value }, set: { value = $0 })
        let calendar = CalendarService(timeZone: TimeZone(secondsFromGMT: 0)!)
        let min = calendar.startOfDay(for: value)
        var selector = DateSelector("Date", selection: binding, calendar: calendar, minimumDate: min)
        XCTAssertFalse(selector.select(calendar.adding(.day, value: -1, to: value)!))
        selector.present(); selector.moveDay(by: 1)
        XCTAssertTrue(selector.select(selector.focusedDate)); XCTAssertFalse(selector.isPresented)
    }

    func testInvalidDateAndCancelRestoreSelection() {
        var value = Date(timeIntervalSince1970: 1_700_000_000)
        let binding = Binding(get: { value }, set: { value = $0 })
        var selector = DateSelector(selection: binding, maximumDate: value)
        selector.present(); selector.moveDay(by: 1); selector.cancel()
        XCTAssertEqual(selector.focusedDate, value); XCTAssertFalse(selector.isPresented)
        XCTAssertFalse(selector.select(value.addingTimeInterval(86_400)))
    }
}
