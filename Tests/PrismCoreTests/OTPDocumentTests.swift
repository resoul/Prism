import XCTest
@testable import PrismCore

final class OTPDocumentTests: XCTestCase {
    func testPasteFiltersAndCapsValueWithoutLogging() {
        var document = OTPDocument(length: 6)
        XCTAssertTrue(document.paste("12-34 5678")); XCTAssertEqual(document.value, "123456"); XCTAssertTrue(document.isComplete)
        XCTAssertEqual(document.segments.compactMap { $0 }.count, 6)
    }
    func testBackspaceClearAndAutofillBoundary() {
        var document = OTPDocument(length: 4, value: "12")
        XCTAssertTrue(document.insert("3")); XCTAssertTrue(document.backspace()); XCTAssertEqual(document.value, "12")
        document.clear(); XCTAssertEqual(document.value, "")
        XCTAssertFalse(document.paste("abcd")); XCTAssertEqual(document.value, "")
    }
}
