import XCTest
@testable import PrismCore

final class AutocompleteTests: XCTestCase {
    func testOutOfOrderResponsesOnlyLatestGenerationWins() async throws {
        let engine = AutocompleteEngine<String>(debounceNanoseconds: 1) { text in
            if text == "old" { try await Task.sleep(nanoseconds: 80_000_000) }
            return [text.uppercased()]
        }
        await engine.update(text: "old"); await engine.update(text: "new")
        try await Task.sleep(nanoseconds: 120_000_000)
        let snapshot = await engine.snapshot()
        XCTAssertEqual(snapshot.text, "new"); XCTAssertEqual(snapshot.suggestions, ["NEW"]); XCTAssertFalse(snapshot.isLoading)
    }

    func testCancelClearsLoadingAndSuggestions() async throws {
        let engine = AutocompleteEngine<String>(debounceNanoseconds: 100_000_000) { _ in ["result"] }
        await engine.update(text: "query"); await engine.cancel()
        let snapshot = await engine.snapshot()
        XCTAssertEqual(snapshot.text, "query"); XCTAssertTrue(snapshot.suggestions.isEmpty); XCTAssertFalse(snapshot.isLoading)
    }
}
