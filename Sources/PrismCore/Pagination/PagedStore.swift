import Foundation
import Flux
import PrismLogging

/// Immutable state representation for a paginated collection.
public struct PagedState<Item: Identifiable & Sendable & Equatable, Cursor: Sendable & Equatable>: Sendable, Equatable {
    /// Currently loaded items, merged with stable identity deduplication.
    public var items: [Item]

    /// Cursor token for requesting the next page, or `nil` if end of collection is reached.
    public var nextCursor: Cursor?

    /// Optional total item count reported by the backend.
    public var totalCount: Int?

    /// True if an initial load is currently in progress.
    public var isInitialLoading: Bool

    /// True if a refresh operation is currently in progress while retaining stale items.
    public var isRefreshing: Bool

    /// True if an append / next page fetch is in progress.
    public var isLoadingNextPage: Bool

    /// Error encountered during initial load, if any.
    public var initialError: LoadableError?

    /// Error encountered during refresh, if any.
    public var refreshError: LoadableError?

    /// Error encountered during next page append, if any.
    public var nextPageError: LoadableError?

    /// Generation index of the active query. Used to invalidate stale asynchronous responses.
    public var generation: UInt64

    /// True if more pages can be requested.
    public var hasMorePages: Bool {
        nextCursor != nil
    }

    /// True if any network or fetching operation is currently active.
    public var isAnyLoading: Bool {
        isInitialLoading || isRefreshing || isLoadingNextPage
    }

    public init(
        items: [Item] = [],
        nextCursor: Cursor? = nil,
        totalCount: Int? = nil,
        isInitialLoading: Bool = false,
        isRefreshing: Bool = false,
        isLoadingNextPage: Bool = false,
        initialError: LoadableError? = nil,
        refreshError: LoadableError? = nil,
        nextPageError: LoadableError? = nil,
        generation: UInt64 = 0
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.totalCount = totalCount
        self.isInitialLoading = isInitialLoading
        self.isRefreshing = isRefreshing
        self.isLoadingNextPage = isLoadingNextPage
        self.initialError = initialError
        self.refreshError = refreshError
        self.nextPageError = nextPageError
        self.generation = generation
    }
}

/// Generic, actor/serialized state machine managing paginated datasets.
///
/// Features:
/// - Reactive state emission via Flux `CurrentValueDistinct`.
/// - Automatic in-flight deduplication: multiple rapid `loadNextPage()` calls coalesce into exactly one request.
/// - Stable ID merging: updates existing items with matching ID and appends unique items, avoiding duplicate render keys.
/// - Stale query protection: async responses from superseded queries or refreshed generations are discarded.
/// - Structured task cancellation and retry hooks.
/// - Observability: emits structured logging events with privacy redaction and trace contexts.
@MainActor
public final class PagedStore<
    Item: Identifiable & Sendable & Equatable,
    Query: Sendable & Equatable,
    Cursor: Sendable & Equatable
> {
    // MARK: - Public Properties

    /// Current query specification for this store.
    public private(set) var query: Query

    /// Requested number of items per page.
    public let pageSize: Int

    /// Observable reactive state stream backed by Flux.
    public let state: CurrentValueDistinct<PagedState<Item, Cursor>>

    /// Direct synchronous snapshot of the current state on MainActor.
    public private(set) var currentState: PagedState<Item, Cursor>

    /// Direct accessor to the latest items.
    public var items: [Item] {
        currentState.items
    }

    /// Direct accessor to check if more items can be loaded.
    public var hasMorePages: Bool {
        currentState.hasMorePages
    }

    // MARK: - Private State

    private let loader: any PageLoader<Item, Query, Cursor>
    private let cache: (any PageCache<Item, Query, Cursor>)?
    private let logger: Logger?

    private var currentGeneration: UInt64 = 0
    private var activeInitialTask: Task<Void, Never>?
    private var activeNextPageTask: Task<Void, Never>?
    private var activeRefreshTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        query: Query,
        loader: any PageLoader<Item, Query, Cursor>,
        cache: (any PageCache<Item, Query, Cursor>)? = nil,
        logger: Logger? = nil,
        pageSize: Int = 20,
        initialState: PagedState<Item, Cursor> = .init()
    ) {
        self.query = query
        self.loader = loader
        self.cache = cache
        self.logger = logger
        self.pageSize = pageSize
        self.currentGeneration = initialState.generation
        self.currentState = initialState
        self.state = CurrentValueDistinct(initialState)
    }

    // MARK: - Pagination Actions

    /// Initiates loading of the first page.
    /// Deduplicates if an initial load is already running.
    public func loadInitial() {
        guard !currentState.isInitialLoading else { return }

        // Cancel any active operations
        cancel()

        updateState { state in
            state.isInitialLoading = true
            state.initialError = nil
        }

        let generation = currentGeneration
        let trace = LogTraceContext()
        logDiagnostic("Initiating initial page load", level: .debug, trace: trace)

        activeInitialTask = Task { [weak self, query, loader, cache, pageSize] in
            // Check cache first if available
            if let cache = cache, let cachedResult = await cache.cachedPage(query: query, cursor: nil) {
                self?.handleInitialSuccess(cachedResult, forGeneration: generation, fromCache: true, trace: trace)
            }

            do {
                let result = try await loader.loadPage(query: query, cursor: nil, pageSize: pageSize)
                try Task.checkCancellation()
                await cache?.storePage(result, query: query, cursor: nil)
                self?.handleInitialSuccess(result, forGeneration: generation, fromCache: false, trace: trace)
            } catch is CancellationError {
                self?.handleCancellation(forGeneration: generation)
            } catch {
                self?.handleInitialFailure(error, forGeneration: generation, trace: trace)
            }
        }
    }

    /// Loads the next page of items.
    ///
    /// Coalesces multiple rapid calls into a single in-flight request.
    /// Returns immediately if already loading or if no further pages exist.
    public func loadNextPage() {
        guard !currentState.isLoadingNextPage,
              !currentState.isInitialLoading,
              !currentState.isRefreshing,
              let cursor = currentState.nextCursor else {
            return
        }

        updateState { state in
            state.isLoadingNextPage = true
            state.nextPageError = nil
        }

        let generation = currentGeneration
        let trace = LogTraceContext()
        logDiagnostic("Loading next page", level: .debug, trace: trace)

        activeNextPageTask = Task { [weak self, query, loader, cache, pageSize] in
            do {
                let result = try await loader.loadPage(query: query, cursor: cursor, pageSize: pageSize)
                try Task.checkCancellation()
                await cache?.storePage(result, query: query, cursor: cursor)
                self?.handleNextPageSuccess(result, forGeneration: generation, trace: trace)
            } catch is CancellationError {
                self?.handleCancellation(forGeneration: generation)
            } catch {
                self?.handleNextPageFailure(error, forGeneration: generation, trace: trace)
            }
        }
    }

    /// Refreshes the dataset starting from the initial page.
    ///
    /// Retains currently loaded items so UI displays stale data without a blank screen.
    /// Cancels any in-flight append requests.
    public func refresh() {
        guard !currentState.isRefreshing else { return }

        // Cancel pending append task
        activeNextPageTask?.cancel()
        activeNextPageTask = nil

        updateState { state in
            state.isRefreshing = true
            state.refreshError = nil
        }

        let generation = currentGeneration
        let trace = LogTraceContext()
        logDiagnostic("Refreshing paged store", level: .info, trace: trace)

        activeRefreshTask = Task { [weak self, query, loader, cache, pageSize] in
            do {
                let result = try await loader.loadPage(query: query, cursor: nil, pageSize: pageSize)
                try Task.checkCancellation()
                await cache?.storePage(result, query: query, cursor: nil)
                self?.handleRefreshSuccess(result, forGeneration: generation, trace: trace)
            } catch is CancellationError {
                self?.handleCancellation(forGeneration: generation)
            } catch {
                self?.handleRefreshFailure(error, forGeneration: generation, trace: trace)
            }
        }
    }

    /// Retries an initial load if it previously failed.
    public func retryInitial() {
        loadInitial()
    }

    /// Retries fetching the next page if the previous append attempt failed.
    public func retryNextPage() {
        loadNextPage()
    }

    /// Updates the query.
    ///
    /// Increments the generation counter to invalidate any in-flight responses,
    /// cancels existing tasks, and optionally triggers an immediate reload.
    public func updateQuery(_ newQuery: Query, reload: Bool = true) {
        guard newQuery != query else { return }

        query = newQuery
        currentGeneration &+= 1
        cancel()

        updateState { state in
            state.generation = currentGeneration
            state.items = []
            state.nextCursor = nil
            state.totalCount = nil
            state.initialError = nil
            state.refreshError = nil
            state.nextPageError = nil
            state.isInitialLoading = false
            state.isRefreshing = false
            state.isLoadingNextPage = false
        }

        logDiagnostic("Query updated", level: .info)

        if reload {
            loadInitial()
        }
    }

    /// Cancels all active in-flight requests and resets loading flags.
    public func cancel() {
        activeInitialTask?.cancel()
        activeInitialTask = nil
        activeNextPageTask?.cancel()
        activeNextPageTask = nil
        activeRefreshTask?.cancel()
        activeRefreshTask = nil

        if currentState.isAnyLoading {
            updateState { state in
                state.isInitialLoading = false
                state.isRefreshing = false
                state.isLoadingNextPage = false
            }
        }
    }

    // MARK: - State Update Helper

    private func updateState(_ mutate: (inout PagedState<Item, Cursor>) -> Void) {
        var next = currentState
        mutate(&next)
        currentState = next
        let distinctHolder = self.state
        Task {
            await distinctHolder.set(next)
        }
    }

    // MARK: - Private Response Handlers

    private func handleInitialSuccess(
        _ result: PageResult<Item, Cursor>,
        forGeneration generation: UInt64,
        fromCache: Bool,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else {
            logDiagnostic("Discarding stale initial page response", level: .debug, trace: trace)
            return
        }

        activeInitialTask = nil
        updateState { state in
            state.items = result.items
            state.nextCursor = result.nextCursor
            state.totalCount = result.totalCount
            if !fromCache {
                state.isInitialLoading = false
            }
            state.initialError = nil
        }

        logDiagnostic("Initial page loaded (\(result.items.count) items)", level: .info, trace: trace)
    }

    private func handleInitialFailure(
        _ error: any Error,
        forGeneration generation: UInt64,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else { return }

        activeInitialTask = nil
        updateState { state in
            state.isInitialLoading = false
            state.initialError = LoadableError(from: error)
        }

        logDiagnostic("Initial page load failed: \(error.localizedDescription)", level: .warning, trace: trace)
    }

    private func handleNextPageSuccess(
        _ result: PageResult<Item, Cursor>,
        forGeneration generation: UInt64,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else {
            logDiagnostic("Discarding stale next page response", level: .debug, trace: trace)
            return
        }

        activeNextPageTask = nil
        updateState { state in
            state.items = mergeItems(state.items, with: result.items)
            state.nextCursor = result.nextCursor
            state.totalCount = result.totalCount ?? state.totalCount
            state.isLoadingNextPage = false
            state.nextPageError = nil
        }

        logDiagnostic("Next page appended (\(result.items.count) new items, total: \(currentState.items.count))", level: .info, trace: trace)
    }

    private func handleNextPageFailure(
        _ error: any Error,
        forGeneration generation: UInt64,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else { return }

        activeNextPageTask = nil
        updateState { state in
            state.isLoadingNextPage = false
            state.nextPageError = LoadableError(from: error)
        }

        logDiagnostic("Next page load failed: \(error.localizedDescription)", level: .warning, trace: trace)
    }

    private func handleRefreshSuccess(
        _ result: PageResult<Item, Cursor>,
        forGeneration generation: UInt64,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else {
            logDiagnostic("Discarding stale refresh response", level: .debug, trace: trace)
            return
        }

        activeRefreshTask = nil
        updateState { state in
            state.items = result.items
            state.nextCursor = result.nextCursor
            state.totalCount = result.totalCount
            state.isRefreshing = false
            state.refreshError = nil
        }

        logDiagnostic("Refresh completed (\(result.items.count) items)", level: .info, trace: trace)
    }

    private func handleRefreshFailure(
        _ error: any Error,
        forGeneration generation: UInt64,
        trace: LogTraceContext
    ) {
        guard generation == currentGeneration else { return }

        activeRefreshTask = nil
        updateState { state in
            state.isRefreshing = false
            state.refreshError = LoadableError(from: error)
        }

        logDiagnostic("Refresh failed: \(error.localizedDescription)", level: .warning, trace: trace)
    }

    private func handleCancellation(forGeneration generation: UInt64) {
        guard generation == currentGeneration else { return }
        updateState { state in
            state.isInitialLoading = false
            state.isRefreshing = false
            state.isLoadingNextPage = false
        }
    }

    // MARK: - Stable ID Merging

    /// Merges new page items with existing items, updating existing items in place
    /// and appending unique new items to prevent duplicate identity collisions.
    private func mergeItems(_ existing: [Item], with incoming: [Item]) -> [Item] {
        var merged = existing
        var indexByID: [Item.ID: Int] = [:]
        indexByID.reserveCapacity(existing.count + incoming.count)

        for (index, item) in existing.enumerated() {
            indexByID[item.id] = index
        }

        for newItem in incoming {
            if let existingIndex = indexByID[newItem.id] {
                merged[existingIndex] = newItem
            } else {
                indexByID[newItem.id] = merged.count
                merged.append(newItem)
            }
        }

        return merged
    }

    // MARK: - Logging Helper

    private func logDiagnostic(
        _ message: String,
        level: LogLevel,
        trace: LogTraceContext? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        guard let logger = logger else { return }
        let metadata: [String: LogMetadataValue] = [
            "generation": .public(Int(currentGeneration)),
            "itemCount": .public(currentState.items.count),
            "hasMorePages": .public(currentState.hasMorePages)
        ]

        logger.log(
            level,
            message,
            metadata: metadata,
            file: file,
            function: function,
            line: UInt(line)
        )
    }
}
