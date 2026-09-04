# ADR 0004: Virtual Render Tree (VRT) & Declarative Component API

## Status
Accepted

## Context
A cross-platform UI engine requires a declarative composition model for authoring views without directly coupling the authoring surface to heavy, mutable platform graphics objects (`CALayer`, `UIView`, `NSView`).

Directly creating and modifying layers during view evaluation leads to expensive layout churn, memory overhead, complex state invalidation, and severe difficulties in testing view output deterministically off the main thread.

## Decision
1. **Immutable Virtual Render Tree (`RenderElement`):**
   - The primary result of component evaluation is an immutable value type (`RenderElement`).
   - `RenderElement` holds zero references to `CALayer`, `UIView`, `NSView`, or platform host objects.
   - It is safe to evaluate, copy, transform, and inspect on any thread.
2. **Three-Tuple Element Identity:**
   - Identity is defined as: `(typeName, key, siblingIndex)`.
   - Collections require explicit, stable keys for dynamic data to guarantee state persistence and stable animations across reordering. Array index as identity is strictly forbidden for dynamic collections.
3. **Declarative Component Model & Result Builder:**
   - User components conform to `Component` and implement `body(context: ComponentContext) -> RenderElement`.
   - `@resultBuilder ComponentBuilder` provides declarative syntax supporting conditionals, optional unwrapping, loops, and structural grouping.
4. **Structural Primitives (`Group`, `Empty`):**
   - `Group` is inlined during tree normalization without creating intermediate container or layout nodes.
   - `Empty` represents the complete absence of visual or layout footprint.
5. **Deterministic Modifier Pipeline:**
   - Modifiers follow value semantics (copy-on-write).
   - Paddings and margins accumulate (`outer + inner`).
   - Frame dimensions override previous dimensions (`later wins`).
   - Opacity composites multiplicatively (`outer * inner`, clamped to `[0.0, 1.0]`).

## Alternatives Considered
- **Direct CALayer Tree Construction:** Rejected. Causes significant main thread contention, makes headless testing impossible, and makes diff-based reconciliation impractical.
- **Dynamic AnyObject Attribute Dictionaries:** Rejected in favor of typed `ElementKind` and structured `ElementProps`/`ElementModifier` to preserve compile-time safety and high-performance layout decoding.

## Consequences
- **Positive:** Components can be rendered and tested headlessly without window servers or platform host views.
- **Positive:** Reconcilers (Task 08) can diff two pure value trees in parallel before committing layer changes on the MainActor.
- **Trade-off:** Requires a normalization and mounting step to translate `RenderElement` trees into layout nodes and CALayers.
