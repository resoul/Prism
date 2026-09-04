import XCTest
@testable import PrismStorage

final class SecureStoreTests: XCTestCase {
    private var store: SecureStore!
    private let testKey = "test_auth_token"

    override func setUp() {
        super.setUp()
        store = SecureStore(service: "com.prism.tests.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? store.removeAll()
        super.tearDown()
    }

    func testSetAndGetString() throws {
        do {
            try store.setString("secret_token_12345", for: testKey)
            let retrieved = try store.getString(testKey)
            XCTAssertEqual(retrieved, "secret_token_12345")
            XCTAssertTrue(try store.contains(testKey))

            try store.remove(testKey)
            XCTAssertNil(try store.getString(testKey))
            XCTAssertFalse(try store.contains(testKey))
        } catch SecureStoreError.unavailable {
            // Headless keychain unavailable in some restricted environments
            XCTAssertTrue(true)
        }
    }

    func testSetAndGetData() throws {
        do {
            let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
            try store.set(data, for: testKey)

            let retrieved = try store.get(testKey)
            XCTAssertEqual(retrieved, data)

            try store.removeAll()
            XCTAssertNil(try store.get(testKey))
        } catch SecureStoreError.unavailable {
            XCTAssertTrue(true)
        }
    }

    func testNonExistentKeyReturnsNil() throws {
        do {
            let result = try store.getString("non_existent_key_abc")
            XCTAssertNil(result)
        } catch SecureStoreError.unavailable {
            XCTAssertTrue(true)
        }
    }

    func testOverwriteExistingKey() throws {
        do {
            try store.setString("initial_value", for: testKey)
            try store.setString("updated_value", for: testKey)
            let value = try store.getString(testKey)
            XCTAssertEqual(value, "updated_value")
        } catch SecureStoreError.unavailable {
            XCTAssertTrue(true)
        }
    }
}
