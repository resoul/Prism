import Foundation
import struct Flux.Flux
import PrismStorage

/// Domain entity representing a user profile with synthetic attributes.
public struct UserProfile: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public var name: String
    public var email: String
    public var avatarURL: URL?
    public var role: String

    public init(
        id: String,
        name: String,
        email: String,
        avatarURL: URL? = nil,
        role: String = "Member"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.role = role
    }
}

/// Example repository managing user profile persistence, caching, and synthetic network fetching.
public final class ProfileRepository: Sendable {
    public static let shared = ProfileRepository()

    private let repository: Repository<String, UserProfile>

    public init(
        httpClient: HTTPClient? = nil,
        cacheNamespace: String = "profiles",
        transport: any HTTPTransport = MockHTTPTransport()
    ) {
        let client = httpClient ?? HTTPClient(transport: transport)
        self.repository = Repository(
            namespace: cacheNamespace,
            remoteFetch: { userID in
                if let httpClient = httpClient ?? (transport is MockHTTPTransport ? nil : client) {
                    return try await httpClient.send(HTTPRequest(path: "/users/\(userID)"))
                }
                // Synthetic network resolution without real external credentials or endpoints
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms simulated latency
                return UserProfile(
                    id: userID,
                    name: "Alex Rivera",
                    email: "alex.rivera@example.com",
                    avatarURL: URL(string: "https://example.com/avatars/\(userID).png"),
                    role: "Design Lead"
                )
            },
            remoteSave: { _, _ in
                try await Task.sleep(nanoseconds: 5_000_000)
            },
            remoteDelete: { _ in
                try await Task.sleep(nanoseconds: 5_000_000)
            }
        )
    }

    /// Fetches a profile according to the specified fetch strategy.
    public func getProfile(id: String, strategy: FetchStrategy = .cacheFirst) async throws -> UserProfile {
        try await repository.fetch(key: id, strategy: strategy)
    }

    /// Observes real-time and cached profile updates.
    public func observeProfile(id: String, strategy: FetchStrategy = .cacheAndNetwork) -> Flux<UserProfile> {
        repository.observe(key: id, strategy: strategy)
    }

    /// Updates a user profile.
    public func updateProfile(_ profile: UserProfile) async throws {
        try await repository.save(profile, for: profile.id)
    }
}

/// Reactive domain store holding active user profile state, emitting changes strictly through Flux.
public actor ProfileStore {
    public static let shared = ProfileStore()

    private let store: Store<UserProfile?>

    public var state: UserProfile? {
        get async {
            await store.state
        }
    }

    public nonisolated var stateFlux: Flux<UserProfile?> {
        store.stateFlux
    }

    public init(initialProfile: UserProfile? = nil) {
        self.store = Store(initialState: initialProfile)
    }

    public func update(_ profile: UserProfile?) async {
        await store.update(profile)
    }

    public func mutate(_ mutation: @Sendable (inout UserProfile?) -> Void) async {
        await store.mutate(mutation)
    }

    /// Asynchronously reloads profile data into the store using `ProfileRepository`.
    public func load(userID: String, repository: ProfileRepository = .shared) async {
        if let profile = try? await repository.getProfile(id: userID, strategy: .cacheFirst) {
            await store.update(profile)
        }
    }
}
