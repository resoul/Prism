import XCTest
@testable import PrismData
import PrismStorage
import Flux

final class PrismDataTests: XCTestCase {
    func testDataLayerDescription() {
        XCTAssertFalse(PrismData.layerDescription.isEmpty)
    }

    func testPrismDataDependencies() async {
        // PrismData depends on PrismStorage and Flux
        XCTAssertFalse(PrismStorage.layerDescription.isEmpty)
        let state = CurrentValue(true)
        let resolved = await state.value
        XCTAssertTrue(resolved)
    }
}
