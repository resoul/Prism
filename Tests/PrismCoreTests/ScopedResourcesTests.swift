import XCTest
@testable import PrismCore

final class ScopedResourcesTests: XCTestCase {
    func testClipboardDenialAndRevocation() async throws {
        let clipboard = ClipboardStore(initialValue: "safe", allowed: false)
        do { _ = try await clipboard.read(); XCTFail("read should be denied") }
        catch let error as ScopedResourceError { XCTAssertEqual(error, .permissionDenied) }
        catch { XCTFail("unexpected error: \(error)") }
        await clipboard.grant(); try await clipboard.write("updated")
        let updated = try await clipboard.read()
        XCTAssertEqual(updated, "updated")
        await clipboard.revoke()
        do { _ = try await clipboard.read(); XCTFail("read should be denied after revocation") }
        catch let error as ScopedResourceError { XCTAssertEqual(error, .revoked) }
        catch { XCTFail("unexpected error: \(error)") }
    }

    func testScopedFileCloseRevokeAndCancellation() async throws {
        let handle = ScopedFileHandle(data: Data("payload".utf8))
        let payload = try await handle.read()
        XCTAssertEqual(payload, Data("payload".utf8))
        await handle.cancel()
        do { _ = try await handle.read(); XCTFail("read should fail after cancellation") }
        catch let error as ScopedResourceError { XCTAssertEqual(error, .closed) }
        catch { XCTFail("unexpected error: \(error)") }
        await handle.revoke()
        do { _ = try await handle.read(); XCTFail("read should fail after revocation") }
        catch let error as ScopedResourceError { XCTAssertEqual(error, .revoked) }
        catch { XCTFail("unexpected error: \(error)") }
    }
}
