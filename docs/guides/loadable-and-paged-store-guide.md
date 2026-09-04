# Loadable, Resource, and Generic PagedStore Guide

This guide describes how to manage asynchronous data loading, pagination, and error handling in Prism using `Loadable<Value>`, the declarative `Resource` component, and `PagedStore`.

---

## 1. Asynchronous Data Lifecycle (`Loadable<Value>`)

`Loadable<Value>` models the complete lifecycle of remote or asynchronous data without relying on ambiguous boolean combinations.

```swift
public enum Loadable<Value: Sendable>: Sendable {
    case idle
    case loading(previous: Value? = nil)
    case loaded(Value)
    case refreshing(previous: Value)
    case failure(error: LoadableError, previous: Value? = nil)
}
```

### Key Principles
- **No Content Flashing:** When reloading existing content (e.g. pull-to-refresh or background polling), `.refreshing(previous: val)` retains the current data so the UI remains stable.
- **Offline & Retry Resilience:** If a reload fails, `.failure(error: err, previous: val)` preserves stale data while allowing the UI to present a non-intrusive warning or retry banner.
- **Typed Errors:** `LoadableError` classifies failures into clear codes (`.network`, `.timeout`, `.unauthorized`, `.serverError`, `.cancelled`) without leaking sensitive user data into logs.

### Transformations
`Loadable` provides functional operators:
```swift
let userLoadable: Loadable<User> = ...
let nameLoadable: Loadable<String> = userLoadable.map { $0.displayName }
```

---

## 2. Declarative UI with `Resource`

The `Resource` component in `PrismUI` translates `Loadable<Value>` into virtual render tree nodes:

```swift
Resource(profileLoadable, retry: { store.reloadProfile() }) { profile in
    ProfileCard(profile: profile)
} loading: { previous in
    if let previous = previous {
        ProfileCard(profile: previous).opacity(0.6)
    } else {
        ProfileSkeleton()
    }
} failure: { error, retry in
    ErrorBanner(message: error.message, retry: retry)
}
```

### Default Behaviors
- **Default Loading:** If no custom `loading` builder is provided:
  - If a previous value exists, it is displayed dimmed (opacity 0.6) with accessibility hint `"Reloading content"`.
  - If no previous value exists, an accessible loading placeholder (`Text("Loading...")` with trait `.updatesFrequently`) is displayed.
- **Default Failure:** Renders an error message and a "Retry" button (if a retry closure was provided).
- **Zero Network Coupling:** `Resource` never initiates HTTP requests or manages background tasks directly.

---

## 3. Generic Pagination with `PagedStore`

`PagedStore<Item, Query, Cursor>` is a serialized `@MainActor` state machine for paginated collections (such as posts, comments, or search results).

```swift
final class PostListStore {
    let pagedPosts: PagedStore<Post, PostQuery, Int>

    init(query: PostQuery, loader: any PageLoader<Post, PostQuery, Int>) {
        self.pagedPosts = PagedStore(query: query, loader: loader, pageSize: 20)
    }
}
```

### Automatic Protections
1. **Prefetch Deduplication:** Rapid scrolling can trigger multiple prefetch events in quick succession. `PagedStore.loadNextPage()` automatically coalesces concurrent requests into a single in-flight operation.
2. **Stable ID Merging:** Incoming page items are merged deterministically by `Item.id`. Existing items are updated in-place and new items are appended, eliminating duplicate render key crashes.
3. **Stale Query Protection:** Updating the query (`updateQuery(newQuery)`) increments a generation counter and cancels pending tasks. Responses from superseded queries are automatically discarded.
4. **Flicker-Free Refresh:** Calling `refresh()` reloads the initial page while keeping existing items visible until the new page arrives.

### Observing State
`PagedStore` exposes both a reactive Flux stream and synchronous snapshot properties:
```swift
// Synchronous access on MainActor:
let count = store.items.count
let hasMore = store.hasMorePages

// Reactive Flux subscription:
Reactive(store.state) { pagedState in
    LazyGrid(columns: .fixed(3), data: pagedState.items, id: \.id) { post in
        PostTile(post)
    }
    .prefetch(distance: 10) {
        store.loadNextPage()
    }
}
```

---

## 4. Implementing `PageLoader`

To supply data to a `PagedStore`, conform to `PageLoader`:

```swift
struct PostApiLoader: PageLoader {
    typealias Item = Post
    typealias Query = PostQuery
    typealias Cursor = Int

    func loadPage(
        query: PostQuery,
        cursor: Int?,
        pageSize: Int
    ) async throws -> PageResult<Post, Int> {
        let pageIndex = cursor ?? 0
        let response = try await apiClient.fetchPosts(tag: query.tag, page: pageIndex, limit: pageSize)
        
        return PageResult(
            items: response.posts,
            nextCursor: response.hasMore ? pageIndex + 1 : nil,
            totalCount: response.totalCount
        )
    }
}
```

### In-Memory / Test Loader
For unit tests or mocks, use `AnyPageLoader`:
```swift
let mockLoader = AnyPageLoader<Post, String, Int> { query, cursor, pageSize in
    PageResult(items: [Post(id: "1", title: "Test")], nextCursor: nil)
}
let store = PagedStore(query: "recent", loader: mockLoader)
```

---

## 5. Structured Observability

`PagedStore` integrates with `PrismLogging`:
- Emits diagnostic records under `LogCategory("data.paged")`.
- Associates operations with `LogTraceContext` across asynchronous spans.
- Logs metadata like `generation`, `itemCount`, and `hasMorePages` while strictly redacting raw item contents and query parameters.
