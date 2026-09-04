import XCTest
import PrismUI

final class PrismUITests: XCTestCase {
    func testPrismUIRexportsPrismCore() {
        // ElementID is defined in PrismCore and re-exported by PrismUI
        let elementID = ElementID(typeName: "Button", key: "action", siblingIndex: 0)
        XCTAssertEqual(elementID.typeName, "Button")
        XCTAssertEqual(elementID.key, "action")
        XCTAssertEqual(elementID.siblingIndex, 0)
    }

    func testPrismUIMarker() {
        XCTAssertFalse(PrismUI.layerDescription.isEmpty)
        XCTAssertEqual(PrimitivesSectionMarker.sectionName, "Primitives")
    }
}
