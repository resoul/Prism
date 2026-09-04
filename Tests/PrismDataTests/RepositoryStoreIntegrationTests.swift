import XCTest
import Foundation
@testable import PrismData
@testable import PrismStorage
import struct Flux.Flux

final class RepositoryStoreIntegrationTests: XCTestCase {

    struct Article: Codable, Equatable, Sendable {
        let id: String
        let title: String
    }

    func testRepositoryCacheFirstStrategy() async throws {
        let cache = HybridCache<String, Article>(
            namespace: "test_articles_\(UUID().uuidString)",
            memoryCostLimit: 1024,
            diskSizeLimit: 1024 * 1024
        )

        let initial = Article(id: "1", title: "Cached Title")
        await cache.set(initial, for: "1")

        final class CallCounter: @unchecked Sendable {
            private let lock = NSLock()
            private var count = 0
            func inc() { lock.withLock { count += 1 } }
            var value: Int { lock.withLock { count } }
        }

        let counter = CallCounter()
        let repo = Repository<String, Article>(
            cache: cache,
            remoteFetch: { key in
                counter.inc()
                return Article(id: key, title: "Network Title")
            }
        )

        // Fetch with cacheFirst should return cached item without hitting network
        let result = try await repo.fetch(key: "1", strategy: .cacheFirst)
        XCTAssertEqual(result.title, "Cached Title")
        XCTAssertEqual(counter.value, 0)
    }

    func testRepositoryNetworkFirstStrategy() async throws {
        let cache = HybridCache<String, Article>(
            namespace: "test_articles_net_\(UUID().uuidString)",
            memoryCostLimit: 1024,
            diskSizeLimit: 1024 * 1024
        )

        let cached = Article(id: "2", title: "Stale Title")
        await cache.set(cached, for: "2")

        let repo = Repository<String, Article>(
            cache: cache,
            remoteFetch: { key in
                Article(id: key, title: "Fresh Title")
            }
        )

        let result = try await repo.fetch(key: "2", strategy: .networkFirst)
        XCTAssertEqual(result.title, "Fresh Title")

        // Verify cache was updated
        let fromCache = await cache.get("2")
        XCTAssertEqual(fromCache?.title, "Fresh Title")
    }

    func testRepositoryObserveCacheAndNetwork() async throws {
        let cache = HybridCache<String, Article>(
            namespace: "test_articles_obs_\(UUID().uuidString)",
            memoryCostLimit: 1024,
            diskSizeLimit: 1024 * 1024
        )

        let cached = Article(id: "obs_1", title: "Cached Observation")
        await cache.set(cached, for: "obs_1")

        let repo = Repository<String, Article>(
            cache: cache,
            remoteFetch: { key in
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                return Article(id: key, title: "Network Observation")
            }
        )

        let stream = repo.observe(key: "obs_1", strategy: .cacheAndNetwork)

        let expectation = expectation(description: "Emitted cached then network")
        var received: [Article] = []

        let task = Task {
            for await article in stream.stream {
                received.append(article)
                if received.count == 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)
        task.cancel()

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].title, "Cached Observation")
        XCTAssertEqual(received[1].title, "Network Observation")
    }

    func testStoreStateMutationsAndFluxEmission() async {
        let store = Store<Int>(initialState: 0)
        let initial = await store.state
        XCTAssertEqual(initial, 0)

        let expectation = expectation(description: "Store emitted 2 state mutations")
        var receivedStates: [Int] = []

        let task = Task {
            for await state in store.stateFlux.stream {
                receivedStates.append(state)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Allow subscription to attach before mutations
        try? await Task.sleep(nanoseconds: 50_000_000)

        await store.update(10)
        await store.mutate { $0 += 5 }

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        let finalState = await store.state
        XCTAssertEqual(finalState, 15)
        XCTAssertEqual(receivedStates, [10, 15])
    }

    func testProfileRepositoryAndStoreDomainFlow() async throws {
        let mockTransport = MockHTTPTransport()
        let expectedProfile = UserProfile(id: "usr_42", name: "Alex", email: "alex@example.test")
        let encodedData = try JSONEncoder().encode(expectedProfile)

        mockTransport.stub(
            urlPattern: "api.example.test/users/usr_42",
            response: HTTPResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: encodedData)
        )

        let client = HTTPClient(baseURL: URL(string: "https://api.example.test")!, transport: mockTransport)
        let repo = ProfileRepository(
            httpClient: client,
            cacheNamespace: "profile_test_\(UUID().uuidString)"
        )

        let fetchedProfile = try await repo.getProfile(id: "usr_42", strategy: .networkFirst)
        XCTAssertEqual(fetchedProfile, expectedProfile)

        // Load into domain store
        let store = ProfileStore(initialProfile: nil)
        await store.update(fetchedProfile)

        let storeProfile = await store.state
        XCTAssertEqual(storeProfile?.name, "Alex")

        // Mutate store state
        await store.mutate { profile in
            profile?.name = "Alexander"
        }

        let updatedProfile = await store.state
        XCTAssertEqual(updatedProfile?.name, "Alexander")
    }
}
