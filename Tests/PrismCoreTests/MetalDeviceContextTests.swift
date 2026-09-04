import XCTest
import Metal
@testable import PrismCore

final class MetalDeviceContextTests: XCTestCase {
    func testDeviceContextInitialization() {
        let context = MetalDeviceContext.shared

        // Should accurately report device availability on Apple platform
        let hasDevice = MTLCreateSystemDefaultDevice() != nil
        XCTAssertEqual(context.isSupported, hasDevice)

        if hasDevice {
            XCTAssertNotNil(context.device)
            XCTAssertNotNil(context.commandQueue)
        }
    }

    func testSimulatedUnsupportedFallbackToggle() {
        let context = MetalDeviceContext()
        XCTAssertTrue(context.isSupported)

        context.setSimulatedUnsupported(true)
        XCTAssertFalse(context.isSupported)
        XCTAssertNil(context.device)
        XCTAssertNil(context.commandQueue)

        context.setSimulatedUnsupported(false)
        XCTAssertTrue(context.isSupported)
    }

    func testAsyncPipelinePreparation() async {
        let context = MetalDeviceContext()
        guard context.isSupported else { return }

        let exp = expectation(description: "Pipelines compiled asynchronously")
        context.preparePipelinesAsync { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 5.0)
        XCTAssertNotNil(context.pipelines)
    }

    func testFrameBudgetLogging() {
        // Frame within budget
        MetalFrameBudget.recordFrameDuration(milliseconds: 8.5, effect: "TestSDF")

        // Frame exceeding 16.66ms budget (triggers warning log without crashing)
        MetalFrameBudget.recordFrameDuration(milliseconds: 24.2, effect: "HeavyMesh")
    }
}
