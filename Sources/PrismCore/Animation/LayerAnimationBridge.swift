import Foundation
import QuartzCore

/// Core Animation delegate bridging completion closures back to the MainActor.
@MainActor
private final class LayerAnimationDelegateWrapper: NSObject, CAAnimationDelegate, @unchecked Sendable {
    private let onComplete: (@MainActor (Bool) -> Void)?

    init(onComplete: (@MainActor (Bool) -> Void)?) {
        self.onComplete = onComplete
    }

    nonisolated func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        Task { @MainActor in
            self.onComplete?(flag)
        }
    }
}

/// Renderer bridge synthesizing explicit Core Animation objects from declarative Animation models.
///
/// Invariant: Layer model properties are updated immediately under an actions-disabled CATransaction,
/// and explicit CAAnimations are attached with fromValue sampled from the current presentation layer.
/// This guarantees zero model/presentation drift upon completion or interruption.
@MainActor
public enum LayerAnimationBridge {

    // MARK: - Diagnostics & Telemetry

    public static private(set) var activeAnimationCount: Int = 0
    public static var onAnimationStarted: (@MainActor (String, UUID?) -> Void)?
    public static var onAnimationCompleted: (@MainActor (String, UUID?) -> Void)?

    // MARK: - Explicit Property Animation

    /// Animates a property on a `CALayer` using declarative animation settings.
    @discardableResult
    public static func animate(
        layer: CALayer,
        keyPath: String,
        targetValue: Any,
        animation: Animation?,
        transactionID: UUID? = nil,
        reduceMotion: Bool = false,
        completion: (@MainActor (Bool) -> Void)? = nil
    ) -> Bool {
        // If animations are suppressed, nil, or reduced motion applies, apply model directly
        guard let anim = animation, anim.nominalDuration > 0, !reduceMotion else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.setValue(targetValue, forKeyPath: keyPath)
            CATransaction.commit()
            completion?(true)
            return false
        }

        // 1. Sample current presentation layer value (or fallback to current model value)
        let fromValue = layer.presentation()?.value(forKeyPath: keyPath) ?? layer.value(forKeyPath: keyPath)

        // 2. Immediately commit target value to layer model to prevent drift
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.setValue(targetValue, forKeyPath: keyPath)
        CATransaction.commit()

        // 3. Synthesize explicit CAAnimation
        let caAnimation = makeCAAnimation(
            curve: anim.curve,
            nominalDuration: anim.singleIterationDuration,
            keyPath: keyPath,
            fromValue: fromValue,
            toValue: targetValue
        )

        if anim.delay > 0 {
            caAnimation.beginTime = CACurrentMediaTime() + anim.delay
        }
        caAnimation.speed = Float(anim.speed)
        caAnimation.autoreverses = anim.autoreverses

        if anim.isRepeatForever {
            caAnimation.repeatCount = .infinity
        } else if let count = anim.repeatCount, count > 1 {
            caAnimation.repeatCount = Float(count)
        }

        caAnimation.isRemovedOnCompletion = true
        caAnimation.fillMode = .removed

        // 4. Attach completion delegate & telemetry
        activeAnimationCount += 1
        onAnimationStarted?(keyPath, transactionID)

        let delegate = LayerAnimationDelegateWrapper { finished in
            activeAnimationCount = max(0, activeAnimationCount - 1)
            onAnimationCompleted?(keyPath, transactionID)
            completion?(finished)
        }
        caAnimation.delegate = delegate

        // 5. Add explicit animation to layer
        layer.add(caAnimation, forKey: keyPath)
        return true
    }

    // MARK: - CAAnimation Synthesis

    private static func makeCAAnimation(
        curve: TimingCurve,
        nominalDuration: Double,
        keyPath: String,
        fromValue: Any?,
        toValue: Any
    ) -> CAPropertyAnimation {
        switch curve {
        case .spring(let response, let dampingRatio, _):
            let spring = CASpringAnimation(keyPath: keyPath)
            let safeResponse = max(0.01, response)
            let omega0 = 2.0 * .pi / safeResponse
            let mass: CGFloat = 1.0
            let stiffness = CGFloat(mass * omega0 * omega0)
            let damping = CGFloat(2.0 * dampingRatio * Double(mass) * omega0)

            spring.mass = mass
            spring.stiffness = max(1.0, stiffness)
            spring.damping = max(0.1, damping)
            spring.initialVelocity = 0.0
            spring.duration = max(0.1, spring.settlingDuration)
            spring.fromValue = fromValue
            spring.toValue = toValue
            return spring

        case .interpolatingSpring(let mass, let stiffness, let damping, let initialVelocity):
            let spring = CASpringAnimation(keyPath: keyPath)
            spring.mass = CGFloat(max(0.001, mass))
            spring.stiffness = CGFloat(max(0.001, stiffness))
            spring.damping = CGFloat(max(0.001, damping))
            spring.initialVelocity = CGFloat(initialVelocity)
            spring.duration = max(0.1, spring.settlingDuration)
            spring.fromValue = fromValue
            spring.toValue = toValue
            return spring

        case .linear:
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = nominalDuration
            basic.timingFunction = CAMediaTimingFunction(name: .linear)
            basic.fromValue = fromValue
            basic.toValue = toValue
            return basic

        case .easeIn:
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = nominalDuration
            basic.timingFunction = CAMediaTimingFunction(name: .easeIn)
            basic.fromValue = fromValue
            basic.toValue = toValue
            return basic

        case .easeOut:
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = nominalDuration
            basic.timingFunction = CAMediaTimingFunction(name: .easeOut)
            basic.fromValue = fromValue
            basic.toValue = toValue
            return basic

        case .easeInOut:
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = nominalDuration
            basic.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            basic.fromValue = fromValue
            basic.toValue = toValue
            return basic

        case .cubicBezier(let c1x, let c1y, let c2x, let c2y):
            let basic = CABasicAnimation(keyPath: keyPath)
            basic.duration = nominalDuration
            basic.timingFunction = CAMediaTimingFunction(
                controlPoints: Float(c1x),
                Float(c1y),
                Float(c2x),
                Float(c2y)
            )
            basic.fromValue = fromValue
            basic.toValue = toValue
            return basic
        }
    }

    // MARK: - Keyframe Animation

    /// Binds and starts a keyframe track on a layer property, returning a cancellation token.
    @discardableResult
    public static func animateKeyframes<Value: Sendable>(
        layer: CALayer,
        keyPath: String,
        track: KeyframeTrack<Value>,
        reduceMotion: Bool = false
    ) -> KeyframeAnimationToken {
        let animKey = "prism.keyframe.\(keyPath)"

        guard !reduceMotion, !track.keyframes.isEmpty else {
            if let last = track.keyframes.last {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.setValue(last.value, forKeyPath: keyPath)
                CATransaction.commit()
            }
            return KeyframeAnimationToken(targetLayer: layer, animationKey: animKey)
        }

        let keyframeAnim = CAKeyframeAnimation(keyPath: keyPath)
        keyframeAnim.duration = max(0.01, track.cycleDuration)

        var values: [Any] = []
        var keyTimes: [NSNumber] = []
        var timingFunctions: [CAMediaTimingFunction] = []

        var elapsed = 0.0
        let total = track.cycleDuration

        for kf in track.keyframes {
            values.append(kf.value)
            keyTimes.append(NSNumber(value: total > 0 ? elapsed / total : 0.0))
            elapsed += kf.duration

            switch kf.curve {
            case .easeIn:
                timingFunctions.append(CAMediaTimingFunction(name: .easeIn))
            case .easeOut:
                timingFunctions.append(CAMediaTimingFunction(name: .easeOut))
            case .easeInOut:
                timingFunctions.append(CAMediaTimingFunction(name: .easeInEaseOut))
            case .cubicBezier(let c1x, let c1y, let c2x, let c2y):
                timingFunctions.append(CAMediaTimingFunction(controlPoints: Float(c1x), Float(c1y), Float(c2x), Float(c2y)))
            default:
                timingFunctions.append(CAMediaTimingFunction(name: .linear))
            }
        }

        if let last = track.keyframes.last {
            values.append(last.value)
            keyTimes.append(1.0)
        }

        keyframeAnim.values = values
        keyframeAnim.keyTimes = keyTimes
        keyframeAnim.timingFunctions = timingFunctions
        keyframeAnim.autoreverses = track.autoreverses

        if track.isRepeatForever {
            keyframeAnim.repeatCount = .infinity
        } else if let count = track.repeatCount {
            keyframeAnim.repeatCount = Float(count)
        }

        keyframeAnim.isRemovedOnCompletion = false
        keyframeAnim.fillMode = .forwards

        layer.add(keyframeAnim, forKey: animKey)

        return KeyframeAnimationToken(targetLayer: layer, animationKey: animKey) {
            layer.removeAnimation(forKey: animKey)
        }
    }

    // MARK: - Structural Transitions

    /// Applies an entry transition animation to a mounted layer.
    public static func applyInsertion(
        layer: CALayer,
        effect: Transition.Effect,
        bounds: CGRect,
        animation: Animation?,
        reduceMotion: Bool = false
    ) {
        let resolved = reduceMotion ? effect.reducedMotionFallback : effect
        for atomic in resolved.atomicEffects {
            switch atomic {
            case .opacity(let start):
                animate(
                    layer: layer,
                    keyPath: "opacity",
                    targetValue: Float(1.0),
                    animation: animation,
                    reduceMotion: reduceMotion
                )
                // Set the fromValue by pre-setting opacity
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.opacity = Float(start)
                CATransaction.commit()
                animate(
                    layer: layer,
                    keyPath: "opacity",
                    targetValue: Float(1.0),
                    animation: animation,
                    reduceMotion: reduceMotion
                )

            case .scale(let factor):
                let targetTransform = CATransform3DIdentity
                let initialTransform = CATransform3DMakeScale(CGFloat(factor), CGFloat(factor), 1.0)
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.transform = initialTransform
                CATransaction.commit()
                animate(
                    layer: layer,
                    keyPath: "transform",
                    targetValue: targetTransform,
                    animation: animation,
                    reduceMotion: reduceMotion
                )

            case .move(let edge):
                let initialOffset = offset(for: edge, bounds: bounds)
                let targetPos = layer.position
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.position = CGPoint(x: targetPos.x + initialOffset.x, y: targetPos.y + initialOffset.y)
                CATransaction.commit()
                animate(
                    layer: layer,
                    keyPath: "position",
                    targetValue: targetPos,
                    animation: animation,
                    reduceMotion: reduceMotion
                )

            case .offset(let x, let y):
                let targetPos = layer.position
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.position = CGPoint(x: targetPos.x + CGFloat(x), y: targetPos.y + CGFloat(y))
                CATransaction.commit()
                animate(
                    layer: layer,
                    keyPath: "position",
                    targetValue: targetPos,
                    animation: animation,
                    reduceMotion: reduceMotion
                )

            case .identity, .combined:
                break
            }
        }
    }

    /// Applies an exit transition animation to a mounted layer and executes completion upon finish.
    public static func applyRemoval(
        layer: CALayer,
        effect: Transition.Effect,
        bounds: CGRect,
        animation: Animation?,
        reduceMotion: Bool = false,
        completion: @escaping @MainActor () -> Void
    ) {
        let resolved = reduceMotion ? effect.reducedMotionFallback : effect
        let atomicList = resolved.atomicEffects

        guard !atomicList.isEmpty, let anim = animation, anim.nominalDuration > 0, !reduceMotion else {
            completion()
            return
        }

        var remaining = atomicList.count
        let onOneComplete: @MainActor () -> Void = {
            remaining -= 1
            if remaining <= 0 {
                completion()
            }
        }

        for atomic in atomicList {
            switch atomic {
            case .opacity(let end):
                animate(
                    layer: layer,
                    keyPath: "opacity",
                    targetValue: Float(end),
                    animation: anim,
                    reduceMotion: reduceMotion
                ) { _ in onOneComplete() }

            case .scale(let factor):
                let targetTransform = CATransform3DMakeScale(CGFloat(factor), CGFloat(factor), 1.0)
                animate(
                    layer: layer,
                    keyPath: "transform",
                    targetValue: targetTransform,
                    animation: anim,
                    reduceMotion: reduceMotion
                ) { _ in onOneComplete() }

            case .move(let edge):
                let delta = offset(for: edge, bounds: bounds)
                let targetPos = CGPoint(x: layer.position.x + delta.x, y: layer.position.y + delta.y)
                animate(
                    layer: layer,
                    keyPath: "position",
                    targetValue: targetPos,
                    animation: anim,
                    reduceMotion: reduceMotion
                ) { _ in onOneComplete() }

            case .offset(let x, let y):
                let targetPos = CGPoint(x: layer.position.x + CGFloat(x), y: layer.position.y + CGFloat(y))
                animate(
                    layer: layer,
                    keyPath: "position",
                    targetValue: targetPos,
                    animation: anim,
                    reduceMotion: reduceMotion
                ) { _ in onOneComplete() }

            case .identity, .combined:
                onOneComplete()
            }
        }
    }

    private static func offset(for edge: Transition.TransitionEdge, bounds: CGRect) -> CGPoint {
        switch edge {
        case .top:
            return CGPoint(x: 0, y: -max(50, bounds.height))
        case .bottom:
            return CGPoint(x: 0, y: max(50, bounds.height))
        case .leading:
            return CGPoint(x: -max(50, bounds.width), y: 0)
        case .trailing:
            return CGPoint(x: max(50, bounds.width), y: 0)
        }
    }
}
