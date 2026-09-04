# Storage, Cache, and Reactive Data Layer Guide

Prism provides an enterprise-grade persistence, multi-tier caching, and network data layer split into two focused modules: `PrismStorage` and `PrismData`.

This guide covers setup, best practices, credential security, and reactive data patterns.

---

## Architecture & Boundary Invariants

1. **Strict Decoupling from Presentation:**
   - `PrismUI` does not import `PrismStorage` or `PrismData`.
   - Data operations run off the MainActor or inside dedicated actors (`FileStore`, `DiskCache`, `Store`).
   - Presentation layers receive state updates strictly as immutable snapshots via `Flux<T>` streams.
2. **Security & Redaction:**
   - Secrets and credentials must live exclusively in `SecureStore` (backed by the platform Keychain).
   - Sensitive headers (`Authorization`, `Cookie`, `X-API-Key`) are redacted in diagnostic output via `HeaderSanitizer`.
   - Synthetic fixtures and test doubles use mock values; zero real API keys or endpoints are embedded.

---

## 1. Persistence with `PrismStorage`

### Typed Preferences (`Preferences` & `PrefKey`)

Strongly-typed wrapper around `UserDefaults` with codable support and reactive Flux change streams:

```swift
import PrismStorage
import struct Flux.Flux

// 1. Define preference keys with typed defaults
enum AppPreferences {
    static let username = PrefKey<String>(name: "user_name", defaultValue: "Guest")
    static let enableHaptics = PrefKey<Bool>(name: "enable_haptics", defaultValue: true)
}

// 2. Read and write
let prefs = Preferences.standard
let current = prefs.get(AppPreferences.username)
prefs.set("Alice", for: AppPreferences.username)

// 3. Observe changes reactively
let stream = prefs.observe(AppPreferences.username)
Task {
    for await newName in stream.stream {
        print("Username updated: \(newName)")
    }
}

// 4. Declarative Property Wrapper
struct SettingsManager {
    @Preference(key: AppPreferences.username)
    var username: String
}
```

### Keychain Security (`SecureStore`)

Safe storage for tokens and credentials with platform accessibility levels:

```swift
import PrismStorage

let secureStore = SecureStore(service: "com.example.app.auth")

// Save token with accessibility policy
try secureStore.setString(
    "jwt_session_token_example",
    for: "auth_token",
    accessibility: .afterFirstUnlock
)

// Retrieve token
if let token = try secureStore.getString("auth_token") {
    print("Token retrieved")
}

// Scoped cleanup
try secureStore.remove("auth_token")
try secureStore.removeAll() // Scoped strictly to "com.example.app.auth"
```

### Atomic File Storage (`FileStore` & `FilePath`)

Actor-isolated file operations with atomic writes and directory management:

```swift
import PrismStorage

let fileStore = FileStore.shared
let path = FilePath.documents(subpath: "exports/report.json")

// Atomic write creates intermediate directories automatically
let data = "{\"status\": \"ok\"}".data(using: .utf8)!
try await fileStore.write(data, to: path)

// Read file
let retrieved = try await fileStore.read(at: path)

// Observe filesystem changes via Flux
let watcher = FileWatcher(path: path)
Task {
    for await event in watcher.flux.stream {
        switch event {
        case .modified: print("File modified on disk")
        case .deleted:  print("File deleted")
        case .renamed:  print("File renamed")
        }
    }
}
```

### Multi-Tier Caching (`HybridCache`)

Combines O(1) in-memory LRU caching with persistent disk caching:

```swift
import PrismStorage

struct CachedArticle: Codable, Equatable, Sendable {
    let id: String
    let title: String
}

let cache = HybridCache<String, CachedArticle>(
    namespace: "articles",
    memoryCostLimit: 32 * 1024 * 1024, // 32MB
    memoryCountLimit: 500,
    diskSizeLimit: 100 * 1024 * 1024   // 100MB
)

// Store in both memory (L1) and disk (L2)
let article = CachedArticle(id: "1", title: "Prism Storage Architecture")
await cache.set(article, for: "1", ttl: 3600) // 1 hour TTL

// Get: hits memory if available; if only on disk, promotes to memory automatically
if let hit = await cache.get("1") {
    print("Fetched: \(hit.title)")
}
```

---

## 2. Networking with `PrismData`

### HTTP Client with Interceptors and Exponential Retries

```swift
import PrismData

let client = HTTPClient(
    baseURL: URL(string: "https://api.example.com")!,
    transport: URLSessionTransport(), // or MockHTTPTransport() for unit tests
    interceptors: [
        BearerTokenInterceptor {
            try? SecureStore.standard.getString("auth_token")
        }
    ],
    retryPolicy: RetryPolicy(
        maxAttempts: 3,
        initialDelay: 0.2,
        maxDelay: 2.0,
        backoffMultiplier: 2.0,
        jitter: true
    )
)

// Fluent request construction
let request = HTTPRequest(path: "/users/me")
    .header("Accept", "application/json")
    .query("fields", "id,name,email")

// Send and decode directly
let profile: UserProfile = try await client.send(request)
```

### WebSocket Client with Automatic Reconnection

```swift
import PrismData

let wsClient = WebSocketClient(
    url: URL(string: "wss://api.example.com/events")!,
    reconnectPolicy: ReconnectPolicy(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 10.0,
        backoffMultiplier: 1.5,
        jitter: true
    )
)

// Observe connection state
Task {
    for await state in wsClient.state.stream {
        switch state {
        case .disconnected: print("Disconnected")
        case .connecting:   print("Connecting...")
        case .connected:    print("Connected")
        case .reconnecting(let attempt): print("Reconnecting (attempt \(attempt))...")
        case .failed(let err): print("Failed: \(err)")
        }
    }
}

// Observe incoming messages
Task {
    for await message in wsClient.messages.stream {
        switch message {
        case .string(let text): print("Received text: \(text)")
        case .data(let raw):    print("Received binary: \(raw.count) bytes")
        }
    }
}

wsClient.connect()
```

---

## 3. Reactive Repository and Domain Store

### `Repository<Key, Entity>` and `FetchStrategy`

Orchestrates multi-tier cache and remote network fetching:

```swift
import PrismData
import PrismStorage

let repository = Repository<String, UserProfile>(
    namespace: "users",
    remoteFetch: { userId in
        try await client.send(HTTPRequest(path: "/users/\(userId)"))
    }
)

// 1. Immediate cache fetch
let cached = try await repository.fetch(key: "usr_1", strategy: .cacheFirst)

// 2. Fresh network fetch
let fresh = try await repository.fetch(key: "usr_1", strategy: .networkFirst)

// 3. Reactive stream: yields cached version first, then yields fresh network update
let profileStream = repository.observe(key: "usr_1", strategy: .cacheAndNetwork)
Task {
    for await profile in profileStream.stream {
        print("Received profile state: \(profile.name)")
    }
}
```

### Reactive `Store<State>` Actor

State container isolating mutations and broadcasting changes via `Flux`:

```swift
import PrismData

struct FeedState: Sendable {
    var items: [String] = []
    var isRefreshing: Bool = false
}

actor FeedStore {
    private let store = Store<FeedState>(initialState: FeedState())

    var state: FeedState {
        get async { await store.state }
    }

    nonisolated var stateFlux: Flux<FeedState> {
        store.stateFlux
    }

    func setRefreshing(_ refreshing: Bool) async {
        await store.mutate { $0.isRefreshing = refreshing }
    }

    func appendItems(_ newItems: [String]) async {
        await store.mutate {
            $0.items.append(contentsOf: newItems)
            $0.isRefreshing = false
        }
    }
}
```

---

## 4. Testing & Mocks

All networking and data repositories can be tested 100% offline using `MockHTTPTransport` and `MockWebSocketTransport`:

```swift
import XCTest
import PrismData

final class UserTests: XCTestCase {
    func testProfileFetch() async throws {
        let mockTransport = MockHTTPTransport()
        mockTransport.stub(
            urlPattern: "api.example.com/users/u1",
            response: HTTPResponse(statusCode: 200, headers: [:], body: "{\"id\":\"u1\",\"name\":\"Sam\"}".data(using: .utf8)!)
        )

        let client = HTTPClient(baseURL: URL(string: "https://api.example.com")!, transport: mockTransport)
        let response: HTTPResponse = try await client.send(HTTPRequest(path: "/users/u1"))
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(mockTransport.sentRequests.count, 1)
    }
}
```
