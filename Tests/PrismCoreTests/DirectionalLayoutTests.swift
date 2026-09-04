import XCTest
@testable import PrismCore

final class DirectionalLayoutTests: XCTestCase {

    func testDirectionalInsetsResolutionLTR() {
        let insets = DirectionalEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let resolved = insets.resolved(for: .leftToRight)

        XCTAssertEqual(resolved.top, 10)
        XCTAssertEqual(resolved.left, 20, "In LTR, leading maps to left")
        XCTAssertEqual(resolved.bottom, 30)
        XCTAssertEqual(resolved.right, 40, "In LTR, trailing maps to right")
    }

    func testDirectionalInsetsResolutionRTL() {
        let insets = DirectionalEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let resolved = insets.resolved(for: .rightToLeft)

        XCTAssertEqual(resolved.top, 10)
        XCTAssertEqual(resolved.left, 40, "In RTL, trailing maps to left")
        XCTAssertEqual(resolved.bottom, 30)
        XCTAssertEqual(resolved.right, 20, "In RTL, leading maps to right")
    }

    func testHorizontalAlignmentResolution() {
        XCTAssertEqual(HorizontalAlignment.leading.absolute(for: .leftToRight), .left)
        XCTAssertEqual(HorizontalAlignment.leading.absolute(for: .rightToLeft), .right)

        XCTAssertEqual(HorizontalAlignment.trailing.absolute(for: .leftToRight), .right)
        XCTAssertEqual(HorizontalAlignment.trailing.absolute(for: .rightToLeft), .left)

        XCTAssertEqual(HorizontalAlignment.center.absolute(for: .leftToRight), .center)
        XCTAssertEqual(HorizontalAlignment.center.absolute(for: .rightToLeft), .center)
    }

    func testNaturalReadingDirectionFromLocale() {
        let arabic = Locale(identifier: "ar_SA")
        let hebrew = Locale(identifier: "he_IL")
        let english = Locale(identifier: "en_US")
        let japanese = Locale(identifier: "ja_JP")

        XCTAssertEqual(LayoutDirection.natural(for: arabic), .rightToLeft)
        XCTAssertEqual(LayoutDirection.natural(for: hebrew), .rightToLeft)
        XCTAssertEqual(LayoutDirection.natural(for: english), .leftToRight)
        XCTAssertEqual(LayoutDirection.natural(for: japanese), .leftToRight)
    }

    func testLocalizationEnvironmentForks() {
        let env = LocalizationEnvironment(
            locale: Locale(identifier: "en_US"),
            contentSizeCategory: .large
        )
        XCTAssertEqual(env.layoutDirection, .leftToRight)

        let arabicEnv = env.withLocale(Locale(identifier: "ar_EG"))
        XCTAssertEqual(arabicEnv.layoutDirection, .rightToLeft)

        let insets = DirectionalEdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 25)
        let arabicInsets = arabicEnv.resolveInsets(insets)
        XCTAssertEqual(arabicInsets.left, 25)
        XCTAssertEqual(arabicInsets.right, 15)

        let scaledEnv = env.withContentSizeCategory(.accessibilityLarge)
        XCTAssertEqual(scaledEnv.contentSizeCategory, .accessibilityLarge)
    }
}
