# Scroll Engine, Virtualization, and Async Image Pipeline Guide

This guide describes how to build high-performance scrolling containers, virtualized collections (`LazyList`, `LazyGrid`), and asynchronously loaded, downsampled images using Prism.

---

## 1. Declarative Scrolling (`ScrollArea`)

`ScrollArea` provides viewport clipping, momentum scrolling, and programmatic coordinate targeting without exposing platform-specific UI controls.

```swift
import PrismUI

ScrollArea(.vertical, bounces: true) { proxy in
    VStack(spacing: 16) {
        Button("Jump to Section 2") {
            proxy.scrollTo("section-2", anchor: .top)
        }

        HeaderView("Section 1").pinnedHeader()
        ContentBlock()

        HeaderView("Section 2").scrollTarget(id: "section-2")
        MoreContent()
    }
}
```

### Features & Capabilities
- **Programmatic Scrolling:** Use `ScrollProxy` to invoke `scrollTo(offset)` or `scrollTo(id:anchor:)` with `.top`, `.center`, or `.bottom` alignment.
- **Pinned Headers:** Mark subviews with `.pinnedHeader()` to keep them anchored at the top of the viewport during scrolling.
- **Scroll Target Anchors:** Mark any subview with `.scrollTarget(id:)` to establish a target for `ScrollProxy`.
- **Pull to Refresh:** Supply an `async` refresh closure via `.pullToRefresh { await refreshData() }`.
- **Scroll State Observation:** Receive real-time updates through `onScroll: { position in ... }`.

---

## 2. Keyed Virtualized Collections (`LazyList` & `LazyGrid`)

When rendering datasets with thousands of items, mounting all views simultaneously degrades memory and GPU performance. `LazyList` and `LazyGrid` calculate visible and overscan windows to only instantiate and render items currently near the viewport.

### Virtualized Vertical List (`LazyList`)

```swift
LazyList(items, id: \.id, estimatedItemLength: 48.0) { item in
    UserRow(item: item)
}
.prefetch(distance: 10) {
    store.loadNextPage()
}
```

### Virtualized Grid (`LazyGrid`)

```swift
LazyGrid(
    columns: .adaptive(minWidth: 150),
    data: products,
    id: \.id,
    spacing: 12.0,
    estimatedRowHeight: 200.0
) { product in
    ProductCard(product: product)
}
.prefetch(distance: 8) {
    store.loadNextPage()
}
```

### Virtualization Guarantees
- **Bounded CALayer Allocation:** A list of 10,000 items only allocates ~30-40 CALayers (covering the visible window plus 1x viewport overscan buffer).
- **Cell Recycling:** Idle layer hierarchies are retained in a `CellReusePool` and recycled by template key, automatically wiping selection and highlight state.
- **Pre-fetching:** Use `.prefetch(distance:action:)` to trigger background page fetches before the user reaches the end of the collection.

---

## 3. Asynchronous Image Pipeline (`Image`)

`Image` loads, decodes, and downsamples images off the main thread before binding them to CALayers.

```swift
Image(url: product.imageURL)
    .contentMode(.fit)
    .cornerRadius(8.0)
    .placeholder {
        ShimmerPlaceholder()
    }
```

### Architecture & Capabilities
1. **Background Downsampling:**
   - Instead of decoding full multi-megapixel images into memory, `ImageDownsampler` uses `CGImageSourceCreateThumbnailAtIndex` with target pixel dimensions matched to the screen scale (e.g. 2x/3x Retina).
2. **In-Flight Deduplication:**
   - Multiple views requesting the same URL share a single ongoing background network/decoding task via `ImageLoader`.
3. **Memory Cache with LRU Eviction:**
   - Decoded `CGImage` thumbnails are cached in `ImageMemoryCache` (default 64MB budget) with automatic LRU purging.
4. **Stale Cell Reuse Protection:**
   - In fast-scrolling lists where cells are recycled, asynchronous image completions verify the current item key before applying `CALayer.contents`, eliminating image flicker.
5. **Smooth Cross-fade:**
   - Images smoothly fade in upon completion, preserving placeholder views while loading.

---

## 4. Priority Scheduler (`RenderScheduler`)

The asynchronous rendering pipeline uses `RenderScheduler` to prevent low-priority prefetch tasks from blocking high-priority immediate user interactions:

- **Immediate Lane:** Dedicated to currently visible frame transactions and user gesture responses.
- **Prefetch Lane:** Used for offscreen overscan image downsampling and text measurement.
- **Idle Lane:** Used for cache compaction, resource cleanup, and disk warmups.
- **Cancellation:** In-flight background decoding tasks for recycled elements are cancelled immediately via `RenderScheduler.shared.cancelAll(for: elementID)`.
