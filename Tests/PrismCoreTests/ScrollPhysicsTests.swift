import XCTest
import CoreGraphics
@testable import PrismCore

final class ScrollPhysicsTests: XCTestCase {

    func testScrollPositionProgressCalculation() {
        let position = ScrollPosition(
            offset: CGPoint(x: 50, y: 100),
            contentSize: CGSize(width: 200, height: 500),
            viewportSize: CGSize(width: 100, height: 300)
        )

        // maxOffset: width: 200 - 100 = 100, height: 500 - 300 = 200
        XCTAssertEqual(position.maxOffset.x, 100)
        XCTAssertEqual(position.maxOffset.y, 200)

        XCTAssertEqual(position.horizontalProgress, 0.5) // 50 / 100
        XCTAssertEqual(position.verticalProgress, 0.5)   // 100 / 200
    }

    func testDragDeltaAndBoundsClampingWithoutBounces() {
        let physics = ScrollPhysicsEngine(axis: .vertical, bounces: false)
        physics.updateMetrics(contentSize: CGSize(width: 100, height: 400), viewportSize: CGSize(width: 100, height: 200))

        // Drag downwards (offset.y increases)
        let remainder1 = physics.applyDelta(CGPoint(x: 0, y: -50))
        XCTAssertEqual(physics.position.offset.y, 50)
        XCTAssertEqual(remainder1.y, 0)

        // Drag past maximum boundary (max is 200)
        let remainder2 = physics.applyDelta(CGPoint(x: 0, y: -250))
        XCTAssertEqual(physics.position.offset.y, 200) // Clamped at 200
        XCTAssertEqual(remainder2.y, -100) // Unconsumed remainder passes to parent
    }

    func testRubberBandResistanceWithBounces() {
        let physics = ScrollPhysicsEngine(axis: .vertical, bounces: true)
        physics.updateMetrics(contentSize: CGSize(width: 100, height: 300), viewportSize: CGSize(width: 100, height: 200))

        // Pull past top boundary (offset < 0)
        physics.applyDelta(CGPoint(x: 0, y: 100))
        XCTAssertTrue(physics.position.offset.y < 0)
        // With 0.55 coefficient, offset should be dampened to -55
        XCTAssertEqual(physics.position.offset.y, -55, accuracy: 1.0)
        XCTAssertTrue(physics.isOverscrolled)
    }

    func testDecelerationDecay() {
        let physics = ScrollPhysicsEngine(axis: .vertical, bounces: false)
        physics.updateMetrics(contentSize: CGSize(width: 100, height: 1000), viewportSize: CGSize(width: 100, height: 200))

        physics.startFling(initialVelocity: CGPoint(x: 0, y: 500))
        XCTAssertTrue(physics.isDecelerating)

        // Step simulation forward by 0.1s
        physics.advance(deltaTime: 0.1)
        XCTAssertTrue(physics.position.offset.y > 0)
        XCTAssertTrue(physics.velocity.y < 500)
    }

    func testTargetOffsetCalculations() {
        let physics = ScrollPhysicsEngine(axis: .vertical)
        physics.updateMetrics(contentSize: CGSize(width: 100, height: 1000), viewportSize: CGSize(width: 100, height: 200))

        let targetFrame = CGRect(x: 0, y: 400, width: 100, height: 50)

        let topOffset = physics.targetOffset(for: targetFrame, anchor: .top)
        XCTAssertEqual(topOffset.y, 400)

        let centerOffset = physics.targetOffset(for: targetFrame, anchor: .center)
        // midY is 425; viewport/2 is 100 -> 325
        XCTAssertEqual(centerOffset.y, 325)

        let bottomOffset = physics.targetOffset(for: targetFrame, anchor: .bottom)
        // maxY is 450; viewport is 200 -> 250
        XCTAssertEqual(bottomOffset.y, 250)
    }
}
