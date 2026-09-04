# Prism Layout Engine: Constraints, Sizing & Leaf Measurement Guide

Prism implements a high-performance, two-pass layout engine inspired by modern flexbox models and desktop layout architectures. It is completely decoupled from platform views and `CALayer`.

---

## 1. The Two-Pass Layout Architecture

Layout execution proceeds in two strictly sequential phases:

```text
┌────────────────────────────────────────────────────────┐
│ 1. Measure Pass (Bottom-Up)                            │
│ Parent offers SizeConstraint (width, height)           │
│ Child computes and returns MeasuredSize (w, h)         │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│ 2. Layout Pass (Top-Down)                              │
│ Parent assigns LayoutFrame (origin, size)              │
│ Node applies PixelRoundingPolicy and positions children│
└────────────────────────────────────────────────────────┘
```

1. **Pass 1: Measure (Bottom-Up)**:
   - A parent presents a `SizeConstraint` (available space) to each child.
   - Leaves (e.g. `Text`, `Shape`, `Spacer`) or containers compute their preferred dimensions (`MeasuredSize`).
   - Results are cached on `LayoutNode.measuredSize`.
2. **Pass 2: Layout (Top-Down)**:
   - The parent assigns a concrete `LayoutFrame` (`origin`, `size`) to each child.
   - Coordinates are snapped to physical device pixels according to `PixelRoundingPolicy`.
   - The node is marked with `LayoutInvalidationState.clean`.

---

## 2. Parent Dimension Constraints (`DimensionConstraint`)

Parent space is modeled as one of three states per axis:

| Constraint | Semantics | Typical Context |
|---|---|---|
| `.unspecified` | Unbounded available space. Child sizes intrinsically. | Inside `ScrollView`, horizontal tags, or unconstrained axes. |
| `.atMost(Double)` | Upper bound limit. Child may choose any size up to this bound. | Column with maximum width, window viewport bound. |
| `.exactly(Double)` | Strict exact size enforced by parent. | Stretched cross-axis, fixed parent container. |

### Invariant: Unconstrained Space is NOT Zero Space
> [!IMPORTANT]
> `.unspecified` indicates that the parent places no restrictions on child size. It must never be treated as `0`. A child with `.fill` or `.fraction` collapses to its intrinsic size (or 0 if empty) when measured under `.unspecified` space.

---

## 3. Element Size Values (`SizeValue`)

Elements declare sizing intent via `LayoutStyle`:

- **`.fixed(Double)`**: Explicit dimension in points (e.g. `.fixed(120)`).
- **`.fraction(Double)`**: Percentage of available parent space (e.g. `.fraction(0.5)` for 50%).
- **`.intrinsic`**: Sized according to content metrics (e.g. text bounds or natural shape size).
- **`.fill`**: Expands to take all available space (`atMost` or `exactly`).
- **`.range(min: Double?, max: Double?)`**: Bounds intrinsic size within specified limits.

---

## 4. Min/Max Clamping & Conflict Resolution

When `minWidth` / `minHeight` or `maxWidth` / `maxHeight` bounds are specified:
$$\text{Clamped} = \max(\text{minBound}, \min(\text{maxBound}, \text{Target}))$$

### Conflict Resolution Rule: `min` Wins Over `max`
> [!CAUTION]
> If a configuration specifies conflicting bounds where `minBound > maxBound` (e.g., `minWidth: 80` but `maxWidth: 50`):
> **`minBound` takes precedence.**
> 
> This invariant guarantees that critical accessibility touch targets (e.g. 44x44 pt) and text legibility thresholds are never violated by secondary container caps.

---

## 5. CoreText Leaf Measurement (`TextMeasurePolicy`)

Text measurement is executed headlessly using `CoreText`:

- **Empty Strings**: Return `MeasuredSize(0, 0)` immediately with zero allocation.
- **Single Line Text**: Computes precise typographical bounding boxes using `CTFramesetterSuggestFrameSizeWithConstraints`.
- **Multi-Line Text**: Automatically wraps when `constraint.width` specifies `.atMost` or `.exactly`.
- **Line Limit (`lineLimit`)**: Caps the maximum line count and calculates truncated height.
- **Custom Line Height**: Respects `customLineHeight` settings via `CTParagraphStyle`.
- **Unicode & Emoji**: Handles multi-byte UTF-8/16 scripts, bidirectional text, and compound family emojis reliably without NaN or negative bounds.

---

## 6. Pixel Rounding Policy (`PixelRoundingPolicy`)

To prevent subpixel rendering artifacts, hairline seams, and blurry text:

- `scaleFactor`: Configured for screen scale (`1.0` for 1x, `2.0` for 2x Retina, `3.0` for 3x Super Retina).
- Frame origins are rounded to the nearest device pixel.
- Frame widths and heights are rounded up (`ceil`) to device pixels to ensure content is never clipped.

---

## 7. Invalidation Lifecycle

`LayoutNode` maintains an explicit invalidation state:

```text
               ┌─────────────────────────────────┐
               │    .measureInvalidated          │
               │ (Style, Content, or Tree change)│
               └────────────────┬────────────────┘
                                │ measure()
                                ▼
               ┌─────────────────────────────────┐
               │     .layoutInvalidated          │
               │ (Measure cached, Frame pending) │
               └────────────────┬────────────────┘
                                │ layout()
                                ▼
               ┌─────────────────────────────────┐
               │            .clean               │
               │ (Both passes cached & up-to-date)│
               └─────────────────────────────────┘
```

- **`invalidateMeasure()`**: Clears `measuredSize` and `layoutFrame`. Triggers both measure and layout passes on the next frame.
- **`invalidateLayout()`**: Retains valid `measuredSize` cache; only re-runs the top-down layout pass.
