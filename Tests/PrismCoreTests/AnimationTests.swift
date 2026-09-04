import XCTest
@testable import PrismCore

@MainActor
final class AnimationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReduceMotionPreference.isEnabled = false
    }

    override func tearDown() {
        ReduceMotionPreference.isEnabled = false
        super.tearDown()
    }

    // MARK: - 1. Timing Curves & Duration

    func testTimingCurvesAndModifiers() {
        let linear = Animation.linear(duration: 0.5)
        XCTAssertEqual(linear.curve, .linear)
        XCTAssertEqual(linear.nominalDuration, 0.5)
        XCTAssertEqual(linear.delay, 0.0)
        XCTAssertEqual(linear.speed, 1.0)
        XCTAssertNil(linear.repeatCount)
        XCTAssertFalse(linear.autoreverses)
        XCTAssertFalse(linear.isRepeatForever)

        let modified = linear.delay(0.2).speed(2.0).repeatCount(3, autoreverses: true)
        XCTAssertEqual(modified.delay, 0.2)
        XCTAssertEqual(modified.speed, 2.0)
        XCTAssertEqual(modified.repeatCount, 3)
        XCTAssertTrue(modified.autoreverses)
        XCTAssertEqual(modified.singleIterationDuration, 0.25)
        XCTAssertEqual(modified.totalDuration, 0.2 + (0.25 * 3))

        let repeatingForever = linear.repeatForever()
        XCTAssertTrue(repeatingForever.isRepeatForever)
        XCTAssertEqual(repeatingForever.totalDuration, .infinity)
    }

    // MARK: - 2. Physically Based Springs

    func testSpringPrimitives() {
        let spring = Animation.spring(response: 0.4, dampingRatio: 0.8)
        if case .spring(let r, let d, _) = spring.curve {
            XCTAssertEqual(r, 0.4)
            XCTAssertEqual(d, 0.8)
        } else {
            XCTFail("Expected .spring timing curve")
        }
        XCTAssertGreaterThan(spring.nominalDuration, 0.1)

        let bouncy = Animation.bouncy(duration: 0.5, extraBounce: 0.2)
        XCTAssertGreaterThan(bouncy.nominalDuration, 0.0)

        let snappy = Animation.snappy(duration: 0.4)
        XCTAssertGreaterThan(snappy.nominalDuration, 0.0)

        let interpolating = Animation.interpolatingSpring(mass: 2.0, stiffness: 200.0, damping: 15.0)
        if case .interpolatingSpring(let m, let s, let d, _) = interpolating.curve {
            XCTAssertEqual(m, 2.0)
            XCTAssertEqual(s, 200.0)
            XCTAssertEqual(d, 15.0)
        } else {
            XCTFail("Expected .interpolatingSpring timing curve")
        }
    }

    // MARK: - 3. Transaction Scoping & withAnimation

    func testTransactionScoping() {
        XCTAssertNil(Transaction.current.animation)
        XCTAssertFalse(Transaction.current.disablesAnimations)

        let anim = Animation.spring()
        withAnimation(anim) {
            XCTAssertEqual(Transaction.current.animation, anim)
            XCTAssertFalse(Transaction.current.disablesAnimations)

            // Nested override
            let innerAnim = Animation.linear(duration: 0.2)
            withAnimation(innerAnim) {
                XCTAssertEqual(Transaction.current.animation, innerAnim)
            }

            // Back to outer transaction
            XCTAssertEqual(Transaction.current.animation, anim)
        }

        // Ambient restored
        XCTAssertNil(Transaction.current.animation)
    }

    func testDisabledTransactionSuppression() {
        let disabledTx = Transaction(disablesAnimations: true)
        withTransaction(disabledTx) {
            XCTAssertTrue(Transaction.current.disablesAnimations)

            // Inner withAnimation should be suppressed
            withAnimation(.default) {
                XCTAssertTrue(Transaction.current.disablesAnimations)
                XCTAssertNil(Transaction.current.animation)
            }
        }
    }

    // MARK: - 4. Transition Declarations & Combinators

    func testTransitions() {
        let opacity = Transition.opacity
        XCTAssertEqual(opacity.insertion, .opacity(start: 0.0))
        XCTAssertEqual(opacity.removal, .opacity(start: 0.0))

        let scale = Transition.scale(0.5)
        XCTAssertEqual(scale.insertion, .scale(factor: 0.5))
        XCTAssertEqual(scale.removal, .scale(factor: 0.5))

        let combined = opacity.combined(with: scale)
        XCTAssertEqual(combined.insertion, .combined(.opacity(start: 0.0), .scale(factor: 0.5)))
        XCTAssertEqual(combined.removal, .combined(.opacity(start: 0.0), .scale(factor: 0.5)))

        let asymmetric = Transition.asymmetric(insertion: .slide, removal: .opacity)
        XCTAssertEqual(asymmetric.insertion, .move(edge: .leading))
        XCTAssertEqual(asymmetric.removal, .opacity(start: 0.0))
    }

    // MARK: - 5. Reduce Motion Accessibility Adaptation

    func testReduceMotionFallback() {
        let slide = Transition.slide
        let resolvedNormal = slide.resolved(reduceMotion: false)
        XCTAssertEqual(resolvedNormal.insertion, .move(edge: .leading))

        // When reduceMotion is enabled, physical sliding falls back to a crossfade
        let resolvedReduced = slide.resolved(reduceMotion: true)
        XCTAssertEqual(resolvedReduced.insertion, .opacity(start: 0.0))
        XCTAssertEqual(resolvedReduced.removal, .opacity(start: 0.0))

        // withAnimation under reduce motion suppression
        ReduceMotionPreference.isEnabled = true
        withAnimation(.bouncy()) {
            XCTAssertNil(Transaction.current.animation)
        }
    }
}
