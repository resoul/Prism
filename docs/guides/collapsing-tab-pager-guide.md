# CollapsingTabPager and Shared Header Guide

This guide explains how to construct rich profile screens and multi-tab feed experiences with a shared collapsing header, sticky tabs, and virtualized paged grids using Prism's `CollapsingTabPager`.

---

## 1. Overview

`CollapsingTabPager` solves the common UI pattern where:
1. A top header (avatar, statistics, bio) smoothly collapses as the user scrolls down.
2. A tab bar docks to the top of the viewport and remains sticky once the header reaches its minimum collapsed height.
3. Multiple pages can be swiped horizontally, with each page retaining its own independent vertical scroll position and reactive data store.

---

## 2. Public Composition API

```swift
import PrismUI

enum ProfileTab: String, CaseIterable, TabItem {
    case posts, likes, reposts

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct ProfileScreen: Component {
    @Binding var selectedTab: ProfileTab
    let store: ProfileStore

    var body: [RenderElement] {
        CollapsingTabPager(
            selection: $selectedTab,
            expandedHeaderHeight: 188.0,
            collapsedHeaderHeight: 0.0
        ) {
            CollapsingHeader(expandedHeight: 188.0, collapsedHeight: 0.0) {
                ProfileHeaderView(profile: store.profile)
            }

            PinnedTabs(
                ProfileTab.allCases,
                selection: selectedTab,
                height: 44.0
            ) { tab in
                selectedTab = tab
            }
        } pages: {
            TabPage(.posts) {
                PostGridView(store: store.postsStore)
            }
            TabPage(.likes) {
                PostGridView(store: store.likesStore)
            }
            TabPage(.reposts) {
                PostGridView(store: store.repostsStore)
            }
        }
    }
}
```

---

## 3. Architecture & Mechanics

### Header Collapse Coordinator (`HeaderCollapseCoordinator`)
- Manages `expandedHeight`, `collapsedHeight`, and `collapseProgress` (0.0 to 1.0).
- As the active page list is scrolled, the header absorbs initial offset changes until fully collapsed.
- **Cross-Tab Preservation:** When switching between tabs, if the header is currently collapsed, the incoming tab's starting offset accommodates the collapsed boundary so the header does not suddenly jump open. When returning to a tab that had scrolled deeper into its collection, its residual scroll depth is restored.

### Gesture Arena (`GestureArena`)
- Disambiguates 2D pan gestures using a configurable slop threshold (default 10pt).
- If horizontal movement dominates (`abs(dx) > abs(dy)`), gesture lock is assigned to page transitions.
- If vertical movement dominates (`abs(dy) >= abs(dx)`), gesture lock is assigned to active page scrolling and header collapse.

### Neighbour Mount Policy (`NeighbourMountPolicy`)
- To prevent memory bloat, `PagePager` mounts only the currently visible page and its immediate neighbours:
  ```text
  Active: Tab 2 (Likes)
  Mounted: [Tab 1 (Posts), Tab 2 (Likes), Tab 3 (Reposts)]
  Unmounted: All distant pages
  ```
- Unmounting distant pages immediately frees CALayer allocations and cancels background tasks.

---

## 4. Performance & Scalability (10,000+ Items)

Each tab can render a virtualized `LazyGrid` paired with an asynchronous `PagedStore`:

```swift
LazyGrid(
    columns: .fixed(3),
    data: store.items,
    id: \.id,
    spacing: 2.0,
    estimatedRowHeight: 120.0
) { item in
    Image(url: item.imageURL)
        .contentMode(.fill)
}
.prefetch(distance: 9) {
    store.loadNextPage()
}
```

- **Bounded CALayers:** Even with 10,000 items in the store, `LazyGrid` maintains only ~30-40 active CALayers on screen.
- **Request Deduplication:** Rapid prefetch events are coalesced by `PagedStore`.
- **Query Generation Protection:** Switching filters or profiles increments the store's monotonic generation index, instantly dropping stale background network and decode responses.
