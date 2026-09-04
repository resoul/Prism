import XCTest
@testable import PrismCore

final class DynamicTypeScalingTests: XCTestCase {

    func testCategoryScaleFactorsAndOrdering() {
        XCTAssertEqual(ContentSizeCategory.large.scaleFactor, 1.0)
        XCTAssertLessThan(ContentSizeCategory.small.scaleFactor, 1.0)
        XCTAssertGreaterThan(ContentSizeCategory.extraLarge.scaleFactor, 1.0)

        XCTAssertTrue(ContentSizeCategory.small < ContentSizeCategory.large)
        XCTAssertTrue(ContentSizeCategory.large < ContentSizeCategory.extraExtraExtraLarge)
        XCTAssertTrue(ContentSizeCategory.extraExtraExtraLarge < ContentSizeCategory.accessibilityLarge)

        XCTAssertFalse(ContentSizeCategory.large.isAccessibilityCategory)
        XCTAssertTrue(ContentSizeCategory.accessibilityMedium.isAccessibilityCategory)
    }

    func testTypographyDynamicTypeScaling() {
        let typography = Typography(baseSize: 16, scale: .majorThird)

        let baselineSize = typography.fontSize(for: .body, contentSizeCategory: .large)
        XCTAssertEqual(baselineSize, 16.0)

        let smallSize = typography.fontSize(for: .body, contentSizeCategory: .small)
        XCTAssertEqual(smallSize, 14.0) // 16 * 0.88 = 14.08 -> 14.0

        let xxxlSize = typography.fontSize(for: .body, contentSizeCategory: .extraExtraExtraLarge)
        XCTAssertEqual(xxxlSize, 22.0) // 16 * 1.36 = 21.76 -> 22.0

        let axLargeSize = typography.fontSize(for: .body, contentSizeCategory: .accessibilityLarge)
        XCTAssertEqual(axLargeSize, 31.0) // 16 * 1.95 = 31.2 -> 31.0
    }

    func testDynamicTypeClamping() {
        let typography = Typography(baseSize: 16, scale: .majorThird)

        // Restrict scaling between 0.9 and 1.5
        let clampedConfig = DynamicTypeConfig(minScale: 0.9, maxScale: 1.5)

        let extraSmallSize = typography.fontSize(
            for: .body,
            contentSizeCategory: .extraSmall, // normally 0.82
            dynamicTypeConfig: clampedConfig
        )
        // 16 * 0.9 = 14.4 -> 14.5
        XCTAssertEqual(extraSmallSize, 14.5)

        let giantSize = typography.fontSize(
            for: .body,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge, // normally 3.4
            dynamicTypeConfig: clampedConfig
        )
        // 16 * 1.5 = 24.0
        XCTAssertEqual(giantSize, 24.0)
    }

    func testScaledLineHeight() {
        let typography = Typography(baseSize: 16)
        let bodyLHNormal = typography.scaledLineHeight(for: .body, contentSizeCategory: .large)
        let bodyLHLarge = typography.scaledLineHeight(for: .body, contentSizeCategory: .extraExtraLarge)

        XCTAssertGreaterThan(bodyLHLarge, bodyLHNormal)
    }
}
