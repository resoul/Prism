import XCTest
@testable import PrismCore

final class FileUploadTests: XCTestCase {
    func testValidationAndSuccessfulUpload() async throws {
        let coordinator = FileUploadCoordinator(maxBytes: 10, allowedMIMETypes: ["text/plain"]) { _ in }
        await coordinator.start(id: "ok", file: UploadFile(name: "note.txt", mimeType: "text/plain", data: Data("hello".utf8)))
        try await Task.sleep(nanoseconds: 10_000_000)
        let okStatus = await coordinator.status(for: "ok")
        XCTAssertEqual(okStatus, .succeeded)
        await coordinator.start(id: "bad", file: UploadFile(name: "../secret", mimeType: "text/plain", data: Data("x".utf8)))
        try await Task.sleep(nanoseconds: 10_000_000)
        let badStatus = await coordinator.status(for: "bad")
        XCTAssertEqual(badStatus, .failed(.invalidFilename))
    }
    func testDeniedTypeSizeAndCancellation() async throws {
        let coordinator = FileUploadCoordinator(maxBytes: 2, allowedMIMETypes: ["image/png"]) { _ in try await Task.sleep(nanoseconds: 1_000_000_000) }
        await coordinator.start(id: "type", file: UploadFile(name: "a.txt", mimeType: "text/plain", data: Data()))
        await coordinator.start(id: "size", file: UploadFile(name: "a.png", mimeType: "image/png", data: Data(repeating: 0, count: 3)))
        await coordinator.start(id: "cancel", file: UploadFile(name: "a.png", mimeType: "image/png", data: Data()))
        await coordinator.cancel(id: "cancel"); try await Task.sleep(nanoseconds: 10_000_000)
        let typeStatus = await coordinator.status(for: "type")
        let sizeStatus = await coordinator.status(for: "size")
        let cancelStatus = await coordinator.status(for: "cancel")
        XCTAssertEqual(typeStatus, .failed(.invalidType)); XCTAssertEqual(sizeStatus, .failed(.invalidSize)); XCTAssertEqual(cancelStatus, .cancelled)
    }
}
