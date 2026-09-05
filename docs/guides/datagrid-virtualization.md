# DataGrid Virtualization (P3)

Use `DataGridViewport` to calculate bounded cells for a large 2D dataset:

```swift
var grid = DataGridViewport(rows: 100_000, columns: 100)
grid.updateViewport(offsetX: scrollX, offsetY: scrollY, width: width, height: height)
let cells = grid.mountedCells
```

Resize rows/columns through `resizeRow` and `resizeColumn`; pinned headers remain mounted while scrolling. The `scrollAnchor` and `accessibilityCoordinate` expose logical coordinates to host adapters.

## Extending

Map logical row/column indices to stable application IDs and render only `mountedCells`. Persist validated metrics in the consumer and keep editing/sorting in separate models.

## Limitations

This core model does not render cells, provide editing/sorting, or implement a persistence backend. Extent lookup is linear over the configured axis and should be replaced with a tree/Fenwick structure for highly variable million-row datasets.
