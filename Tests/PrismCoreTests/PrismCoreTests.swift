import XCTest
@testable import PrismCore
import Flux

final class PrismCoreTests: XCTestCase {
    func testElementIDFormatting() {
        let idWithoutKey = ElementID(typeName: "Text", key: nil, siblingIndex: 0)
        XCTAssertEqual(idWithoutKey.description, "Text@0")

        let idWithKey = ElementID(typeName: "Card", key: "primary", siblingIndex: 2)
        XCTAssertEqual(idWithKey.description, "Card[primary]@2")
    }

    func testElementIDEquality() {
        let id1 = ElementID(typeName: "Stack", key: "header", siblingIndex: 1)
        let id2 = ElementID(typeName: "Stack", key: "header", siblingIndex: 1)
        let id3 = ElementID(typeName: "Stack", key: "header", siblingIndex: 2)
        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)
    }

    func testFluxAvailableInCore() async {
        let value = CurrentValue(42)
        let resolved = await value.value
        XCTAssertEqual(resolved, 42)
    }
}
