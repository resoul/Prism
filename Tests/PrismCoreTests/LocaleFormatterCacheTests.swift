import XCTest
@testable import PrismCore

final class LocaleFormatterCacheTests: XCTestCase {

    func testDateFormatterCaching() {
        let cache = LocaleFormatterCache()
        let locale = Locale(identifier: "en_US")
        let timeZone = TimeZone(identifier: "UTC")!

        let formatter1 = cache.dateFormatter(
            locale: locale,
            dateStyle: .short,
            timeStyle: .short,
            timeZone: timeZone
        )

        let formatter2 = cache.dateFormatter(
            locale: locale,
            dateStyle: .short,
            timeStyle: .short,
            timeZone: timeZone
        )

        XCTAssertTrue(formatter1 === formatter2, "Identical request should return identical DateFormatter instance from cache")
    }

    func testNumberFormatterCaching() {
        let cache = LocaleFormatterCache()
        let locale = Locale(identifier: "fr_FR")

        let formatter1 = cache.numberFormatter(locale: locale, style: .currency, currencyCode: "EUR")
        let formatter2 = cache.numberFormatter(locale: locale, style: .currency, currencyCode: "EUR")

        XCTAssertTrue(formatter1 === formatter2, "Identical request should return identical NumberFormatter instance from cache")
    }

    func testFormattedOutputsAcrossLocales() {
        let cache = LocaleFormatterCache()
        let date = Date(timeIntervalSince1970: 1700000000) // 2023-11-14 22:13:20 UTC
        let timeZone = TimeZone(identifier: "UTC")!

        let enString = cache.string(
            from: date,
            locale: Locale(identifier: "en_US"),
            dateStyle: .short,
            timeStyle: .none,
            timeZone: timeZone
        )

        let deString = cache.string(
            from: date,
            locale: Locale(identifier: "de_DE"),
            dateStyle: .short,
            timeStyle: .none,
            timeZone: timeZone
        )

        XCTAssertFalse(enString.isEmpty)
        XCTAssertFalse(deString.isEmpty)
        XCTAssertNotEqual(enString, deString, "Formatters should produce different localized date formats")

        let price = NSNumber(value: 49.99)
        let usd = cache.formatCurrency(price, currencyCode: "USD", locale: Locale(identifier: "en_US"))
        let eur = cache.formatCurrency(price, currencyCode: "EUR", locale: Locale(identifier: "de_DE"))

        XCTAssertTrue(usd.contains("$") || usd.contains("USD"))
        XCTAssertTrue(eur.contains("€") || eur.contains("EUR"))
    }

    func testConcurrentAccessThreadSafety() {
        let cache = LocaleFormatterCache()
        let expectation = expectation(description: "Concurrent cache access")
        expectation.expectedFulfillmentCount = 20

        for i in 0..<20 {
            DispatchQueue.global().async {
                let locale = Locale(identifier: i % 2 == 0 ? "en_US" : "fr_FR")
                _ = cache.dateFormatter(locale: locale, dateStyle: .medium, timeStyle: .none)
                _ = cache.numberFormatter(locale: locale, style: .decimal)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
        XCTAssertGreaterThan(cache.cachedCount, 0)
    }
}
