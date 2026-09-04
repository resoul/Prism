# ADR 0016: Scroll Engine, Virtualization Windowing, and Async Image Pipeline

## Status
Accepted

## Context
Displaying long dynamic feeds, photo galleries, and nested scrollable layouts is a foundational requirement for modern user interfaces. However, naive implementations suffer from severe performance and architecture pathologies:
1. **Unbounded GPU Layer Allocation:** Mounting thousands of subviews/CALayers causes catastrophic memory growth, frame drops, and application termination.
2. **Main Thread Blocking:** Parsing network/disk images and measuring multiline text on the UI thread causes severe scroll hitches (>16.6ms frame times).
3. **Stale Asynchronous Updates:** In virtualized collections, cells are rapidly recycled. Asynchronous image loading tasks completing after a cell has been reassigned to a different item cause visual flickering and incorrect image flashing.
4. **Scroll Coordination & Rubber-banding:** Platform scroll views (`UIScrollView` vs `NSScrollView`) have incompatible event and physics models. Prism requires a deterministic, platform-agnostic physics simulator with remainder propagation for nested containers, bounce resistance, and anchor-based programmatic alignment.
5. **Platform UI Leakage:** Directly exposing platform scroll views or image views violates `0001-no-platform-ui-in-public-api.md`.

## Decision

1. **Deterministic Physics Simulator (`ScrollPhysicsEngine` & `ScrollPosition`):**
   - Pure Swift deterministic physics simulation supporting horizontal, vertical, and bidirectional scrolling.
   - Deceleration decay with configurable friction factor (0.998), fling velocity handling, and iOS-standard rubber-band spring dampening (0.55 coefficient).
   - Unconsumed remainder propagation: `applyDelta(_:)` returns unconsumed offset deltas for nested scroll gesture delegation.
   - Programmatic `targetOffset(for:anchor:)` supporting `.top`, `.center`, and `.bottom` target anchoring.
   - Serializable `ScrollStateSnapshot` enabling persistent scroll position restoration across view hierarchy reconstruction.

2. **Render-Tree Scroll Area (`ScrollAreaRenderer` & `ScrollArea`):**
   - `ScrollArea` component in `PrismUI` exposing `ScrollProxy` for programmatic scrolling by offset or target ID.
   - `ScrollAreaRenderer` creates a clipped container layer (`masksToBounds = true`) hosting a dedicated content translation layer (`CATransform3DMakeTranslation`).
   - Integrated vertical/horizontal fading scroll indicator layers with automatic fade animations.

3. **Virtualization Window & Cell Reuse Pool (`VirtualizationWindow` & `CellReusePool`):**
   - `VirtualizationWindow` computes visible and overscan item ranges using configurable overscan multiples (default 1.0x viewport height).
   - Only visible + overscan elements are translated into `RenderElement` nodes, keeping CALayer allocation strictly bounded (e.g. ~35 layers for a 10,000-item list).
   - `CellReusePool` recycles idle layer hierarchies by template identifier with full transient state reset (`isSelected = false`, `isHighlighted = false`, transform resets).

4. **Background Priority Scheduler (`RenderScheduler` & `DisplayTransaction`):**
   - Background execution queue with prioritized lanes (`immediate`, `prefetch`, `idle`).
   - Task cancellation tokens and element ID scoped eviction (`cancelAll(for: id)`), preventing stale background computations when views unmount or recycle.
   - `DisplayTransaction` packages immutable display payloads off-thread and applies them atomically on `@MainActor`.

5. **Asynchronous Downsampled Image Pipeline (`ImageLoader`, `ImageMemoryCache`, `ImageRenderer`):**
   - `ImageDownsampler` decodes images off-the-main-thread using `CGImageSourceCreateThumbnailAtIndex` matching exact pixel display bounds and retina scale.
   - In-flight request deduplication via `ImageLoader`: concurrent loads for the same URL share a single ongoing background task.
   - `ImageMemoryCache`: Thread-safe LRU cache bounded by byte size (default 64MB) with automatic memory pressure eviction.
   - Cell reuse protection: `ImageRenderer` checks `currentImageKey` against requested key before setting `CALayer.contents`.
   - Smooth fade-in transitions and `.fit`/`.fill`/`.stretch`/`.center` content mode mapping via `contentsGravity`.

## Consequences
- **Positive:** Bounded memory and CALayer consumption regardless of collection size (proven for 10,000+ items).
- **Positive:** Hitch-free 60/120 FPS scrolling with image decoding and downsampling completely offloaded to background threads.
- **Positive:** Zero image flashing during rapid cell reuse due to key-based generation tracking.
- **Positive:** Complete cross-platform parity on macOS and iOS with zero platform UI leaks.
- **Trade-off:** Virtualized lists require an estimated item height before first layout measurement to calculate scrollbar thumb dimensions.
