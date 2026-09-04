import XCTest
@testable import PrismCore
import CoreText

final class TypographyAndFontResolverTests: XCTestCase {

    func testTypeScaleCalculations() {
        let typography = Typography(baseSize: 16, scale: .majorThird) // ratio 1.25

        // body is step 0: base size 16
        XCTAssertEqual(typography.fontSize(for: .body), 16.0)

        // subheading is step 2: 16 * 1.25^2 = 25.0
        XCTAssertEqual(typography.fontSize(for: .subheading), 25.0)

        // caption is step -2: 16 * 1.25^-2 = 10.24 -> rounded to 10.0
        XCTAssertEqual(typography.fontSize(for: .caption), 10.0)

        // heading1 is step 6: 16 * 1.25^6 = 61.035 -> rounded to 61.0
        XCTAssertEqual(typography.fontSize(for: .heading1), 61.0)
    }

    func testCustomScaleMap() {
        let customMap: [TextStyle: CGFloat] = [
            .caption: 11,
            .body: 15,
            .heading1: 34
        ]
        let typography = Typography(baseSize: 15, scale: .customMap(customMap))

        XCTAssertEqual(typography.fontSize(for: .caption), 11.0)
        XCTAssertEqual(typography.fontSize(for: .body), 15.0)
        XCTAssertEqual(typography.fontSize(for: .heading1), 34.0)
    }

    func testCacheKeyEqualityAndHashing() {
        let key1 = FontCacheKey(family: "Inter", weight: .bold, size: 16, italic: false, tracking: 0)
        let key2 = FontCacheKey(family: "Inter", weight: .bold, size: 16, italic: false, tracking: 0)
        let key3 = FontCacheKey(family: "Inter", weight: .regular, size: 16, italic: false, tracking: 0)

        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1.hashValue, key2.hashValue)
        XCTAssertNotEqual(key1, key3)
    }

    func testResolverIdenticalQueryReturnsCachedFont() {
        let resolver = FontResolver()
        let font1 = resolver.resolve(family: "Helvetica", weight: .regular, size: 14)
        let font2 = resolver.resolve(family: "Helvetica", weight: .regular, size: 14)

        XCTAssertTrue(font1 === font2, "Identical query should return identical CTFont instance from cache")
        XCTAssertEqual(resolver.cachedCount, 1)
    }

    func testResolverDifferentRoleAndSizeYieldDifferentMetrics() {
        let resolver = FontResolver()
        let smallFont = resolver.resolve(family: "Helvetica", weight: .regular, size: 12)
        let largeFont = resolver.resolve(family: "Helvetica", weight: .bold, size: 36)

        let smallAscent = CTFontGetAscent(smallFont)
        let largeAscent = CTFontGetAscent(largeFont)

        let smallCapHeight = CTFontGetCapHeight(smallFont)
        let largeCapHeight = CTFontGetCapHeight(largeFont)

        XCTAssertGreaterThan(largeAscent, smallAscent)
        XCTAssertGreaterThan(largeCapHeight, smallCapHeight)
    }

    func testResolverSystemFallbackForMissingFamily() {
        let resolver = FontResolver()
        // Non-existent family name
        let fallbackFont = resolver.resolve(family: "DefinitelyNonExistentFontFamily12345", weight: .semibold, size: 18)

        XCTAssertNotNil(fallbackFont)
        XCTAssertEqual(CTFontGetSize(fallbackFont), 18.0)
    }
}
