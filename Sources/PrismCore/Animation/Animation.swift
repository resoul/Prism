import Foundation

/// Mathematical timing curve representation.
public enum TimingCurve: Equatable, Sendable, Hashable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case cubicBezier(c1x: Double, c1y: Double, c2x: Double, c2y: Double)
    case spring(response: Double, dampingRatio: Double, blendDuration: Double)
    case interpolatingSpring(mass: Double, stiffness: Double, damping: Double, initialVelocity: Double)
}

/// Declarative, pure value representation of an animation.
public struct Animation: Equatable, Sendable, Hashable {
    public var curve: TimingCurve
    public var nominalDuration: Double
    public var delay: Double
    public var speed: Double
    public var repeatCount: Int?
    public var autoreverses: Bool
    public var isRepeatForever: Bool

    public init(
        curve: TimingCurve,
        nominalDuration: Double,
        delay: Double = 0.0,
        speed: Double = 1.0,
        repeatCount: Int? = nil,
        autoreverses: Bool = false,
        isRepeatForever: Bool = false
    ) {
        self.curve = curve
        self.nominalDuration = max(0.0, nominalDuration)
        self.delay = max(0.0, delay)
        self.speed = max(0.001, speed)
        self.repeatCount = repeatCount
        self.autoreverses = autoreverses
        self.isRepeatForever = isRepeatForever
    }

    // MARK: - Standard Timing Curves

    public static func linear(duration: Double = 0.35) -> Animation {
        Animation(curve: .linear, nominalDuration: duration)
    }

    public static func easeIn(duration: Double = 0.35) -> Animation {
        Animation(curve: .easeIn, nominalDuration: duration)
    }

    public static func easeOut(duration: Double = 0.35) -> Animation {
        Animation(curve: .easeOut, nominalDuration: duration)
    }

    public static func easeInOut(duration: Double = 0.35) -> Animation {
        Animation(curve: .easeInOut, nominalDuration: duration)
    }

    public static func timingCurve(
        _ c1x: Double,
        _ c1y: Double,
        _ c2x: Double,
        _ c2y: Double,
        duration: Double = 0.35
    ) -> Animation {
        Animation(curve: .cubicBezier(c1x: c1x, c1y: c1y, c2x: c2x, c2y: c2y), nominalDuration: duration)
    }

    public static let `default`: Animation = .easeInOut(duration: 0.35)

    // MARK: - Physically-based Springs

    public static func spring(
        response: Double = 0.55,
        dampingRatio: Double = 0.825,
        blendDuration: Double = 0.0
    ) -> Animation {
        // Effective settling duration for standard harmonic oscillator
        let duration = max(0.1, response * 3.5)
        return Animation(
            curve: .spring(response: response, dampingRatio: dampingRatio, blendDuration: blendDuration),
            nominalDuration: duration
        )
    }

    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0.2) -> Animation {
        let dampingRatio = max(0.1, 0.7 - extraBounce * 0.5)
        return .spring(response: duration, dampingRatio: dampingRatio)
    }

    public static func snappy(duration: Double = 0.4, extraBounce: Double = 0.0) -> Animation {
        let dampingRatio = max(0.1, 0.85 - extraBounce * 0.3)
        return .spring(response: duration, dampingRatio: dampingRatio)
    }

    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0.0) -> Animation {
        let dampingRatio = max(0.1, 1.0 - extraBounce * 0.2)
        return .spring(response: duration, dampingRatio: dampingRatio)
    }

    public static func interpolatingSpring(
        mass: Double = 1.0,
        stiffness: Double = 100.0,
        damping: Double = 10.0,
        initialVelocity: Double = 0.0
    ) -> Animation {
        let safeMass = max(0.001, mass)
        let safeStiffness = max(0.001, stiffness)
        let gamma = damping / (2.0 * safeMass)
        let duration = gamma > 0 ? min(3.0, 7.0 / gamma) : 1.0
        return Animation(
            curve: .interpolatingSpring(
                mass: safeMass,
                stiffness: safeStiffness,
                damping: damping,
                initialVelocity: initialVelocity
            ),
            nominalDuration: max(0.1, duration)
        )
    }

    // MARK: - Modifiers

    public func delay(_ delay: Double) -> Animation {
        var copy = self
        copy.delay = max(0.0, delay)
        return copy
    }

    public func speed(_ speed: Double) -> Animation {
        var copy = self
        copy.speed = max(0.001, speed)
        return copy
    }

    public func repeatCount(_ count: Int, autoreverses: Bool = true) -> Animation {
        var copy = self
        copy.repeatCount = max(1, count)
        copy.autoreverses = autoreverses
        copy.isRepeatForever = false
        return copy
    }

    public func repeatForever(autoreverses: Bool = true) -> Animation {
        var copy = self
        copy.repeatCount = nil
        copy.autoreverses = autoreverses
        copy.isRepeatForever = true
        return copy
    }

    // MARK: - Timing Computation

    /// Computes the effective duration of one iteration (accounting for speed).
    public var singleIterationDuration: Double {
        nominalDuration / speed
    }

    /// Computes total nominal duration including delay, repeats, and speed scaling.
    public var totalDuration: Double {
        if isRepeatForever {
            return .infinity
        }
        let count = Double(repeatCount ?? 1)
        return delay + (singleIterationDuration * count)
    }
}
