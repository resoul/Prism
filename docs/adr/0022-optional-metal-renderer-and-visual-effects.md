# ADR 0022: Optional Metal Renderer and Visual Effects

## Status
Accepted

## Context
High-performance visual effects such as sub-pixel anti-aliased Signed Distance Field (SDF) rounded rectangles, real-time frosted glassmorphism (blur, saturation boost, specular tinting), and multi-point 2D mesh gradients enhance UI aesthetics but impose GPU rendering requirements:
1. **Zero UI Framework & Metal Type Leakage:** In accordance with `MODULE_CONTRACT.md` and `ADR 0001`, public API surfaces must never expose `MTLDevice`, `CAMetalLayer`, `MTLRenderPipelineState`, or other Metal types. All effect configurations must be expressed as pure Swift value types (`Color`, `Double`, `MeshGradientGrid`).
2. **Optional Backend & Graceful Degradation:** Metal must never be a hard requirement for running Prism applications. Headless CI test environments, older virtual machines, or simulator environments without full GPU acceleration must remain 100% functional.
3. **No Main-Thread Blocking:** Shader compilation and pipeline state creation (`makeRenderPipelineState`) can incur noticeable latency and must be executed asynchronously off the main thread.
4. **Clean Resource Lifecycle:** `CAMetalLayer` instances and GPU drawables must release resources immediately upon view unmount or application backgrounding to eliminate memory leaks.

## Decision

1. **Internal Metal Engine in `PrismCore`:**
   - `MetalDeviceContext`: Encapsulates system default `MTLDevice` and `MTLCommandQueue`. Exposes `isSupported` and `setSimulatedUnsupported(_:)` for testing fallback code paths.
   - Asynchronous Pipeline Preparation: `preparePipelinesAsync` compiles MSL source strings into `MetalPipelines` off the main thread with callback notifications.
   - Performance Budgeting: `MetalFrameBudget` records GPU frame durations and emits structured diagnostic warnings if rendering exceeds 16.66ms (targeting 60/120 fps).

2. **Embedded Metal Shading Language (MSL) Shaders:**
   - **SDF Rounded Rectangle:** Signed distance field evaluation computing exact Euclidean distance to rounded rectangular boundaries with sub-pixel anti-aliasing via screen-space derivatives (`fwidth(d)`), configurable corner radii, and inner border strokes.
   - **Glassmorphism / Frosted Blur:** Fragment shader simulating frosted glass with specular top-edge dispersion, saturation adjustment, and tint blending.
   - **Mesh Gradient:** 2D grid bicubic/bilinear spline interpolation evaluating smooth color transitions between control points across unit coordinates.

3. **`MetalLayer` & `LayerRenderer` Compositing:**
   - `MetalLayer`: Wraps `CAMetalLayer`, configures `.bgra8Unorm` pixel format, sRGB color space, Retina `contentsScale`, dynamic `drawableSize` resize handling, and `purgeResources()` on unmount.
   - `MetalEffectRenderer`: Implements `LayerRenderer`. When Metal is available, renders via `MetalLayer`. When Metal is unsupported or disabled, falls back cleanly to pure `CALayer` representations:
     - SDF -> `rootLayer.cornerRadius`, `borderWidth`, `borderColor`, `backgroundColor`.
     - Glassmorphism -> tinted semi-transparent overlay with rounded corners.
     - Mesh Gradient -> multi-stop `CAGradientLayer`.
   - `ContainerRenderer`: Seamlessly integrates `MetalEffectRenderer` as a background layer beneath child elements.

4. **Declarative Public Modifiers & Components in `PrismUI`:**
   - `MeshGradient`: Public declarative component accepting grid dimensions and colors.
   - Modifiers: `.sdfRoundedRect(...)`, `.glassmorphism(...)`, and `.meshGradient(...)` extending `Component` and `RenderElement`.
   - `MetalEffectsDemo`: Demonstration scene showing cards, gradients, and live fallback simulation.

## Consequences
- **Positive:** Advanced GPU visual effects without leaking Metal framework types into public APIs.
- **Positive:** 100% testable and runnable on headless machines and non-Metal platforms via documented CALayer fallbacks.
- **Positive:** Zero main-thread shader compilation stutters.
- **Positive:** Bounded GPU frame budgeting with structured diagnostic logging.
