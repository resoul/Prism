# ADR 0006: Flexbox Layout Engine & Multi-Model Positioning

## Status
Accepted

## Context
Building responsive and platform-agnostic user interfaces on iOS, macOS, and tvOS requires a comprehensive flexbox model that supports directional flow, space distribution (grow/shrink), alignment along main and cross axes, multi-line wrapping, and overlays without coupling the layout pass to platform frameworks.

## Decision
1. **Deterministic Flexbox Subset:**
   - **Main Axis Flow:** Direction (`row`, `column`, `rowReverse`, `columnReverse`), gaps, and `justifyContent` (`start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly`).
   - **Cross Axis Flow:** Alignment via `alignItems` and `alignSelf` (`start`, `center`, `end`, `stretch`, `baseline`).
   - **Space Distribution:** Flexible space distributed proportionally using `flexGrow`; overflow absorbed proportionally using `flexShrink`.
2. **Multi-Line Flex Wrapping:**
   - `flexWrap: .wrap` partitions items into lines when content exceeds available main space. Lines are spaced along the cross axis using `crossGap`.
3. **Multi-Model Positioning:**
   - `.flow`: Standard flex participation.
   - `.absolute`: Positioned relative to the enclosing container's content box using `top`, `leading`, `bottom`, `trailing` offsets. Excluded from flow measurement.
   - `.fixed`: Positioned relative to the root window viewport. Excluded from flow measurement.
   - `zIndex`: Deterministically sets visual stacking order.
4. **Actionable Diagnostics (`LayoutTrace`):**
   - Produces a deterministic string dump of the entire layout tree (frames, constraints, styles, positioning) to debug test and layout regressions.

## Consequences
- **Positive:** P0 primitives (`Stack`, `HStack`, `VStack`, `Spacer`, `Rectangle`, `Circle`, `Text`) layout predictably and responsively.
- **Positive:** Absolute overlays (badges, tooltips, dialog backdrops) do not distort parent flow sizes.
- **Trade-off:** Multi-line wrapping requires line partitioning before cross-axis alignment, adding a pass over wrapped items.
