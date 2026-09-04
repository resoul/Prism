# Icon System and Safe SVG Subset Guide

This guide covers working with icons in Prism: declaring Apple SF Symbols, rendering custom SVG assets, embedding pre-compiled vector paths, configuring design token modifiers, and registering named icon packs.

---

## 1. Icon Sources (`IconSource`)

Prism unifies all vector and bitmap icon sources under the platform-neutral `IconSource` enumeration:

| Source | Case | Example | Description |
| :--- | :--- | :--- | :--- |
| **SF Symbols** | `.sf(name:)` | `.sf(name: "star.fill")` | Apple system symbol rendered via internal platform bridge into `CGImage`. |
| **Custom SVG** | `.svg(named:bundle:)` | `.svg(named: "bell", bundle: "MyAssets")` | Vector SVG asset loaded from registered pack or bundle. |
| **SVG from URL** | `.svgURL(URL)` | `.svgURL(fileURL)` | Direct file URL on disk with automatic cache invalidation. |
| **Compiled Vector** | `.path(CGPath, viewBox:)` | `.path(cgPath, viewBox: rect)` | Pre-compiled vector path scaled with aspect-fit into target layout frame. |
| **Raster Asset** | `.raster(named:bundle:)` | `.raster(named: "logo")` | Bitmap/PDF image fallback asset. |

---

## 2. Using the `Icon` Primitive

In `PrismUI`, use the `Icon` component directly or via its semantic initializers and factories:

```swift
import PrismUI

// 1. SF Symbol (default convenience initializer)
Icon("heart.fill")
    .iconSize(.lg)
    .iconColor(Color.hex("#E11D48"))

// 2. Named custom SVG from registered pack or bundle
Icon.svg("shopping-bag")
    .iconSize(.md)
    .iconColor(Color.hex("#2563EB"))

// 3. SVG directly from a file URL
Icon.svgURL(assetURL)
    .iconSize(32)

// 4. Pre-compiled vector path
Icon.path(customPath, viewBox: CGRect(x: 0, y: 0, width: 24, height: 24))
    .iconSize(.sm)
```

---

## 3. Styling & Modifiers

Icons support standardized modifiers for size, color tinting, stroke weight, and vector colorization modes:

### Size Tokens (`IconSize`)

```swift
Icon("bell")
    .iconSize(.xs)             // 12pt (subtext, badges, dense tables)
    .iconSize(.sm)             // 16pt (inline tags, secondary button actions)
    .iconSize(.md)             // 20pt (standard buttons, form inputs - default)
    .iconSize(.lg)             // 24pt (navigation bars, prominent cards)
    .iconSize(.xl)             // 32pt (hero banners, empty state illustrations)
    .iconSize(.custom(48.0))   // Explicit custom points
    .iconSize(48.0)            // Numeric Double shorthand
```

### Color & Tinting

```swift
Icon("checkmark.circle")
    .iconColor(Color.hex("#10B981"))
```

### Symbol Stroke Weight (`IconWeight`)

Applied to SF Symbols (mapped to `NSFont.Weight` or `UIImage.SymbolWeight` internally):

```swift
Icon("gearshape")
    .iconWeight(.semibold)     // .ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
```

### Rendering Modes (`IconRenderingMode`)

Controls vector colorization:

```swift
// Monochrome (default): Re-tints all vector fills and strokes with iconColor
Icon.svg("flag")
    .renderingMode(.monochrome)
    .iconColor(Color.hex("#3B82F6"))

// Multicolor: Preserves original SVG shape colors declared in the asset
Icon.svg("badge-multicolor")
    .renderingMode(.multicolor)

// Hierarchical: Renders symbol tiers with hierarchical opacity levels
Icon("cloud.sun.rain.fill")
    .renderingMode(.hierarchical)
    .iconColor(Color.hex("#0EA5E9"))
```

---

## 4. Safe SVG Subset & Security

Prism implements a high-performance XML parser for a strictly validated subset of SVG vector graphics.

### Supported Features
- **Shapes:** `<path>`, `<rect>`, `<circle>`, `<ellipse>`, `<line>`, `<polyline>`, `<polygon>`, `<g>`.
- **Attributes:** `viewBox`, `fill`, `fill-opacity`, `fill-rule` (`nonzero`, `evenodd`), `stroke`, `stroke-width`, `stroke-opacity`, `stroke-linecap`, `stroke-linejoin`, `opacity`, and 2D `transform` (`matrix`, `translate`, `scale`, `rotate`, `skewX`, `skewY`).
- **Path commands:** Full W3C path data specification (`M, m, L, l, H, h, V, v, C, c, S, s, Q, q, T, t, A, a, Z, z`).

### Security Rejections & Guarantees
To protect against XML Entity Expansion, Server-Side Request Forgery, and arbitrary code execution:
- XML external entities are disabled (`shouldResolveExternalEntities = false`).
- `<script>` tags immediately throw `SVGError.securityViolation`.
- `<foreignObject>` embedded HTML blocks immediately throw `SVGError.securityViolation`.
- External URI references (`http://`, `https://`, `ftp://`, `data:`) in `href` or `src` attributes are rejected.
- `<style>` CSS stylesheet blocks are ignored with non-fatal diagnostics.
- `<text>` and `<tspan>` tags are rejected (use Prism's native `Text` primitive).

---

## 5. Caching & Memory Management (`IconCache`)

Parsed `SVGDocument` instances are automatically cached in memory via thread-safe `IconCache`:

```swift
// Retrieves from cache, or parses and caches automatically
let doc = IconCache.shared.document(for: fileURL)
```

- **Disk modification invalidation:** If the SVG file on disk is modified, `IconCache` compares the file's modification date and automatically re-parses the fresh asset.
- **Bounded memory:** Bounded via `NSCache` with configurable `countLimit` (default: 500 documents).
- **Manual clear:** `IconCache.shared.clear()` evicts all cached documents.

---

## 6. Icon Registry & Pack Management (`IconRegistry`)

Organize application icon sets into reusable packs or directories:

```swift
// Register an entire folder of SVGs as an icon pack
let assetsDirectory = Bundle.main.bundleURL.appendingPathComponent("Icons")
try IconRegistry.shared.register(pack: "heroicons", directoryURL: assetsDirectory)

// Resolve by pack prefix
let checkIcon = Icon("heroicons/check-circle")

// Register individual custom sources with collision policy
try IconRegistry.shared.register(
    source: .sf(name: "bell.badge.fill"),
    for: "notifications.unread",
    collisionPolicy: .overwrite // .overwrite, .ignore, or .error
)
```
