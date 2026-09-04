import Foundation

/// Defines visual transition effects applied when a node is mounted or removed from the render tree.
public struct Transition: Equatable, Sendable {
    /// Screen or container edges for directional transitions.
    public enum TransitionEdge: String, Equatable, Sendable, CaseIterable {
        case top
        case leading
        case bottom
        case trailing
    }

    /// Primitive visual transform effect during transition.
    public enum Effect: Equatable, Sendable {
        case identity
        case opacity(start: Double)
        case scale(factor: Double)
        case move(edge: TransitionEdge)
        case offset(x: Double, y: Double)
        indirect case combined(Effect, Effect)

        /// Flattens this effect hierarchy into atomic components.
        public var atomicEffects: [Effect] {
            switch self {
            case .identity:
                return []
            case .combined(let a, let b):
                return a.atomicEffects + b.atomicEffects
            default:
                return [self]
            }
        }

        /// Returns an accessibility-adapted effect that substitutes motion/scaling with a crossfade.
        public var reducedMotionFallback: Effect {
            switch self {
            case .identity:
                return .identity
            case .opacity(let s):
                return .opacity(start: s)
            case .scale, .move, .offset:
                return .opacity(start: 0.0)
            case .combined(let a, let b):
                return .combined(a.reducedMotionFallback, b.reducedMotionFallback)
            }
        }
    }

    public var insertion: Effect
    public var removal: Effect
    public var animation: Animation?

    public init(insertion: Effect, removal: Effect, animation: Animation? = nil) {
        self.insertion = insertion
        self.removal = removal
        self.animation = animation
    }

    // MARK: - Standard Transitions

    /// Neutral transition with no visual deviation.
    public static let identity = Transition(insertion: .identity, removal: .identity)

    /// Opacity fade transition (0.0 <-> 1.0).
    public static let opacity = Transition(insertion: .opacity(start: 0.0), removal: .opacity(start: 0.0))

    /// Scale transition from/to the specified scale factor.
    public static func scale(_ factor: Double = 0.0) -> Transition {
        Transition(insertion: .scale(factor: factor), removal: .scale(factor: factor))
    }

    /// Directional slide transition moving from/to an edge.
    public static func move(edge: TransitionEdge) -> Transition {
        Transition(insertion: .move(edge: edge), removal: .move(edge: edge))
    }

    /// Classic slide transition: enters from leading edge and exits toward trailing edge.
    public static let slide = Transition(insertion: .move(edge: .leading), removal: .move(edge: .trailing))

    /// Explicit offset transition.
    public static func offset(x: Double = 0.0, y: Double = 0.0) -> Transition {
        Transition(insertion: .offset(x: x, y: y), removal: .offset(x: x, y: y))
    }

    // MARK: - Combinators

    /// Combines two transitions into a composite transition.
    public func combined(with other: Transition) -> Transition {
        Transition(
            insertion: .combined(self.insertion, other.insertion),
            removal: .combined(self.removal, other.removal),
            animation: other.animation ?? self.animation
        )
    }

    /// Creates an asymmetric transition with distinct insertion and removal effects.
    public static func asymmetric(insertion: Transition, removal: Transition) -> Transition {
        Transition(
            insertion: insertion.insertion,
            removal: removal.removal,
            animation: insertion.animation ?? removal.animation
        )
    }

    /// Overrides or assigns an explicit animation curve to this transition.
    public func animation(_ animation: Animation?) -> Transition {
        var copy = self
        copy.animation = animation
        return copy
    }

    /// Resolves this transition respecting the reduce-motion preference.
    public func resolved(reduceMotion: Bool) -> Transition {
        guard reduceMotion else { return self }
        return Transition(
            insertion: insertion.reducedMotionFallback,
            removal: removal.reducedMotionFallback,
            animation: animation?.nominalDuration == 0 ? nil : Animation.easeInOut(duration: 0.15)
        )
    }
}
