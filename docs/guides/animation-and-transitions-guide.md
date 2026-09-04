# Declarative Animation & Transitions Guide

This guide covers how to implement value animations, spring curves, structural transitions, and inspect animation telemetry in Prism applications.

---

## 1. Overview

Prism provides a declarative, hardware-accelerated animation system built directly on top of Core Animation. It delivers:
- **Zero Model Drift:** Layer model values are set immediately under an actions-disabled transaction while attaching explicit `CAAnimation` objects, ensuring presentation and model values never diverge upon completion or interruption.
- **Structural Transitions:** Node removal is held mounted in the Virtual Render Tree reconciler until exit transitions complete.
- **Interruption Continuity:** Re-inserting an element mid-exit cancels removal and restores the node seamlessly.
- **Automatic Reduce Motion:** System motion reduction preferences automatically collapse animation durations and convert spatial movements to accessible crossfades.

---

## 2. Animation Primitives & Curves

### Standard Curves

```swift
// Standard timing curves
let linear = Animation.linear(duration: 0.3)
let easeIn = Animation.easeIn(duration: 0.25)
let easeOut = Animation.easeOut(duration: 0.25)
let easeInOut = Animation.easeInOut(duration: 0.35)
let custom = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.4)
```

### Physically-based Springs

```swift
// Harmonic oscillator springs
let spring = Animation.spring(response: 0.55, dampingRatio: 0.825)
let bouncy = Animation.bouncy(duration: 0.5, extraBounce: 0.2)
let snappy = Animation.snappy(duration: 0.4)
let smooth = Animation.smooth(duration: 0.5)

// Precision physics
let physics = Animation.interpolatingSpring(mass: 1.0, stiffness: 120.0, damping: 14.0)
```

### Modifiers

```swift
let loop = Animation.easeInOut(duration: 0.3)
    .delay(0.1)
    .speed(1.5)
    .repeatCount(3, autoreverses: true)

let pulse = Animation.spring()
    .repeatForever(autoreverses: true)
```

---

## 3. Transaction Scoping & withAnimation

State mutations can be animated imperatively using `withAnimation`:

```swift
withAnimation(.spring(response: 0.4, dampingRatio: 0.75)) {
    isExpanded.value.toggle()
}
```

### Nested & Disabled Transactions

```swift
// Suppressing all child animations
withTransaction(Transaction(disablesAnimations: true)) {
    // Immediate state update with zero animation
    selectedIndex.value = newIndex
}
```

---

## 4. Structural Transitions

Attach enter/exit visual transitions to elements:

```swift
// Predefined transitions
Card { ... }
    .transition(.opacity)

Card { ... }
    .transition(.scale(0.8))

Card { ... }
    .transition(.slide)

// Combined transitions
Card { ... }
    .transition(.opacity.combined(with: .scale(0.9)))

// Asymmetric transitions
Card { ... }
    .transition(.asymmetric(insertion: .slide, removal: .opacity))
```

### Reconciler Retention & Resurrection

When an element with a `.transition` modifier is removed from the hierarchy:
1. The node is moved to the parent's `animatingOutChildren` registry.
2. The exit transition runs to completion while holding the `CALayer` mounted.
3. Upon completion, the node is cleanly unmounted.
4. If state changes re-insert the element before the exit finishes, Prism resurrects the existing node and cancels the exit animation, preventing duplicate layer creation or visual flicker.

---

## 5. Accessibility: Reduce Motion

Prism automatically respects the `Reduce Motion` accessibility setting:
- Animation durations collapse to zero for instant state transitions.
- Physical spatial transitions (`.slide`, `.move`, `.scale`) automatically resolve to a gentle crossfade (`.opacity`) to prevent vestibular discomfort.
- Components require no manual `if reduceMotion` branches.

---

## 6. Animation Inspector & Diagnostics

Prism includes real-time telemetry diagnostics via `AnimationInspector`:

```swift
// Inspect active transaction ID, running layer animations, and lifecycle logs
AnimationInspector(isVisible: true)
```
