import XCTest
@testable import PrismCore

final class TextMeasurementTests: XCTestCase {
    // MARK: - 1. Empty String

    func testEmptyStringReturnsZeroSize() {
        let policy = TextMeasurePolicy(text: "")
        let size = policy.measure(style: .default, constraint: .unconstrained)
        XCTAssertEqual(size.width, 0)
        XCTAssertEqual(size.height, 0)
    }

    // MARK: - 2. Single Line Text

    func testSingleLineTextReturnsValidDimensions() {
        let policy = TextMeasurePolicy(text: "Hello Prism", fontSize: 16)
        let size = policy.measure(style: .default, constraint: .unconstrained)

        XCTAssertTrue(size.width > 0)
        XCTAssertTrue(size.height > 0)
        XCTAssertTrue(size.width.isFinite)
        XCTAssertTrue(size.height.isFinite)
    }

    // MARK: - 3. Multi-line Wrapping

    func testMultiLineTextWrapsAndIncreasesHeight() {
        let longText = "This is a long sentence meant to demonstrate CoreText line wrapping under constrained width boundaries in Prism."
        let policy = TextMeasurePolicy(text: longText, fontSize: 16)

        // Measure unconstrained (single wide line)
        let unconstrainedSize = policy.measure(style: .default, constraint: .unconstrained)

        // Measure constrained to 120pt width (multiple lines)
        let constrainedSize = policy.measure(style: .default, constraint: .atMost(width: 120))

        XCTAssertTrue(constrainedSize.width <= 120)
        XCTAssertTrue(constrainedSize.height > unconstrainedSize.height)
    }

    // MARK: - 4. Line Limit

    func testLineLimitCapsMultiLineHeight() {
        let longText = "Line one\nLine two\nLine three\nLine four\nLine five"
        let unlimitedPolicy = TextMeasurePolicy(text: longText, fontSize: 16, lineLimit: nil)
        let limitedPolicy = TextMeasurePolicy(text: longText, fontSize: 16, lineLimit: 2)

        let unlimitedSize = unlimitedPolicy.measure(style: .default, constraint: .unconstrained)
        let limitedSize = limitedPolicy.measure(style: .default, constraint: .unconstrained)

        XCTAssertTrue(limitedSize.height < unlimitedSize.height)
    }

    // MARK: - 5. Custom Line Height

    func testCustomLineHeightIncreasesHeight() {
        let text = "Line 1\nLine 2"
        let normalPolicy = TextMeasurePolicy(text: text, fontSize: 16, customLineHeight: nil)
        let customPolicy = TextMeasurePolicy(text: text, fontSize: 16, customLineHeight: 32)

        let normalSize = normalPolicy.measure(style: .default, constraint: .unconstrained)
        let customSize = customPolicy.measure(style: .default, constraint: .unconstrained)

        XCTAssertTrue(customSize.height > normalSize.height)
    }

    // MARK: - 6. Emoji & Unicode Metrics

    func testEmojiAndMultilingualUnicodeMeasurement() {
        let unicodeStrings = [
            "🚀 🌍 🎉 💡 🔥",
            "Привет, мир! Тестирование CoreText.",
            "مرحبا بك في بريزم",
            "こんにちは世界！Prismレイアウトエンジン",
            "Hello 👩‍💻👨‍👩‍👧‍👦 Family Emoji"
        ]

        for text in unicodeStrings {
            let policy = TextMeasurePolicy(text: text, fontSize: 18)
            let size = policy.measure(style: .default, constraint: .unconstrained)

            XCTAssertTrue(size.width > 0, "Width should be positive for text: \(text)")
            XCTAssertTrue(size.height > 0, "Height should be positive for text: \(text)")
            XCTAssertTrue(size.width.isFinite)
            XCTAssertTrue(size.height.isFinite)
        }
    }
}
