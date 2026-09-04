import Foundation
import CoreGraphics

/// Direction classification for 2D pan gestures.
public enum PanDirection: Sendable, Equatable {
    case horizontal
    case vertical
}

/// Disambiguation state machine for pan gestures across nested horizontal and vertical scroll containers.
public final class GestureArena: @unchecked Sendable {
    public enum State: Sendable, Equatable {
        case idle
        case undecided(start: CGPoint, current: CGPoint)
        case locked(direction: PanDirection)
        case cancelled
        case ended
    }

    /// Distance in points a gesture must travel before a direction lock is decided.
    public let slopThreshold: Double

    /// Current arbitration state.
    public private(set) var state: State = .idle

    /// The starting contact point of the active gesture.
    public private(set) var startPoint: CGPoint = .zero

    /// Total displacement accumulated since gesture start.
    public private(set) var displacement: CGPoint = .zero

    public init(slopThreshold: Double = 10.0) {
        self.slopThreshold = max(1.0, slopThreshold)
    }

    /// Starts a new gesture sequence at the specified coordinate.
    public func begin(at point: CGPoint) {
        startPoint = point
        displacement = .zero
        state = .undecided(start: point, current: point)
    }

    /// Updates the active gesture with a new touch/pointer coordinate.
    ///
    /// - Parameter point: The current location in points.
    /// - Returns: The updated arbitration state.
    @discardableResult
    public func update(to point: CGPoint) -> State {
        guard case .undecided = state else {
            if case .locked = state {
                displacement = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
            }
            return state
        }

        displacement = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
        let distance = hypot(displacement.x, displacement.y)

        if distance >= CGFloat(slopThreshold) {
            // Determine dominant axis
            if abs(displacement.x) > abs(displacement.y) {
                state = .locked(direction: .horizontal)
            } else {
                state = .locked(direction: .vertical)
            }
        } else {
            state = .undecided(start: startPoint, current: point)
        }

        return state
    }

    /// Cancels the current gesture sequence.
    public func cancel() {
        state = .cancelled
    }

    /// Ends the current gesture sequence normally.
    public func end() {
        state = .ended
    }

    /// Resets the arena to its initial idle state.
    public func reset() {
        state = .idle
        startPoint = .zero
        displacement = .zero
    }
}
