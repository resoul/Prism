import Foundation

/// Policy defining how cache and network layers interact during data retrieval.
public enum FetchStrategy: Sendable, Equatable {
    /// Return data strictly from the local cache. Fails if entry is missing or expired.
    case cacheOnly

    /// Fetch fresh data from the remote network, ignoring local cache. Updates cache on success.
    case networkOnly

    /// Return cached entry if valid; otherwise fetch from network and populate cache.
    case cacheFirst

    /// Attempt network fetch first; fall back to cached entry if network fails.
    case networkFirst

    /// Immediately emit cached entry (if available), then fetch from network and emit fresh entry.
    case cacheAndNetwork
}
