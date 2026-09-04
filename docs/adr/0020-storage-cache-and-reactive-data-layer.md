# ADR 0020: Storage, Cache, and Reactive Data Layer

## Status
Accepted

## Context
Cross-platform UI applications built with Prism require persistence, multi-tier caching, and network communication layers that satisfy strict architectural boundaries:
1. **Module & Thread Isolation:** Data persistence, disk caching, and network transport must be decoupled from UI rendering layers (`PrismUI` must never import Data/Storage; data mutations occur off the MainActor or inside dedicated actors, while UI subscriptions receive immutable snapshots via Flux streams).
2. **Credential Security & Privacy:** Authentication tokens, session cookies, and API keys must be isolated strictly within the platform Keychain (`SecureStore`) and never leak into `UserDefaults`, disk caches, diagnostic metrics, or console logs.
3. **Resilient Network Transport:** Mobile and desktop environments experience network intermittency, dropped connections, and server throttling. HTTP and WebSocket clients must support structured retry policies with exponential backoff and jitter, header redaction, and deterministic test doubles.
4. **Multi-Tier Reactive Data Flow:** Domain entities require seamless synchronization between fast in-memory LRU caching, persistent disk caching, and remote backends (`Repository`), coupled with observable single-source-of-truth domain stores (`Store<State>`) emitting state transitions strictly through Flux.

## Decision

1. **`PrismStorage` Persistence Subsystem:**
   - **Typed Preferences:** `Preferences` wraps `UserDefaults` providing type-safe key-value access via `PrefKey<Value: Codable & Sendable>` and `@Preference` property wrapper bindings with reactive Flux change streams.
   - **Secure Store:** `SecureStore` wraps platform Keychain APIs (`kSecClassGenericPassword`), enforcing accessibility levels (`.afterFirstUnlock`, `.whenUnlocked`), namespaced service isolation, and zero log leakage.
   - **Atomic File Store:** `FileStore` actor provides thread-safe atomic writes (`Data.write(to:options:.atomic)`), directory creation, corruption recovery, and `FileWatcher` broadcasting file change events via `Flux<FileChangeEvent>`.
   - **Two-Tier Composite Cache:**
     - `MemoryLRUCache<Key, Value>`: O(1) doubly-linked list LRU eviction with cost limits, item count limits, and TTL expiration.
     - `DiskCache`: Actor-isolated persistent disk cache scoped strictly to the sandbox directory, enforcing size-budget pruning and TTL eviction.
     - `HybridCache<Key, Value>`: Coordinates L1 memory LRU and L2 disk persistence, automatically promoting disk hits into fast memory.

2. **`PrismData` Networking & Realtime Subsystem:**
   - **Pure HTTP Value Models:** `HTTPRequest` (with fluent builders) and `HTTPResponse` (with status verification and `decode()` helpers).
   - **Transport Abstraction:** `HTTPTransport` protocol allowing transparent substitution with `URLSessionTransport` in production or `MockHTTPTransport` in tests.
   - **Resilient HTTP Client:** `HTTPClient` supporting base URL resolution, request interceptor chains (`HTTPRequestInterceptor`, `BearerTokenInterceptor`), automatic retries (`RetryPolicy`) with exponential backoff and randomized jitter, and universal credential redaction (`HeaderSanitizer`).
   - **Resilient WebSocket Client:** `WebSocketClient` built on `URLSessionWebSocketTask`, featuring connection state tracking (`WebSocketState`), exponential reconnect loops (`ReconnectPolicy`), and reactive `Flux<WebSocketMessage>` streams.
   - **Reactive Repository & Store:**
     - `Repository<Key, Entity>` orchestrates `HybridCache` and remote fetching according to explicit `FetchStrategy` options (`.cacheOnly`, `.networkOnly`, `.cacheFirst`, `.networkFirst`, `.cacheAndNetwork`).
     - `Store<State>` actor provides isolated state mutations (`update`, `mutate`) and publishes transitions strictly via `Flux<State>` without any UI framework dependencies.

3. **Domain Reference Implementation & Test Doubles:**
   - `MockHTTPTransport` and `MockWebSocketTransport` enable 100% offline, deterministic unit and integration testing without external network endpoints.
   - `UserProfile`, `ProfileRepository`, and `ProfileStore` demonstrate end-to-end domain caching and reactive binding using synthetic non-sensitive data.

## Consequences
- **Positive:** Full decoupling between data persistence/networking and UI components, honoring `MODULE_CONTRACT.md`.
- **Positive:** Zero credential leakage: auth tokens and sensitive headers are redacted in all logs and diagnostics.
- **Positive:** Thread-safe, actor-isolated disk and file operations prevent race conditions and corruption.
- **Positive:** Deterministic testability across all networking, caching, and repository flows using test doubles.
