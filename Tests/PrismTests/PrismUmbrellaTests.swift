import XCTest
import Prism

final class PrismUmbrellaTests: XCTestCase {
    func testUmbrellaExposesAllLayersWithoutSeparateImports() async {
        // PrismSDK
        XCTAssertEqual(PrismSDK.version, "0.1.0")

        // PrismCore (re-exported via PrismUI)
        let elementID = ElementID(typeName: "Stack", key: "root", siblingIndex: 0)
        XCTAssertEqual(elementID.description, "Stack[root]@0")

        // PrismUI
        XCTAssertFalse(PrismUI.layerDescription.isEmpty)

        // PrismData
        XCTAssertFalse(PrismData.layerDescription.isEmpty)

        // PrismStorage
        XCTAssertFalse(PrismStorage.layerDescription.isEmpty)

        // PrismLogging
        XCTAssertEqual(PrismLogging.subsystem, "dev.prism.ui")

        // Flux
        let count = CurrentValue(10)
        let resolved = await count.value
        XCTAssertEqual(resolved, 10)
    }
}
