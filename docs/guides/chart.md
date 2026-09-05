# Chart (P3)

Create renderer-neutral series and derive bounded/exportable representations:

```swift
let chart = ChartModel(kind: .line, series: [series])
let renderData = chart.decimated(maxPoints: 2_000)
let table = renderData.accessibilityTable()
let csv = renderData.csv()
```

Non-finite points are removed. `hitTest(x:y:tolerance:)` returns the nearest finite point within tolerance. The accessible table and CSV use the same data as rendering for consistency.

## Extending

Add host renderers behind the model boundary and encode series distinctions with labels/patterns as well as color. Keep export and AX output derived from normalized data.

## Limitations

No native renderer, axes/legend layout, streaming data source, or image export is included. Decimation is endpoint sampling rather than extrema-preserving LTTB.
