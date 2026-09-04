import Foundation
import CoreGraphics

/// Deterministic physics simulator for scrolling gestures, deceleration, rubber-banding, and bounds clamping.
public final class ScrollPhysicsEngine: @unchecked Sendable {
    public var axis: ScrollAxis
    public var bounces: Bool
    public var friction: Double = 0.998 // Standard deceleration decay
    public var rubberBandCoefficient: Double = 0.55 // iOS standard rubber-band factor

    public private(set) var position: ScrollPosition
    public private(set) var velocity: CGPoint = .zero
    public private(set) var isDecelerating: Bool = false

    public init(
        axis: ScrollAxis = .vertical,
        bounces: Bool = true,
        position: ScrollPosition = .init()
    ) {
        self.axis = axis
        self.bounces = bounces
        self.position = position
    }

    // MARK: - Viewport & Content Configuration

    public func updateMetrics(contentSize: CGSize, viewportSize: CGSize) {
        position.contentSize = contentSize
        position.viewportSize = viewportSize
        clampPosition()
    }

    // MARK: - Gesture Dragging & Remainder Propagation

    /// Applies a delta from a drag or scroll-wheel event.
    ///
    /// - Parameter delta: The translation delta in points.
    /// - Returns: Any unconsumed remainder delta that can propagate to an enclosing nested scroll container.
    @discardableResult
    public func applyDelta(_ delta: CGPoint) -> CGPoint {
        isDecelerating = false
        velocity = .zero

        var consumedX: CGFloat = 0
        var consumedY: CGFloat = 0

        let max = position.maxOffset

        // Horizontal axis handling
        if axis == .horizontal || axis == .both {
            let proposedX = position.offset.x - delta.x
            if proposedX < 0 {
                if bounces {
                    position.offset.x -= delta.x * rubberBandCoefficient
                    consumedX = delta.x
                } else {
                    consumedX = position.offset.x
                    position.offset.x = 0
                }
            } else if proposedX > max.x {
                if bounces {
                    position.offset.x -= delta.x * rubberBandCoefficient
                    consumedX = delta.x
                } else {
                    consumedX = -(max.x - position.offset.x)
                    position.offset.x = max.x
                }
            } else {
                position.offset.x = proposedX
                consumedX = delta.x
            }
        }

        // Vertical axis handling
        if axis == .vertical || axis == .both {
            let proposedY = position.offset.y - delta.y
            if proposedY < 0 {
                if bounces {
                    position.offset.y -= delta.y * rubberBandCoefficient
                    consumedY = delta.y
                } else {
                    consumedY = position.offset.y
                    position.offset.y = 0
                }
            } else if proposedY > max.y {
                if bounces {
                    position.offset.y -= delta.y * rubberBandCoefficient
                    consumedY = delta.y
                } else {
                    consumedY = -(max.y - position.offset.y)
                    position.offset.y = max.y
                }
            } else {
                position.offset.y = proposedY
                consumedY = delta.y
            }
        }

        return CGPoint(x: delta.x - consumedX, y: delta.y - consumedY)
    }

    /// Begins inertial deceleration with the specified initial velocity.
    public func startFling(initialVelocity: CGPoint) {
        self.velocity = CGPoint(
            x: (axis == .horizontal || axis == .both) ? initialVelocity.x : 0,
            y: (axis == .vertical || axis == .both) ? initialVelocity.y : 0
        )
        self.isDecelerating = abs(velocity.x) > 10 || abs(velocity.y) > 10
    }

    // MARK: - Simulation Step

    /// Advances the physics simulation by `deltaTime` seconds using a deterministic clock.
    public func advance(deltaTime: Double) {
        guard isDecelerating || isOverscrolled else {
            isDecelerating = false
            return
        }

        let max = position.maxOffset

        // 1. Rubber-band spring restoration if outside bounds
        if position.offset.y < 0 {
            let displacement = position.offset.y
            let springForce = -displacement * 15.0
            position.offset.y += springForce * CGFloat(deltaTime)
            if position.offset.y > -0.5 { position.offset.y = 0 }
            velocity.y = 0
        } else if position.offset.y > max.y {
            let displacement = position.offset.y - max.y
            let springForce = -displacement * 15.0
            position.offset.y += springForce * CGFloat(deltaTime)
            if position.offset.y < max.y + 0.5 { position.offset.y = max.y }
            velocity.y = 0
        }

        if position.offset.x < 0 {
            let displacement = position.offset.x
            let springForce = -displacement * 15.0
            position.offset.x += springForce * CGFloat(deltaTime)
            if position.offset.x > -0.5 { position.offset.x = 0 }
            velocity.x = 0
        } else if position.offset.x > max.x {
            let displacement = position.offset.x - max.x
            let springForce = -displacement * 15.0
            position.offset.x += springForce * CGFloat(deltaTime)
            if position.offset.x < max.x + 0.5 { position.offset.x = max.x }
            velocity.x = 0
        }

        // 2. Velocity deceleration
        if isDecelerating {
            position.offset.x += velocity.x * CGFloat(deltaTime)
            position.offset.y += velocity.y * CGFloat(deltaTime)

            let decay = CGFloat(pow(friction, deltaTime * 1000.0))
            velocity.x *= decay
            velocity.y *= decay

            if abs(velocity.x) < 5 && abs(velocity.y) < 5 {
                velocity = .zero
                isDecelerating = false
            }

            if !bounces {
                clampPosition()
            }
        }
    }

    // MARK: - Programmatic Scroll-To

    /// Calculates target offset for a target rect and anchor alignment.
    public func targetOffset(for targetFrame: CGRect, anchor: ScrollAnchor) -> CGPoint {
        var target = position.offset
        let max = position.maxOffset

        switch anchor {
        case .top:
            target.y = targetFrame.minY
        case .center:
            target.y = targetFrame.midY - position.viewportSize.height / 2.0
            target.x = targetFrame.midX - position.viewportSize.width / 2.0
        case .bottom:
            target.y = targetFrame.maxY - position.viewportSize.height
        case .leading:
            target.x = targetFrame.minX
        case .trailing:
            target.x = targetFrame.maxX - position.viewportSize.width
        }

        // Clamp to content bounds
        target.x = min(max.x, Swift.max(0, target.x))
        target.y = min(max.y, Swift.max(0, target.y))
        return target
    }

    /// Sets the offset directly, clamping if bounces is disabled.
    public func setOffset(_ offset: CGPoint) {
        position.offset = offset
        isDecelerating = false
        velocity = .zero
        if !bounces {
            clampPosition()
        }
    }

    // MARK: - Helper

    public var isOverscrolled: Bool {
        let max = position.maxOffset
        return position.offset.x < -0.5 || position.offset.x > max.x + 0.5 ||
               position.offset.y < -0.5 || position.offset.y > max.y + 0.5
    }

    private func clampPosition() {
        let max = position.maxOffset
        position.offset.x = min(max.x, Swift.max(0, position.offset.x))
        position.offset.y = min(max.y, Swift.max(0, position.offset.y))
    }
}
