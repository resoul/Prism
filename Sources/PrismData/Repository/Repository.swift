import Foundation
import struct Flux.Flux
import class Flux.Pipe
import PrismStorage

/// Generic reactive repository orchestrating cache and network operations according to a `FetchStrategy`.
public final class Repository<Key: Hashable & Sendable, Entity: Codable & Sendable & Equatable>: Sendable {
    public typealias RemoteFetch = @Sendable (Key) async throws -> Entity
    public typealias RemoteSave = @Sendable (Key, Entity) async throws -> Void
    public typealias RemoteDelete = @Sendable (Key) async throws -> Void

    private let cache: HybridCache<Key, Entity>
    private let remoteFetch: RemoteFetch
    private let remoteSave: RemoteSave?
    private let remoteDelete: RemoteDelete?

    public init(
        namespace: String = "repository",
        remoteFetch: @escaping RemoteFetch,
        remoteSave: RemoteSave? = nil,
        remoteDelete: RemoteDelete? = nil
    ) {
        self.cache = HybridCache(namespace: namespace)
        self.remoteFetch = remoteFetch
        self.remoteSave = remoteSave
        self.remoteDelete = remoteDelete
    }

    public init(
        cache: HybridCache<Key, Entity>,
        remoteFetch: @escaping RemoteFetch,
        remoteSave: RemoteSave? = nil,
        remoteDelete: RemoteDelete? = nil
    ) {
        self.cache = cache
        self.remoteFetch = remoteFetch
        self.remoteSave = remoteSave
        self.remoteDelete = remoteDelete
    }

    /// Fetches an entity using the specified strategy.
    public func fetch(key: Key, strategy: FetchStrategy = .cacheFirst) async throws -> Entity {
        switch strategy {
        case .cacheOnly:
            guard let cached = await cache.get(key) else {
                throw HTTPError.transportError(URLError(.fileDoesNotExist))
            }
            return cached

        case .networkOnly:
            let remote = try await remoteFetch(key)
            await cache.set(remote, for: key)
            return remote

        case .cacheFirst:
            if let cached = await cache.get(key) {
                return cached
            }
            let remote = try await remoteFetch(key)
            await cache.set(remote, for: key)
            return remote

        case .networkFirst:
            do {
                let remote = try await remoteFetch(key)
                await cache.set(remote, for: key)
                return remote
            } catch {
                if let cached = await cache.get(key) {
                    return cached
                }
                throw error
            }

        case .cacheAndNetwork:
            // For single-value async fetch, returns fresh network after checking cache
            if let cached = await cache.get(key) {
                Task { [weak self, key] in
                    if let fresh = try? await self?.remoteFetch(key) {
                        await self?.cache.set(fresh, for: key)
                    }
                }
                return cached
            }
            let remote = try await remoteFetch(key)
            await cache.set(remote, for: key)
            return remote
        }
    }

    /// Observes an entity as a reactive Flux stream, delivering cached state and fresh network updates.
    public func observe(key: Key, strategy: FetchStrategy = .cacheAndNetwork) -> Flux<Entity> {
        Flux { [weak self, key] emitter in
            Task { [weak self, key] in
                guard let self else {
                    emitter.finish()
                    return
                }

                if strategy == .cacheAndNetwork || strategy == .cacheFirst {
                    if let cached = await self.cache.get(key) {
                        emitter.send(cached)
                        if strategy == .cacheFirst {
                            emitter.finish()
                            return
                        }
                    }
                }

                if strategy != .cacheOnly {
                    do {
                        let fresh = try await self.remoteFetch(key)
                        await self.cache.set(fresh, for: key)
                        emitter.send(fresh)
                    } catch {
                        // If cached was already emitted, keep stream open or finish
                    }
                }

                emitter.finish()
            }
        }
    }

    /// Saves an entity to cache and remote backend.
    public func save(_ entity: Entity, for key: Key) async throws {
        await cache.set(entity, for: key)
        if let remoteSave {
            try await remoteSave(key, entity)
        }
    }

    /// Deletes an entity from cache and remote backend.
    public func delete(key: Key) async throws {
        await cache.remove(key)
        if let remoteDelete {
            try await remoteDelete(key)
        }
    }
}
