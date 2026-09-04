import XCTest
import CoreGraphics
@testable import PrismCore

final class GestureArenaTests: XCTestCase {

    func testUndecidedStateBelowThreshold() {
        let arena = GestureArena(slopThreshold: 10.0)
        arena.begin(at: CGPoint(x: 100, y: 100))

        // Move 5pt horizontally and 3pt vertically (hypot ≈ 5.8pt < 10pt)
        let state = arena.update(to: CGPoint(x: 105, y: 103))
        if case .undecided = state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected undecided state below slop threshold")
        }
        XCTAssertEqual(arena.displacement.x, 5.0)
        XCTAssertEqual(arena.displacement.y, 3.0)
    }

    func testHorizontalLockWhenHorizontalDeltaDominates() {
        let arena = GestureArena(slopThreshold: 10.0)
        arena.begin(at: CGPoint(x: 100, y: 100))

        // Swipe left by 20pt with 4pt vertical wobble
        let state = arena.update(to: CGPoint(x: 80, y: 104))
        XCTAssertEqual(state, .locked(direction: .horizontal))

        // Further updates stay locked in horizontal direction
        let followUpState = arena.update(to: CGPoint(x: 50, y: 120))
        XCTAssertEqual(followUpState, .locked(direction: .horizontal))
    }

    func testVerticalLockWhenVerticalDeltaDominates() {
        let arena = GestureArena(slopThreshold: 10.0)
        arena.begin(at: CGPoint(x: 100, y: 100))

        // Drag down by 25pt with 2pt horizontal wobble
        let state = arena.update(to: CGPoint(x: 102, y: 125))
        XCTAssertEqual(state, .locked(direction: .vertical))
    }

    func testCancellationAndReset() {
        let arena = GestureArena(slopThreshold: 10.0)
        arena.begin(at: CGPoint(x: 50, y: 50))
        arena.update(to: CGPoint(x: 50, y: 75))
        XCTAssertEqual(arena.state, .locked(direction: .vertical))

        arena.cancel()
        XCTAssertEqual(arena.state, .cancelled)

        arena.reset()
        XCTAssertEqual(arena.state, .idle)
        XCTAssertEqual(arena.displacement, .zero)
    }
}
