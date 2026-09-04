import Foundation

/// The result of fetching a single page from a data source.
public struct PageResult<Item: Sendable & Equatable, Cursor: Sendable & Equatable>: Sendable, Equatable {
    /// Items returned for this page.
    public let items: [Item]

    /// Cursor token for fetching the subsequent page, or `nil` if this is the terminal page.
    public let nextCursor: Cursor?

    /// Optional total count of items across all pages if reported by the remote data source.
    public let totalCount: Int?

    public init(
        items: [Item],
        nextCursor: Cursor?,
        totalCount: Int? = nil
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.totalCount = totalCount
    }
}

/// Contract for asynchronous paginated page retrieval.
///
/// Implemented by API clients, repositories, or memory/disk cache adapters.
/// Designed to be decoupled from presentation components so UI primitives (`LazyGrid`, `Resource`)
/// can request more items without knowing the underlying network or database implementation.
public protocol PageLoader<Item, Query, Cursor>: Sendable {
    associatedtype Item: Identifiable & Sendable & Equatable
    associatedtype Query: Sendable & Equatable
    associatedtype Cursor: Sendable & Equatable

    /// Fetches a page of items matching the given query starting from the specified cursor.
    ///
    /// - Parameters:
    ///   - query: The query filter/specification for this dataset.
    ///   - cursor: The cursor token returned by a previous page, or `nil` for the initial page.
    ///   - pageSize: Requested number of items per page.
    /// - Returns: A `PageResult` containing items and the next cursor token.
    func loadPage(
        query: Query,
        cursor: Cursor?,
        pageSize: Int
    ) async throws -> PageResult<Item, Cursor>
}

/// A type-erased closure-based implementation of `PageLoader`.
public struct AnyPageLoader<Item: Identifiable & Sendable & Equatable, Query: Sendable & Equatable, Cursor: Sendable & Equatable>: PageLoader {
    private let _loadPage: @Sendable (Query, Cursor?, Int) async throws -> PageResult<Item, Cursor>

    public init(
        loadPage: @escaping @Sendable (Query, Cursor?, Int) async throws -> PageResult<Item, Cursor>
    ) {
        self._loadPage = loadPage
    }

    public func loadPage(
        query: Query,
        cursor: Cursor?,
        pageSize: Int
    ) async throws -> PageResult<Item, Cursor> {
        try await _loadPage(query, cursor, pageSize)
    }
}

/// Hook protocol for page caching and offline persistence without coupling to concrete database engines.
public protocol PageCache<Item, Query, Cursor>: Sendable {
    associatedtype Item: Identifiable & Sendable & Equatable
    associatedtype Query: Sendable & Equatable
    associatedtype Cursor: Sendable & Equatable

    /// Attempts to retrieve a previously cached page result for the given query and cursor.
    func cachedPage(query: Query, cursor: Cursor?) async -> PageResult<Item, Cursor>?

    /// Persists a retrieved page result for future instant display.
    func storePage(_ result: PageResult<Item, Cursor>, query: Query, cursor: Cursor?) async

    /// Invalidates all cached pages associated with the query.
    func invalidate(query: Query) async
}
