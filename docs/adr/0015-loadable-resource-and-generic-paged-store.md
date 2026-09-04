# ADR 0015: Loadable, Resource, and Generic PagedStore

## Status
Accepted

## Context
Applications frequently display asynchronous collections and remote resources that progress through distinct lifecycle stages: unstarted (`idle`), initial fetching (`loading`), display of content (`loaded`), background revalidation/pull-to-refresh (`refreshing`), and error states (`failure`). 

Without a standard data loading contract:
1. **Ad-hoc state representation:** Screens independently invent optional booleans (`isLoading`, `isRefreshing`, `hasError`), leading to invalid intermediate states (e.g. `isLoading == true` while `hasError == true`) and screen-flickering bugs when reloads clear existing content.
2. **Pagination race conditions:** Rapid scrolling in virtualized lists (`LazyGrid`) triggers bursts of prefetch calls, leading to duplicated network requests, out-of-order page appending, and duplicate item key crashes.
3. **Stale query leaks:** If a search query changes rapidly, slow responses from earlier queries can overwrite fresh results from newer queries.
4. **Module boundary violations:** If presentation components (`Resource`, `LazyGrid`) depend on concrete HTTP clients or database repositories, UI targets (`PrismUI`) end up improperly coupled to data transport targets (`PrismData`, `PrismStorage`), violating `MODULE_CONTRACT.md`.

## Decision

1. **`Loadable<Value>` Enum Contract (`Sources/PrismCore/State/Loadable.swift`):**
   - Value-type state machine with explicit cases:
     - `.idle`: unstarted state.
     - `.loading(previous: Value?)`: initial fetch in progress, retaining optional previous data.
     - `.loaded(Value)`: successfully loaded content.
     - `.refreshing(previous: Value)`: background refresh while keeping current data visible without screen flicker.
     - `.failure(error: LoadableError, previous: Value?)`: operation failed, preserving stale data for offline/retry scenarios.
   - Strongly typed, sanitized `LoadableError` classifying network, timeout, unauthorized, server, decoding, and cancellation failures without leaking confidential user data.
   - Functional operators: `.map(_:)` and `.flatMap(_:)`.

2. **Declarative UI `Resource<Value>` Component (`Sources/PrismUI/Feedback/Resource.swift`):**
   - Declarative `Component` taking `Loadable<Value>` with customizable builders (`content`, `loading`, `failure`, `empty`).
   - Retains and dims previous content during reload if no custom loading view is specified.
   - Accessibility semantics: attaches `.updatesFrequently` trait to loading placeholders and announces error messages.
   - Zero network ownership: `Resource` does not instantiate tasks or network sessions; it strictly maps reactive state to VRT nodes and invokes optional user retry callbacks.

3. **Generic `PagedStore<Item, Query, Cursor>` (`Sources/PrismCore/Pagination/PagedStore.swift`):**
   - Serialized `@MainActor` state machine managing paginated collections.
   - Exposes reactive stream `state: CurrentValueDistinct<PagedState<Item, Cursor>>` and synchronous snapshot `currentState`.
   - Automatic in-flight request deduplication: rapid successive `loadNextPage()` calls coalesce into a single execution.
   - Deterministic stable ID merging: updates existing items in-place and appends unique new items, preventing duplicate key collisions in virtualized grids.
   - Generation protection: each query change or reload increments a monotonic generation counter; responses from superseded queries are discarded immediately.
   - Structured cancellation: invoking `cancel()` or changing queries aborts running tasks.

4. **Decoupled Architecture (`PageLoader` & `PageCache` protocols in `PrismCore`):**
   - `PageLoader` and `PageCache` protocols reside in `PrismCore`, allowing `PrismUI` to consume `PagedStore` without importing `PrismData`.
   - `PrismData` can subsequently provide concrete HTTP/WebSocket implementations and `PrismStorage` can provide cache adapters.

5. **Structured Logging & Diagnostics:**
   - Emits structured diagnostics via `PrismLogging` under category `LogCategory("data.paged")` and `LogTraceContext`.
   - Privacy guarantee: log records contain query generation, page size, and item counts; raw user entities and private payload bodies are never logged.

## Consequences
- **Positive:** Standardized, flicker-free data loading across all screens and lazy lists.
- **Positive:** In-flight deduplication and generation counters completely prevent pagination race conditions and duplicate render key crashes.
- **Positive:** Clean architectural boundaries: `PrismUI` remains 100% free of HTTP/transport dependencies.
- **Positive:** Unit-testable: mock loaders (`AnyPageLoader`) can be created in a single closure.
- **Trade-off:** Cursors and Items must conform to `Equatable` to support automatic deduplication in `CurrentValueDistinct`.
