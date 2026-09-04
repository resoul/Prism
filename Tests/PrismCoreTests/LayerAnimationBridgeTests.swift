import XCTest
import QuartzCore
@testable import PrismCore

@MainActor
final class LayerAnimationBridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReduceMotionPreference.isEnabled = false
    }

    // MARK: - 1. Zero Model Drift

    func testModelLayerUpdatedImmediatelyWithoutDrift() {
        let layer = CALayer()
        layer.opacity = 1.0

        let animated = LayerAnimationBridge.animate(
            layer: layer,
            keyPath: "opacity",
            targetValue: Float(0.3),
            animation: .linear(duration: 0.4)
        )

        XCTAssertTrue(animated)
        // Model value must be 0.3 immediately so on completion or removal no jump occurs
        XCTAssertEqual(layer.opacity, Float(0.3), accuracy: 0.001)

        let anim = layer.animation(forKey: "opacity") as? CABasicAnimation
        XCTAssertNotNil(anim)
        XCTAssertEqual((anim?.fromValue as? NSNumber)?.floatValue, Float(1.0))
        XCTAssertEqual((anim?.toValue as? NSNumber)?.floatValue, Float(0.3))
    }

    // MARK: - 2. Interruption Resets fromValue Seamlessly

    func testInterruptedAnimationContinuity() {
        let layer = CALayer()
        layer.position = CGPoint(x: 10, y: 10)

        // First animation
        LayerAnimationBridge.animate(
            layer: layer,
            keyPath: "position",
            targetValue: CGPoint(x: 100, y: 100),
            animation: .easeInOut(duration: 0.5)
        )
        XCTAssertEqual(layer.position, CGPoint(x: 100, y: 100))

        // Second animation interrupting the first
        LayerAnimationBridge.animate(
            layer: layer,
            keyPath: "position",
            targetValue: CGPoint(x: 200, y: 50),
            animation: .spring()
        )
        // Model layer is updated to new target immediately
        XCTAssertEqual(layer.position, CGPoint(x: 200, y: 50))
        let springAnim = layer.animation(forKey: "position") as? CASpringAnimation
        XCTAssertNotNil(springAnim)
    }

    // MARK: - 3. Keyframe Track & Cancellation

    func testKeyframeAnimationAndCancellation() {
        let layer = CALayer()
        layer.opacity = 1.0

        let track = KeyframeTrack(
            keyframes: [
                Keyframe(value: Float(0.2), duration: 0.1),
                Keyframe(value: Float(0.8), duration: 0.2),
                Keyframe(value: Float(1.0), duration: 0.1)
            ],
            repeatCount: 1
        )

        let token = LayerAnimationBridge.animateKeyframes(
            layer: layer,
            keyPath: "opacity",
            track: track
        )

        XCTAssertNotNil(layer.animation(forKey: "prism.keyframe.opacity"))

        // Cancellation on unmount
        token.cancel()
        XCTAssertNil(layer.animation(forKey: "prism.keyframe.opacity"))
    }

    // MARK: - 4. Reduce Motion Instant Application

    func testReduceMotionInstantModelApplication() {
        let layer = CALayer()
        layer.opacity = 1.0

        let animated = LayerAnimationBridge.animate(
            layer: layer,
            keyPath: "opacity",
            targetValue: Float(0.0),
            animation: .linear(duration: 0.5),
            reduceMotion: true
        )

        // Must not create CAAnimation when reduceMotion is active
        XCTAssertFalse(animated)
        XCTAssertEqual(layer.opacity, 0.0)
        XCTAssertNil(layer.animation(forKey: "opacity"))
    }
}
