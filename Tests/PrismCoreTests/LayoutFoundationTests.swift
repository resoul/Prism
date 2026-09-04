import XCTest
@testable import PrismCore

final class LayoutFoundationTests: XCTestCase {
    // MARK: - 1. SizeValue Resolution Matrix

    func testFixedSizeResolutionAcrossConstraints() {
        let fixedStyle = SizeValue.fixed(120)

        // Unspecified space: respects fixed value
        let unspec = ConstraintResolver.resolve(sizeValue: fixedStyle, constraint: .unspecified)
        XCTAssertEqual(unspec, 120)

        // AtMost space larger: respects fixed value
        let atMostLarge = ConstraintResolver.resolve(sizeValue: fixedStyle, constraint: .atMost(300))
        XCTAssertEqual(atMostLarge, 120)

        // AtMost space smaller: clamped to available
        let atMostSmall = ConstraintResolver.resolve(sizeValue: fixedStyle, constraint: .atMost(80))
        XCTAssertEqual(atMostSmall, 80)

        // Exactly space
        let exactly = ConstraintResolver.resolve(sizeValue: fixedStyle, constraint: .exactly(200))
        XCTAssertEqual(exactly, 120)
    }

    func testFractionSizeResolutionAcrossConstraints() {
        let halfStyle = SizeValue.fraction(0.5)

        // Unspecified space: falls back to intrinsic (e.g. 40)
        let unspec = ConstraintResolver.resolve(sizeValue: halfStyle, constraint: .unspecified, intrinsic: 40)
        XCTAssertEqual(unspec, 40)

        // AtMost 300: 50% = 150
        let atMost = ConstraintResolver.resolve(sizeValue: halfStyle, constraint: .atMost(300))
        XCTAssertEqual(atMost, 150)

        // Exactly 500: 50% = 250
        let exactly = ConstraintResolver.resolve(sizeValue: halfStyle, constraint: .exactly(500))
        XCTAssertEqual(exactly, 250)
    }

    func testFillSizeResolutionAcrossConstraints() {
        let fillStyle = SizeValue.fill

        // Unspecified space: falls back to intrinsic (e.g. 25)
        let unspec = ConstraintResolver.resolve(sizeValue: fillStyle, constraint: .unspecified, intrinsic: 25)
        XCTAssertEqual(unspec, 25)

        // AtMost 320: takes all 320
        let atMost = ConstraintResolver.resolve(sizeValue: fillStyle, constraint: .atMost(320))
        XCTAssertEqual(atMost, 320)

        // Exactly 400: takes 400
        let exactly = ConstraintResolver.resolve(sizeValue: fillStyle, constraint: .exactly(400))
        XCTAssertEqual(exactly, 400)
    }

    func testIntrinsicSizeResolutionAcrossConstraints() {
        let intrinsicStyle = SizeValue.intrinsic

        // Takes intrinsic value
        let unspec = ConstraintResolver.resolve(sizeValue: intrinsicStyle, constraint: .unspecified, intrinsic: 85)
        XCTAssertEqual(unspec, 85)

        // Clamps if atMost is smaller
        let clamped = ConstraintResolver.resolve(sizeValue: intrinsicStyle, constraint: .atMost(60), intrinsic: 85)
        XCTAssertEqual(clamped, 60)
    }

    // MARK: - 2. Distinction: Unspecified vs Zero Space

    func testUnspecifiedVersusZeroSpaceDistinction() {
        let fill = SizeValue.fill
        let intrinsic = SizeValue.intrinsic

        // Unspecified allows content intrinsic size
        let fillUnspecified = ConstraintResolver.resolve(sizeValue: fill, constraint: .unspecified, intrinsic: 50)
        XCTAssertEqual(fillUnspecified, 50)

        // Zero space forces 0
        let fillZero = ConstraintResolver.resolve(sizeValue: fill, constraint: .exactly(0), intrinsic: 50)
        XCTAssertEqual(fillZero, 0)

        let intrinsicZero = ConstraintResolver.resolve(sizeValue: intrinsic, constraint: .atMost(0), intrinsic: 50)
        XCTAssertEqual(intrinsicZero, 0)
    }

    // MARK: - 3. Min/Max Clamping & Conflict Resolution

    func testMinMaxClamping() {
        // Range: min 50, max 100
        let rangeStyle = SizeValue.range(min: 50, max: 100)

        // Below min -> clamped to 50
        let below = ConstraintResolver.resolve(sizeValue: rangeStyle, constraint: .unspecified, intrinsic: 20)
        XCTAssertEqual(below, 50)

        // Within range -> 75
        let within = ConstraintResolver.resolve(sizeValue: rangeStyle, constraint: .unspecified, intrinsic: 75)
        XCTAssertEqual(within, 75)

        // Above max -> clamped to 100
        let above = ConstraintResolver.resolve(sizeValue: rangeStyle, constraint: .unspecified, intrinsic: 150)
        XCTAssertEqual(above, 100)
    }

    func testConflictingConstraintsMinWinsOverMax() {
        // Conflicting: min 80 > max 50
        let resolved = ConstraintResolver.resolve(
            sizeValue: .fixed(60),
            constraint: .unspecified,
            minBound: 80,
            maxBound: 50
        )
        // Rule: min takes precedence over max for accessibility and readability
        XCTAssertEqual(resolved, 80)
    }

    // MARK: - 4. Invariant Tests (No NaN, No Negatives, Finite)

    func testInvariantsNeverProduceNaNOrNegativeOrInfinite() {
        let testInputs: [Double] = [
            -100, -0.001, 0, 0.0001, 100,
            .nan, .infinity, -.infinity, .greatestFiniteMagnitude
        ]

        for input in testInputs {
            let size = MeasuredSize(width: input, height: input)
            XCTAssertFalse(size.width.isNaN)
            XCTAssertFalse(size.height.isNaN)
            XCTAssertTrue(size.width >= 0)
            XCTAssertTrue(size.height >= 0)
            XCTAssertTrue(size.width.isFinite)
            XCTAssertTrue(size.height.isFinite)

            let resolved = ConstraintResolver.resolve(
                sizeValue: .fixed(input),
                constraint: .atMost(input),
                intrinsic: input,
                minBound: input,
                maxBound: input
            )
            XCTAssertFalse(resolved.isNaN)
            XCTAssertTrue(resolved >= 0)
            XCTAssertTrue(resolved.isFinite)
        }
    }

    // MARK: - 5. Pixel Rounding Policy

    func testPixelRoundingPolicy() {
        let policy2x = PixelRoundingPolicy(scaleFactor: 2.0) // 0.5 step

        XCTAssertEqual(policy2x.roundToPixel(10.2), 10.0)
        XCTAssertEqual(policy2x.roundToPixel(10.3), 10.5)
        XCTAssertEqual(policy2x.ceilToPixel(10.1), 10.5)
        XCTAssertEqual(policy2x.floorToPixel(10.4), 10.0)

        let policy3x = PixelRoundingPolicy(scaleFactor: 3.0) // 1/3 step (~0.333)
        XCTAssertEqual(policy3x.roundToPixel(10.0), 10.0)
        XCTAssertEqual(policy3x.roundToPixel(10.33), 10.333333333333334, accuracy: 0.001)

        let frame = LayoutFrame(x: 10.1, y: 5.2, width: 100.3, height: 50.1)
        let rounded = policy2x.roundFrame(frame)
        XCTAssertEqual(rounded.origin.x, 10.0)
        XCTAssertEqual(rounded.origin.y, 5.0)
        XCTAssertEqual(rounded.width, 100.5)
        XCTAssertEqual(rounded.height, 50.5)
    }
}
