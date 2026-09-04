import XCTest
import Foundation
@testable import PrismStorage
import struct Flux.Flux

final class PreferencesTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var preferences: Preferences!

    override func setUp() {
        super.setUp()
        suiteName = "test.preferences.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        preferences = Preferences(userDefaults: userDefaults, suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testBasicGetAndSet() {
        let key = PrefKey<String>(name: "username", defaultValue: "guest")

        XCTAssertEqual(preferences.get(key), "guest")

        preferences.set("alice", for: key)
        XCTAssertEqual(preferences.get(key), "alice")

        preferences.remove(key)
        XCTAssertEqual(preferences.get(key), "guest")
    }

    func testTypedPrimitives() {
        let intKey = PrefKey<Int>(name: "count", defaultValue: 0)
        let boolKey = PrefKey<Bool>(name: "enabled", defaultValue: false)
        let doubleKey = PrefKey<Double>(name: "scale", defaultValue: 1.0)

        preferences.set(42, for: intKey)
        preferences.set(true, for: boolKey)
        preferences.set(2.5, for: doubleKey)

        XCTAssertEqual(preferences.get(intKey), 42)
        XCTAssertEqual(preferences.get(boolKey), true)
        XCTAssertEqual(preferences.get(doubleKey), 2.5)
    }

    func testCodableSupport() {
        struct Settings: Codable, Equatable {
            var theme: String
            var notifications: Bool
        }

        let key = PrefKey<Settings>(name: "settings", defaultValue: Settings(theme: "light", notifications: false))

        XCTAssertEqual(preferences.get(key), Settings(theme: "light", notifications: false))

        let updated = Settings(theme: "dark", notifications: true)
        preferences.set(updated, for: key)
        XCTAssertEqual(preferences.get(key), updated)
    }

    func testObservationViaFlux() async {
        let key = PrefKey<Int>(name: "counter", defaultValue: 0)
        let stream = preferences.observe(key)

        let expectation = expectation(description: "Emitted new value")
        var receivedValues: [Int] = []

        let task = Task {
            for await val in stream.stream {
                receivedValues.append(val)
                if receivedValues.count == 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Emit updates
        preferences.set(10, for: key)
        preferences.set(20, for: key)

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertEqual(receivedValues, [10, 20])
    }

    func testResetAll() {
        let key1 = PrefKey<String>(name: "k1", defaultValue: "def1")
        let key2 = PrefKey<Int>(name: "k2", defaultValue: 100)

        preferences.set("custom", for: key1)
        preferences.set(200, for: key2)

        preferences.resetAll()

        XCTAssertEqual(preferences.get(key1), "def1")
        XCTAssertEqual(preferences.get(key2), 100)
    }
}
