# CALayer Rendering Pipeline & Ownership Guide

This guide explains how Prism mounts layout calculations onto Apple platform display layers using pure `CALayer` hierarchies, CoreText, and idempotent renderer trees.

---

## 1. Architectural Overview

Prism decouples component declarations and layout geometry from the host display system:

```
┌────────────────────────┐
│ Virtual Render Tree    │ (Pure Sendable immutable value types: RenderElement)
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Layout Engine          │ (Two-pass FlexSolver: LayoutFrame, MeasuredSize)
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ CALayer Renderers      │ (@MainActor: ContainerRenderer, ShapeRenderer, TextRenderer)
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Core Animation Subtree │ (CALayer, CATextLayer with zero implicit animations)
└────────────────────────┘
```

---

## 2. Core Concepts

### LayerRenderer Protocol

Every mounted visual node conforms to `LayerRenderer`:

```swift
@MainActor
public protocol LayerRenderer: AnyObject {
    var elementID: ElementID { get }
    var rootLayer: CALayer { get }
    func update(element: RenderElement, frame: LayoutFrame, context: RenderContext)
    func destroy()
}
```

### Renderer Kinds

- **`ContainerRenderer`**: Manages parent containers (e.g. `Stack`), manages child renderers indexed by `ElementID`, and deterministically sorts sublayers by `zPosition`.
- **`ShapeRenderer`**: Directly configures `CALayer` for `Rectangle` (with `cornerRadius`) and `Circle`.
- **`TextRenderer`**: Employs `CATextLayer` with CoreText `CTFont`, `NSAttributedString`, wrapping, alignment, and display scale factor.

---

## 3. Suppressing Implicit Core Animation Actions

By default, Core Animation plays a 0.25s implicit animation when modifying `CALayer.position`, `bounds`, or `backgroundColor`. Prism suppresses these during layout passes:

```swift
RenderTransaction.perform(disableActions: true) {
    rootLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    rootLayer.position = CGPoint(
        x: frame.origin.x + frame.width / 2.0,
        y: frame.origin.y + frame.height / 2.0
    )
}
```

---

## 4. Idempotent Child Updates & Zero Leaks

`ContainerRenderer.updateChildren` synchronizes child renderers against the target element hierarchy:

```swift
// Existing renderers for known ElementIDs are reused in-place
if let existing = childRenderers[id] {
    renderer = existing
} else {
    renderer = RendererFactory.create(for: childElement)
    rootLayer.addSublayer(renderer.rootLayer)
}
renderer.update(element: childElement, frame: childFrame, context: context)
```

Unused child renderers are pruned with `destroy()`, detaching their layers from `superlayer`.

---

## 5. Diagnostics & Offscreen Detection

Use `LayerDiagnostics` to inspect the mounted hierarchy and prevent performance regressions:

```swift
let totalLayers = LayerDiagnostics.totalLayerCount(container.rootLayer)
let treeDump = LayerDiagnostics.dumpLayerTree(container.rootLayer)
let hasOffscreenHazard = LayerDiagnostics.hasOffscreenRenderingHazard(layer)
```

Offscreen rendering hazard is detected when both clipping (`masksToBounds == true`) and active shadows (`shadowOpacity > 0`) coexist on the same layer.
