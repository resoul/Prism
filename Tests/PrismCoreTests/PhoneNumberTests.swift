import XCTest
@testable import PrismCore

final class PhoneNumberTests: XCTestCase {
    func testInternationalAndLocalCanonicalFormatting() throws {
        let us = PhoneMetadata.country(code: "US")!
        let local = try PhoneNumber("(415) 555-2671", country: us)
        XCTAssertEqual(local.canonical, "+14155552671"); XCTAssertEqual(local.formatted(), "(415) 555-2671")
        XCTAssertEqual(try PhoneNumber("+40 721 123 456").canonical, "+40721123456")
    }
    func testInvalidLengthAndMissingCountry() {
        XCTAssertThrowsError(try PhoneNumber("555-12")) { XCTAssertEqual($0 as? PhoneNumberError, .missingCountry) }
        XCTAssertThrowsError(try PhoneNumber("123", country: PhoneMetadata.country(code: "US")!)) { XCTAssertEqual($0 as? PhoneNumberError, .invalidLength) }
    }
}
