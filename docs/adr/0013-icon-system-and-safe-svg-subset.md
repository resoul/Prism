# ADR 0013: Icon System and Safe SVG Subset

## Status
Accepted

## Context
Prism applications require icons from various sources: Apple system symbols (SF Symbols), custom vector SVG assets, pre-compiled `CGPath` vectors, and raster fallback images. Prior to this ADR, icons were represented by temporary placeholder nodes with no rendering pipeline or cross-platform vector abstraction.

Key architectural and security challenges:
1. **No platform UI leaks:** SF Symbols require platform frameworks (`AppKit` on macOS, `UIKit` on iOS) to configure and render symbols. Exposing `NSImage`, `UIImage`, or `UIFont.Weight` violates `MODULE_CONTRACT.md` and ADR 0001.
2. **SVG XML vulnerabilities & attack surface:** General SVG parsers are susceptible to XML Entity Expansion (billion laughs attack), Server-Side Request Forgery (SSRF) via external entity references (`<!ENTITY>`, `xlink:href`), script execution (`<script>` tags, event handlers), embedded HTML (`<foreignObject>`), and performance degradation from complex filters or text layout.
3. **Layer rendering efficiency:** Vector icons must be rendered sharply at any DPI/scale without pixelation, leveraging GPU-accelerated `CAShapeLayer` hierarchies for vectors, while using bitmap-cached `CALayer.contents` for system symbol rasters.
4. **Caching & disk invalidation:** Parsing SVG XML and generating vector path hierarchies incurs CPU overhead. Parsed `SVGDocument` instances must be cached in memory with bounded eviction and automatically invalidated when files are modified on disk.
5. **Asset management & icon packs:** Application and design systems need a central registry (`IconRegistry`) to register named bundles, asset directories, and collision resolution policies (`.overwrite`, `.ignore`, `.error`).

## Decision
1. **Unified `IconSource` and Modifiers (`Sources/PrismCore/VRT/IconSource.swift`):**
   - Public enumeration: `.sf(name:)`, `.svg(named:bundle:)`, `.svgURL(URL)`, `.path(CGPath, viewBox: CGRect)`, and `.raster(named:bundle:)`.
   - Semantic size tokens: `IconSize` (`.xs`: 12pt, `.sm`: 16pt, `.md`: 20pt, `.lg`: 24pt, `.xl`: 32pt, `.custom(Double)`).
   - Semantic weight tokens: `IconWeight` (`.ultraLight` through `.black`).
   - Colorization modes: `IconRenderingMode` (`.monochrome`, `.multicolor`, `.hierarchical`).
   - Declarative modifiers on `RenderElement` and `Component`: `.iconSize()`, `.iconColor()`, `.iconWeight()`, `.renderingMode()`.

2. **Safe XML Parser for SVG Subset (`Sources/PrismCore/Icons/SVGParser.swift`, `SVGPathParser.swift`, `SVGTypes.swift`):**
   - Supports safe SVG vector primitives: `<path>`, `<rect>`, `<circle>`, `<ellipse>`, `<line>`, `<polyline>`, `<polygon>`, `<g>`, `viewBox`, fill, stroke, stroke-width, opacity, and 2D affine transforms.
   - Robust path data parser conforming to W3C path commands: `M, m, L, l, H, h, V, v, C, c, S, s, Q, q, T, t, A, a, Z, z` with elliptical arc to cubic bezier subdivision.
   - **Strict Security Guarantees:**
     - XML parser disables external entity resolution (`shouldResolveExternalEntities = false`).
     - Rejects `<script>`, `<style>`, `<foreignObject>`, `<filter>`, `<text>`, and `<tspan>` elements, recording structured `SVGDiagnostic` entries and throwing `SVGError.securityViolation`.
     - Rejects external URI references (`http://`, `https://`, `ftp://`, `data:`) in attributes.

3. **Platform-Internal SF Symbol Bridge (`Sources/PrismCore/Icons/SFSymbolAdapter.swift`):**
   - Uses conditional compilation (`#if canImport(AppKit) ... #elseif canImport(UIKit)`) to render SF Symbols into a `CGImage` bitmap.
   - Maps platform-neutral `IconWeight` to `NSFont.Weight` or `UIImage.SymbolWeight`.
   - Applies palette tinting via `NSImage.SymbolConfiguration` or `UIImage.SymbolConfiguration`.
   - Never exposes platform types across package boundaries.

4. **GPU Vector Rendering Pipeline (`Sources/PrismCore/Rendering/IconRenderer.swift`):**
   - Conforms to `LayerRenderer` and integrated into `RendererFactory`.
   - For vector paths and SVGs: decomposes `SVGDocument` into `CAShapeLayer` sublayers transformed by `aspectFit` into target layout bounds.
   - For SF Symbols and raster assets: sets `rootLayer.contents = cgImage` with `.resizeAspect` contents gravity.
   - Layout integration: `LayoutTreeBuilder` assigns fixed layout dimensions or intrinsic size from `iconSize` token / custom dimension (defaulting to 20pt).

5. **Thread-Safe Caching & Registration (`Sources/PrismCore/Icons/IconCache.swift`, `IconRegistry.swift`):**
   - `IconCache`: thread-safe `NSCache` with bounded capacity, invalidating entries when `FileManager` modification date changes on disk.
   - `IconRegistry`: central manager for icon packs and directories supporting collision handling policies (`.overwrite`, `.ignore`, `.error`).

6. **Component Primitive (`Sources/PrismUI/Primitives/Icon.swift`):**
   - High-level `Icon` component supporting direct source initialization, convenience SF Symbol lookup, and static factory helpers (`Icon.sf(...)`, `Icon.svg(...)`, `Icon.path(...)`).

## Consequences
- **Positive:** Developers have a unified, cross-platform icon API supporting SF Symbols and custom SVGs with standard design token modifiers.
- **Positive:** Zero vulnerability to external XML entity attacks, malicious script execution, or network leaks.
- **Positive:** Sharp vector rendering via GPU-accelerated `CAShapeLayer` without rasterization artifacts on high-DPI displays.
- **Positive:** Pure CoreGraphics / QuartzCore abstraction ensures zero UIKit/AppKit leaks into public headers.
- **Trade-off:** Complex SVG features (CSS animations, text layout, filters, external fonts) are deliberately rejected in favor of security and determinism. Text must be rendered using Prism's native `Text` primitive.
