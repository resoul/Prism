import XCTest
@testable import PrismStorage
import Flux

final class PrismStorageTests: XCTestCase {
    func testStorageLayerDescription() {
        XCTAssertFalse(PrismStorage.layerDescription.isEmpty)
    }

    func testFluxAvailableInStorage() async {
        let store = CurrentValue("cached-token")
        let resolved = await store.value
        XCTAssertEqual(resolved, "cached-token")
    }
}
