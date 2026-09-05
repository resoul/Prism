# Resizable (P3)

Use `ResizableSplit` as the state model for a split-panel host:

```swift
var split = ResizableSplit(ratio: 0.5, minimumRatio: 0.2, maximumRatio: 0.8)
split.beginCapture()
split.updateCapture(delta: dragDelta, availableExtent: width)
split.endCapture() // or cancelCapture()
split.keyboardResize(steps: 1, rtl: isRTL)
```

Ratios are always clamped. Store `ratio` in an app-owned persistence binding when needed; call `cancelCapture()` on pointer cancellation or unmount. The `Resizable` facade exposes separator role and ratio metadata for host AX adapters.

## Extending

Compose independent `ResizableSplit` values for nested panels. Route pointer capture and keyboard events from the host, and persist only validated ratios. Keep continuous resize work within the host frame budget.

## Limitations

This contract does not provide a native divider view, persistence backend, or animated layout interpolation. The facade is a semantic placeholder until a host renderer supplies panel content.
