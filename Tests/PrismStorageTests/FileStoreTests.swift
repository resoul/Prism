import XCTest
import Foundation
@testable import PrismStorage

final class FileStoreTests: XCTestCase {
    private var fileStore: FileStore!
    private var tempDirectoryName: String!

    override func setUp() async throws {
        try await super.setUp()
        fileStore = FileStore()
        tempDirectoryName = "prism_test_\(UUID().uuidString)"
    }

    override func tearDown() async throws {
        let testDir = FilePath.temporary(subpath: tempDirectoryName)
        try? await fileStore.delete(at: testDir)
        try await super.tearDown()
    }

    func testAtomicWriteAndReadData() async throws {
        let path = FilePath.temporary(subpath: "\(tempDirectoryName!)/data.bin")
        let sampleData = "Atomic Data Content".data(using: .utf8)!

        try await fileStore.write(sampleData, to: path)

        let exists = await fileStore.exists(at: path)
        XCTAssertTrue(exists)

        let readData = try await fileStore.read(at: path)
        XCTAssertEqual(readData, sampleData)
    }

    func testWriteStringAndReadString() async throws {
        let path = FilePath.temporary(subpath: "\(tempDirectoryName!)/text.txt")
        let text = "Hello from Prism Storage FileStore!"

        try await fileStore.writeString(text, to: path)

        let exists = await fileStore.exists(at: path)
        XCTAssertTrue(exists)

        let readText = try await fileStore.readString(at: path)
        XCTAssertEqual(readText, text)
    }

    func testDeleteFile() async throws {
        let path = FilePath.temporary(subpath: "\(tempDirectoryName!)/delete_me.txt")
        try await fileStore.writeString("to be deleted", to: path)

        let existsBefore = await fileStore.exists(at: path)
        XCTAssertTrue(existsBefore)

        try await fileStore.delete(at: path)
        let existsAfter = await fileStore.exists(at: path)
        XCTAssertFalse(existsAfter)
    }

    func testReadNonExistentThrowsNotFound() async {
        let path = FilePath.temporary(subpath: "\(tempDirectoryName!)/not_found.bin")

        do {
            _ = try await fileStore.read(at: path)
            XCTFail("Expected fileNotFound error")
        } catch let error as FileStoreError {
            if case .fileNotFound = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAutomaticDirectoryCreation() async throws {
        let deepPath = FilePath.temporary(subpath: "\(tempDirectoryName!)/nested/sub/folder/file.json")
        let json = "{\"status\": \"ok\"}"

        try await fileStore.writeString(json, to: deepPath)
        let exists = await fileStore.exists(at: deepPath)
        XCTAssertTrue(exists)

        let read = try await fileStore.readString(at: deepPath)
        XCTAssertEqual(read, json)
    }
}
