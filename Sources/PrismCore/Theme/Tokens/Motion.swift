import Foundation

/// Animation duration representation.
public struct DurationToken: Equatable, Sendable, CustomStringConvertible {
    public let seconds: Double

    public init(seconds: Double) {
        self.seconds = max(0, seconds)
    }

    public static func milliseconds(_ ms: Int) -> DurationToken {
        DurationToken(seconds: Double(ms) / 1000.0)
    }

    public static func seconds(_ s: Double) -> DurationToken {
        DurationToken(seconds: s)
    }

    public static let zero = DurationToken(seconds: 0)

    public var description: String {
        let ms = Int(round(seconds * 1000))
        return "\(ms)ms"
    }
}

/// Timing curves for animations.
public enum AnimationCurve: String, Sendable, CaseIterable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring
}

/// Motion tokens specifying duration and easing curves across the UI.
public struct Motion: Equatable, Sendable {
    public let fast: DurationToken
    public let normal: DurationToken
    public let slow: DurationToken
    public let defaultCurve: AnimationCurve

    public init(
        fast: DurationToken = .milliseconds(150),
        normal: DurationToken = .milliseconds(250),
        slow: DurationToken = .milliseconds(400),
        defaultCurve: AnimationCurve = .easeInOut
    ) {
        self.fast = fast
        self.normal = normal
        self.slow = slow
        self.defaultCurve = defaultCurve
    }

    /// Resolves duration respecting the accessibility Reduce Motion preference.
    public func resolveDuration(_ duration: DurationToken, reduceMotion: Bool) -> DurationToken {
        reduceMotion ? .zero : duration
    }
}
