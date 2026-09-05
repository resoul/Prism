import XCTest
@testable import PrismCore

final class CalendarServiceTests: XCTestCase {
    func testFixedClockAndLeapDay() throws {
        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        let service = CalendarService(timeZone: TimeZone(secondsFromGMT: 0)!, clock: FixedPrismClock(now: instant))
        XCTAssertEqual(service.now, instant)
        let date = try service.date(from: DateComponents(year: 2024, month: 2, day: 29))
        XCTAssertEqual(service.components([.year, .month, .day], from: date).day, 29)
    }

    func testDSTGapAndFold() throws {
        let zone = TimeZone(identifier: "America/New_York")!
        let service = CalendarService(timeZone: zone)
        XCTAssertThrowsError(try service.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 2, minute: 30))) { error in
            XCTAssertEqual(error as? CalendarServiceError, .nonexistentLocalTime)
        }
        let fold = try service.resolve(DateComponents(year: 2024, month: 11, day: 3, hour: 1, minute: 30), repeatedTimePolicy: .last)
        XCTAssertEqual(service.components([.hour], from: fold).hour, 1)
    }

    func testNonGregorianCalendarAndArithmetic() throws {
        let service = CalendarService(calendarIdentifier: .islamicCivil, locale: Locale(identifier: "ar"), timeZone: TimeZone(secondsFromGMT: 0)!)
        let date = try service.date(from: DateComponents(year: 1445, month: 9, day: 1))
        XCTAssertEqual(service.components([.year, .month, .day], from: date).month, 9)
        XCTAssertNotNil(service.adding(.day, value: 1, to: date))
    }
}
