# ADR 0017: CollapsingTabPager, Gesture Arena, and Shared Header Coordinator

## Status
Accepted

## Context
Complex social profiles, media galleries, and feed dashboards require a multi-tab interface with a rich collapsible header (e.g. avatar, bio, follower statistics, action buttons) and sticky tab navigation docked above horizontal swipeable pages.

Previous platform implementations (e.g. `ProfilePage-main` with UIKit `UIPageViewController`, `UICollectionView`, and manual `UIScrollViewDelegate` offset synchronization) suffer from several architectural flaws:
1. **Direct Platform UI Coupling:** Coupling to `UIPageViewController` and `UIScrollView` leaks UIKit/AppKit dependencies into application logic, violating `ADR 0001` and `MODULE_CONTRACT.md`.
2. **Scroll Desynchronization & Snapping Artifacts:** Manually adjusting `contentOffset` across inactive view controllers leads to visual stutter, unexpected header expansion upon tab switching, and infinite layout loops.
3. **Memory Bloat from Eager Paging:** Mounting all tab view controllers and their collection views simultaneously keeps offscreen layers, images, and network subscriptions alive, causing memory exhaustion on large feeds.
4. **2D Gesture Ambiguity:** Diagonal pan gestures cause simultaneous partial horizontal paging and vertical list scrolling, resulting in jarring diagonal drift.

## Decision

1. **Shared State Machine (`HeaderCollapseCoordinator`):**
   - Pure Swift deterministic coordinator tracking `expandedHeight`, `collapsedHeight`, `collapseRange`, and `collapseProgress` (0.0 to 1.0).
   - Unified surface illusion: Active page vertical scrolling collapses the shared header. When switching tabs, if the header is collapsed, the incoming tab's effective scroll offset accommodates the collapsed header boundary without snapping open.
   - Independent page depth preservation: Each tab preserves its own vertical scroll position beyond the collapse threshold (`pageScrollOffsets[page]`).

2. **2D Pan Gesture Disambiguation (`GestureArena`):**
   - Slop threshold (default 10pt) suppresses gesture routing until the user's intent is clear.
   - Dominant axis lock: If `abs(dx) > abs(dy)`, the gesture locks horizontally to page navigation; if `abs(dy) >= abs(dx)`, the gesture locks vertically to list scrolling and header collapse.

3. **Neighbour-Only Mount Policy (`NeighbourMountPolicy`):**
   - `PagePager` renders only the active page and its immediate left/right adjacent neighbours (`[selectedIndex - 1, selectedIndex, selectedIndex + 1]`).
   - Distant pages are unmounted from the Virtual Render Tree, immediately releasing CALayers, canceling background render scheduler tasks, and pausing data subscriptions.

4. **Sticky Semantic Tabs (`PinnedTabs`):**
   - Docked cleanly below the collapsing header container with high z-index (`zIndex: 100`).
   - Sliding selection indicator line, active tab state, and VoiceOver accessibility attributes (`role: tab`, `selected: true/false`).

5. **Heavy Integration Benchmark (`ProfilePageDemo`):**
   - Replicates the `ProfilePage-main` architecture with 3 independent `PagedStore`s (Posts, Likes, Reposts).
   - Each tab leverages `LazyGrid` with asynchronous downsampled `Image` loading and `.prefetch(distance: 9)`.
   - Verified performance with 10,000 synthetic items per tab: strictly bounded CALayers (~30 items mounted), deduplicated in-flight requests, and query generation protection.

## Consequences
- **Positive:** Smooth, hitch-free collapsing header and horizontal paging without any UIKit/AppKit controllers or manual offset math in consumer code.
- **Positive:** Bounded memory footprint via strict neighbour mount policy and lazy grid virtualization.
- **Positive:** Clean gesture arbitration preventing diagonal scroll drift.
- **Trade-off:** Nested scrollable containers within a single page (e.g. horizontal carousel) require careful gesture boundary delegation.
