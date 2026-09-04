# ADR 0007: CALayer Rendering Pipeline, Node Ownership, and Implicit Action Suppression

## Status
Accepted

## Context
Prism renders declarative Virtual Render Tree (VRT) nodes and layout frames onto Apple platforms with 60/120 fps smoothness, zero layout jank, and minimal memory footprint. Direct usage of UIKit or AppKit view hierarchies introduces unnecessary object allocations and complex lifecycle baggage. Meanwhile, unchecked Core Animation layer manipulation introduces unwanted implicit animations on bounds/position updates and GPU offscreen-rendering hazards.

## Decision
1. **Direct CALayer Hierarchy Ownership:**
   - Rendering uses lightweight `CALayer` and `CATextLayer` objects directly without wrapping them in `UIView` or `NSView`.
   - Each `LayerRenderer` manages a root `CALayer` and synchronizes child renderers keyed by deterministic `ElementID`.
2. **MainActor Boundary:**
   - All layer creation, mutation, and teardown must occur strictly on `@MainActor`.
3. **Suppression of Implicit Core Animation Actions:**
   - All frame updates, bounds adjustments, and property assignments are wrapped in `RenderTransaction.perform(disableActions: true)`. This eliminates accidental implicit slide/fade animations during layout passes while preserving an explicit hook for animated transitions.
4. **CATextLayer & CoreText Typography:**
   - Text rendering uses `CATextLayer` configured with `CTFont`, `NSAttributedString`, and explicit `contentsScale` mapped from `RenderContext.scaleFactor` to ensure sharp rendering on Retina and Super Retina displays.
5. **Renderer Diagnostics & Offscreen Detection:**
   - `LayerDiagnostics` provides recursive layer counting, formatted layer tree dumps, and warns about GPU offscreen rendering hazards (such as combining `masksToBounds` with layer shadows).
6. **Zero Duplicate Layer Guarantee:**
   - `ContainerRenderer.updateChildren` reuses existing child renderers across render passes by matching `ElementID`, guaranteeing zero duplicate layers and zero leaks across repeated renders of unchanged trees.

## Consequences
- **Positive:** High rendering throughput with near-zero overhead and deterministic visual updates.
- **Positive:** No UIKit or AppKit types exposed in public API contracts.
- **Positive:** Zero layer count inflation during steady-state rendering.
- **Trade-off:** Advanced vector paths outside of rectangles and circles require dedicated sub-renderers in future tasks.
