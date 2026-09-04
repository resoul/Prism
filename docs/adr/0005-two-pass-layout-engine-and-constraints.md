# ADR 0005: Two-Pass Layout Engine Architecture & Constraint Resolution

## Status
Accepted

## Context
A cross-platform UI engine requires a deterministic, highly predictable layout model that handles arbitrary nesting, responsive flex scaling, intrinsic text measurement, and safe bounds clamping.

Naïve single-pass layout algorithms either suffer from layout thrashing (repeatedly querying and resetting layer positions) or fail to resolve interdependent constraints (such as text wrapping within a flex container). Furthermore, floating-point math can introduce `NaN`, negative dimensions, infinite bounds, or subpixel rounding seams.

## Decision
1. **Two-Pass Layout Contract:**
   - **Measure Pass (Bottom-Up):** Parent passes `SizeConstraint` (`width`, `height`), and each node computes its preferred `MeasuredSize`.
   - **Layout Pass (Top-Down):** Parent assigns `LayoutFrame` (`origin`, `size`), positioning children.
2. **Dimension Constraints:**
   - Modeled via `DimensionConstraint`: `.unspecified` (unbounded), `.atMost(Double)` (upper bound), and `.exactly(Double)` (enforced bound).
   - `.unspecified` represents boundless space (e.g. within scroll views) and is strictly distinguished from zero size.
3. **Constraint Resolution & Clamping:**
   - `ConstraintResolver` resolves `SizeValue` against `DimensionConstraint`.
   - Clamping bounds (`min` and `max`) are strictly enforced. In cases of conflicting bounds (`min > max`), `min` takes precedence to safeguard accessibility touch targets and text legibility.
   - Outputs are guaranteed to be finite and non-negative (no `NaN`, no negative values, no infinities).
4. **CoreText Leaf Measurement:**
   - Leaf text measurement uses CoreText (`CTFramesetter`, `CTTypesetter`, `CTLine`) without importing or leaking `UIKit` or `AppKit`.
   - Supports multi-line word wrapping, line limits, custom line heights, and Unicode/emoji.
5. **Pixel Rounding Policy (`PixelRoundingPolicy`):**
   - Coordinates and sizes are snapped to physical device pixels (`1x`, `2x`, `3x`) to prevent hairline seams and blurry text.
6. **Explicit Invalidation Lifecycle:**
   - `LayoutNode` tracks invalidation via `.measureInvalidated`, `.layoutInvalidated`, and `.clean` states to avoid redundant recomputations.

## Consequences
- **Positive:** Layout calculation is pure, predictable, and fully testable headlessly without host windows.
- **Positive:** Foundation is completely ready for the Flexbox Solver in Task 05.
- **Trade-off:** Requires a two-pass traversal on layout updates, mitigated by cached `measuredSize` and invalidation states.
