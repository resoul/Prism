import Foundation
import QuartzCore

/// An individual keyframe in a keyframe track.
public struct Keyframe<Value: Sendable>: Sendable {
    public var value: Value
    public var duration: Double
    public var curve: TimingCurve

    public init(value: Value, duration: Double, curve: TimingCurve = .linear) {
        self.value = value
        self.duration = max(0.0, duration)
        self.curve = curve
    }
}

extension Keyframe: Equatable where Value: Equatable {}

/// A track of consecutive keyframes for animating a specific property.
public struct KeyframeTrack<Value: Sendable>: Sendable {
    public var keyframes: [Keyframe<Value>]
    public var repeatCount: Int?
    public var autoreverses: Bool
    public var isRepeatForever: Bool

    public init(
        keyframes: [Keyframe<Value>],
        repeatCount: Int? = nil,
        autoreverses: Bool = false,
        isRepeatForever: Bool = false
    ) {
        self.keyframes = keyframes
        self.repeatCount = repeatCount
        self.autoreverses = autoreverses
        self.isRepeatForever = isRepeatForever
    }

    /// Total duration of one cycle across all keyframes.
    public var cycleDuration: Double {
        keyframes.reduce(0.0) { $0 + $1.duration }
    }
}

/// Cancellation token for keyframe animations, allowing unmount or backgrounding cancellation.
@MainActor
public final class KeyframeAnimationToken: @unchecked Sendable {
    private weak var targetLayer: CALayer?
    private let animationKey: String
    private var isCancelled: Bool = false
    private let onCancel: (@MainActor () -> Void)?

    public init(targetLayer: CALayer?, animationKey: String, onCancel: (@MainActor () -> Void)? = nil) {
        self.targetLayer = targetLayer
        self.animationKey = animationKey
        self.onCancel = onCancel
    }

    /// Cancels the keyframe animation immediately.
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        targetLayer?.removeAnimation(forKey: animationKey)
        onCancel?()
    }
}
