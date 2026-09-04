# Metal Effects and Shaders Guide

Prism includes an optional GPU-accelerated Metal backend for rich visual effects composited directly into the CALayer tree.

This guide details effect modifiers, mesh gradients, performance budgeting, and graceful fallback behavior.

---

## Architectural Principles

1. **Zero Framework Leakage:**
   - Public components and modifiers use pure Swift types (`Color`, `Double`, `MeshGradientGrid`).
   - Metal types (`MTLDevice`, `CAMetalLayer`) remain strictly internal implementation details in `PrismCore`.
2. **Optional Backend with Turnkey Fallback:**
   - Metal is optional. If running in environments without Metal (simulators without GPU support, headless CI test runners), Prism automatically falls back to standard `CALayer` approximations without crashing.
3. **Asynchronous Shader Compilation:**
   - Metal pipeline states are compiled asynchronously off the main thread to ensure smooth UI launch times and zero main-thread dropped frames.
4. **Performance Budgets:**
   - GPU frame execution times are measured. Any frame exceeding 16.66ms triggers diagnostic warnings via `PrismLogging.render`.

---

## 1. SDF Rounded Rectangle

Signed Distance Field (SDF) rounded rectangles provide perfectly smooth, anti-aliased borders and corners across Retina and non-Retina displays.

```swift
import PrismUI

VStack(spacing: 8) {
    Text("SDF Card")
    Text("Anti-aliased corner rendering")
}
.padding(16)
.sdfRoundedRect(
    cornerRadius: 24,
    borderWidth: 2.0,
    borderColor: Color(red: 0.35, green: 0.65, blue: 0.95),
    fill: Color(red: 0.1, green: 0.12, blue: 0.18)
)
```

### Fallback Behavior
- When Metal is unavailable, falls back to `CALayer.cornerRadius = cornerRadius`, `CALayer.borderWidth = borderWidth`, `CALayer.borderColor = borderColor.cgColor`, and `CALayer.backgroundColor = fill.cgColor`.

---

## 2. Frosted Glassmorphism

Frosted glass applies real-time blur dispersion, specular highlights, and color saturation adjustments.

```swift
VStack(spacing: 12) {
    Text("Frosted Glass")
    Text("Specular highlights and saturation boost")
}
.padding(20)
.glassmorphism(
    blurRadius: 24,
    tint: Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25),
    saturation: 1.3
)
```

### Fallback Behavior
- When Metal is unavailable, falls back to a tinted semi-transparent overlay layer with a rounded corner radius of 12.0pt.

---

## 3. 2D Mesh Gradient

Renders continuous multi-color gradients interpolated across an $N \times M$ control grid.

```swift
MeshGradient(
    columns: 3,
    rows: 2,
    colors: [
        Color(red: 0.95, green: 0.35, blue: 0.45),
        Color(red: 0.55, green: 0.35, blue: 0.95),
        Color(red: 0.25, green: 0.65, blue: 0.95),
        Color(red: 0.95, green: 0.75, blue: 0.25),
        Color(red: 0.25, green: 0.85, blue: 0.65),
        Color(red: 0.35, green: 0.45, blue: 0.95)
    ],
    height: 160
)
```

### Fallback Behavior
- When Metal is unavailable, falls back to a multi-stop `CAGradientLayer` sampled diagonally between grid corner colors.

---

## 4. Diagnostics & Testing Fallbacks

You can programmatically verify fallback behavior in unit tests or developer debug menus:

```swift
// Simulate unsupported Metal environment
MetalDeviceContext.shared.setSimulatedUnsupported(true)

// Re-enable Metal
MetalDeviceContext.shared.setSimulatedUnsupported(false)
```
