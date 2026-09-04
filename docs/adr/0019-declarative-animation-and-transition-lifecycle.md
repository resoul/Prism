# ADR 0019: Declarative Animation and Transition Lifecycle

## Status
Accepted

## Context
High-performance cross-platform UI engines require declarative value and structural animations that operate seamlessly with tree reconciliation, hardware acceleration, and accessibility.

Key technical challenges in declarative UI animation systems include:
1. **Model vs. Presentation Layer Drift:** In Core Animation, attaching implicit or naively configured explicit animations often results in presentation layers snapping back to old model values upon animation completion or interruption ("jump-back" glitches).
2. **Premature Removal in Reconciliation:** When state changes remove an element from the virtual render tree, standard reconcilers immediately unmount the child, destroy its layer, and detach event listeners. If an exit transition is attached, the element disappears instantly before the exit animation can be perceived.
3. **Interrupted Transitions & Node Resurrection:** If an element is in the process of transitioning out and state changes immediately re-insert it (e.g. rapid user toggling or state bouncing), naively tearing down and re-creating layers introduces flickering, duplicate nodes, or dangling orphan layers.
4. **Accessibility Violations (Reduce Motion):** Hardcoded animations across components cause discomfort for users with vestibular disorders unless motion reduction is handled systematically at the engine level without manual component boilerplate.

## Decision

1. **Declarative Value Primitives (`Animation`):**
   - Pure Swift value types (`Animation`, `TimingCurve`) modeling standard curves (`.linear`, `.easeIn`, `.easeOut`, `.easeInOut`, `.timingCurve`), physically-based springs (`.spring`, `.bouncy`, `.snappy`, `.smooth`, `.interpolatingSpring`), and timing modifiers (`.delay`, `.speed`, `.repeatCount`, `.repeatForever`).
   - Zero QuartzCore types exposed in public APIs.

2. **Ambient Transaction Scoping (`Transaction` & `withAnimation`):**
   - `@TaskLocal` and `@MainActor` transaction context.
   - `withAnimation` scopes state mutations to an active transaction.
   - Nested transaction rules: inner transactions override outer animations; `disablesAnimations: true` explicitly suppresses all child animations.

3. **Zero Model Drift Layer Animation Bridge (`LayerAnimationBridge`):**
   - Immediate Model Synchronization: Prior to attaching an explicit `CAAnimation`, the target value is immediately committed to the layer model under an actions-disabled `CATransaction` (`CATransaction.setDisableActions(true)`).
   - In-Flight Continuity: `fromValue` is sampled from `layer.presentation()?.value(forKeyPath:) ?? layer.value(forKeyPath:)`.
   - `CAAnimation` is configured with `isRemovedOnCompletion = true` and `fillMode = .removed`. Upon completion or interruption, the presentation layer reveals the model layer that already contains the final target value with zero visual discontinuity.

4. **Reconciler Deferred Removal & Node Resurrection:**
   - When `Reconciler.diff` marks a node for removal:
     - If the node has an active transition or transaction animation, `node.unmount()` is deferred.
     - The node is retained in `parent.animatingOutChildren` while retaining its `rootLayer` in the hierarchy.
     - An exit transition (`LayerAnimationBridge.applyRemoval`) is executed.
     - If the animation completes without interruption, `node.unmount()` is called and the layer is detached.
     - If the node is re-inserted while animating out, `parent.animatingOutChildren` resurrects the existing `MountedNode`, cancels the exit animation, and runs the entry transition without allocating duplicate layers.

5. **Universal Reduce Motion Adaptation:**
   - `ReduceMotionPreference` inspects environment and transaction flags.
   - When active, animations collapse to zero duration, and spatial transitions (`.slide`, `.move`, `.scale`) automatically fall back to an accessible crossfade (`.opacity`) without requiring manual boilerplate inside individual components.

6. **Diagnostics & Telemetry (`AnimationInspector`):**
   - Telemetry tracks transaction IDs, active layer animation counts, and transition lifecycle events.

## Consequences
- **Positive:** Smooth 60fps hardware-accelerated animations across iOS and macOS with deterministic reconciliation lifecycles.
- **Positive:** Zero presentation/model layer drift on completion or interruption.
- **Positive:** Clean structural transitions with safe deferred unmount and interruption resurrection.
- **Positive:** Out-of-the-box accessibility compliance with automatic Reduce Motion fallback.
