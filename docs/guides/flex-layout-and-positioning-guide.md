# Prism Flexbox Layout Engine & Positioning Guide

Prism provides a deterministic, high-performance flexbox subset and positioning engine implemented in pure Swift, operating across iOS, macOS, and tvOS without platform dependencies or CALayer ownership during layout computation.

---

## 1. Flex Direction & Axes

Flex containers arrange elements along two perpendicular axes:

- **Main Axis**: Direction of element flow (`direction: .row`, `.column`, `.rowReverse`, `.columnReverse`).
- **Cross Axis**: Perpendicular axis across which alignment and wrapping occur.

```swift
// Row (Horizontal)
VStack {
    HStack(spacing: 12) {
        Rectangle().frame(width: 40, height: 40)
        Text("Item Description")
        Spacer()
        Icon("chevron.right")
    }
}
```

---

## 2. Space Distribution (Grow, Shrink & Gaps)

When extra main-axis space is available, or when child elements overflow the container:

### `flexGrow`
Distributes available free space proportionally among flexible children:
$$\text{ChildMain} = \text{BaseMain} + \text{FreeSpace} \times \frac{\text{child.flexGrow}}{\sum \text{flexGrow}}$$

```swift
// Two columns sharing free space in a 1:2 ratio
HStack {
    Sidebar().layoutStyle(flexGrow: 1.0)
    MainContent().layoutStyle(flexGrow: 2.0)
}
```

### `flexShrink`
Absorbs overflow space proportionally when items exceed container boundaries:
$$\text{Reduction} = \text{Overflow} \times \frac{\text{child.flexShrink} \times \text{BaseMain}}{\sum (\text{flexShrink} \times \text{BaseMain})}$$

---

## 3. Alignment (`justifyContent` & `alignItems`)

### Main Axis: `justifyContent`
Governs how items and remaining space are positioned along the primary flow axis:

- `.start`: Packed at the beginning of the container.
- `.center`: Centered along the main axis.
- `.end`: Packed at the end of the container.
- `.spaceBetween`: First item at start, last item at end, equal spacing between.
- `.spaceAround`: Equal space distributed on both sides of each item.
- `.spaceEvenly`: Equal spacing between all items and container edges.

### Cross Axis: `alignItems` & `alignSelf`
Governs alignment of children across the cross axis:

- `.start`: Aligned to the start edge of the cross axis.
- `.center`: Centered across the cross axis.
- `.end`: Aligned to the end edge of the cross axis.
- `.stretch`: Expands children to match container cross dimension (unless fixed cross size is set).
- `.baseline`: Aligned according to first typographical text baseline.

---

## 4. Multi-Line Flex Wrapping (`flexWrap`)

When `flexWrap: .wrap` is enabled:
1. Items overflowing the container's main dimension automatically wrap onto a new line.
2. Each line's cross size is determined by the maximum cross dimension of its items.
3. Lines are spaced along the cross axis using `crossGap`.

```swift
// Tag cloud wrapping across lines
LayoutNode(
    id: ElementID(typeName: "TagCloud"),
    style: LayoutStyle(
        direction: .row,
        flexWrap: .wrap,
        gap: 8,
        crossGap: 10
    ),
    children: tags
)
```

---

## 5. Positioning Models: Flow vs Absolute vs Fixed

Prism cleanly separates flow layout from out-of-flow overlays:

| Position Type | Participates in Flow Size? | Containing Block | Offsets Applied |
|---|---|---|---|
| `.flow` | **Yes** | Enclosing container | None (managed by flex solver) |
| `.absolute` | **No** | Enclosing container content box | `top`, `leading`, `bottom`, `trailing` |
| `.fixed` | **No** | Root window / viewport | `top`, `leading`, `bottom`, `trailing` |

### Absolute Positioning Rules
- `.absolute` children do **not** contribute to their parent's measured dimensions.
- They are positioned after the main flex pass relative to the container's padding box.
- Specifying both `leading` and `trailing` or `top` and `bottom` stretches the element between the two edges.
- `zIndex` determines stacking order.

---

## 6. Layout Trace Inspection (`dumpTrace()`)

Every layout hierarchy can output an actionable diagnostic trace:

```swift
print(rootNode.dumpTrace())
```

Example output:
```text
Node(RootStack@0) frame: (0.0, 0.0, 320.0, 100.0) desired: (320.0, 100.0) {dir: column, gap: 8.0}
  ├── Node(Title@0) frame: (0.0, 0.0, 120.0, 24.0) desired: (120.0, 24.0)
  └── Node(Badge@1) frame: (280.0, 10.0, 30.0, 20.0) [absolute] {pos: absolute, z: 10}
```
