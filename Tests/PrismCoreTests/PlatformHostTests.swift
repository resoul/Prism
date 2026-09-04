import XCTest
import QuartzCore
@testable import PrismCore
@testable import PrismUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PlatformHostTests: XCTestCase {

    // MARK: - 1. Host Engine Mount and Layout Pass

    func testHostEngineMountAndLayout() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let containerLayer = CALayer()
        containerLayer.bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

        engine.bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        engine.mount(in: containerLayer)

        XCTAssertEqual(engine.rootRenderer.rootLayer.superlayer, containerLayer)
        XCTAssertNotNil(engine.rootLayoutNode)
        XCTAssertEqual(engine.rootLayoutNode?.layoutFrame?.width, 390)

        // Verify layer hierarchy contains multiple children (text, shapes, spacer)
        let totalLayers = LayerDiagnostics.totalLayerCount(containerLayer)
        XCTAssertGreaterThan(totalLayers, 5)
    }

    // MARK: - 2. Repeated Host Creation and Destruction (20 Cycles)

    func testRepeatedCreateDestroyHostHarness() {
        for _ in 1...20 {
            let root = SmokeScene.makeRoot()
            let engine = PrismHostEngine(rootElement: root)
            let hostLayer = CALayer()
            hostLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
            engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 600)

            engine.mount(in: hostLayer)
            XCTAssertEqual(hostLayer.sublayers?.count, 1)

            engine.teardown()
            XCTAssertNil(hostLayer.sublayers?.first { $0 === engine.rootRenderer.rootLayer })
            XCTAssertEqual(engine.rootRenderer.childRenderers.count, 0)
        }
    }

    // MARK: - 3. Dynamic Bounds Resizing

    func testHostEngineBoundsResize() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()

        // Phone portrait
        engine.bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        engine.mount(in: hostLayer)
        XCTAssertEqual(engine.rootLayoutNode?.layoutFrame?.width, 390)

        // Window expansion / rotation
        engine.bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        XCTAssertEqual(engine.rootLayoutNode?.layoutFrame?.width, 800)
    }

    // MARK: - 4. Safe Area Inset Application

    func testHostEngineSafeAreaInsets() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()

        engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        engine.safeAreaInsets = DirectionalEdgeInsets(top: 44, leading: 16, bottom: 34, trailing: 16)
        engine.mount(in: hostLayer)

        guard let frame = engine.rootLayoutNode?.layoutFrame else {
            XCTFail("Missing root layout frame")
            return
        }

        XCTAssertEqual(frame.origin.x, 16)
        XCTAssertEqual(frame.origin.y, 44)
        XCTAssertEqual(frame.width, 368) // 400 - 16 - 16
        XCTAssertEqual(frame.height, 722) // 800 - 44 - 34
    }

    // MARK: - 5. Color Scheme Updates

    func testHostEngineColorSchemeChange() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()

        engine.bounds = CGRect(x: 0, y: 0, width: 300, height: 500)
        engine.colorScheme = .light
        engine.mount(in: hostLayer)

        XCTAssertEqual(engine.colorScheme, .light)

        engine.colorScheme = .dark
        XCTAssertEqual(engine.colorScheme, .dark)
    }

    // MARK: - 6. Scale Factor Propagation

    func testHostEngineScaleFactorChange() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()

        engine.bounds = CGRect(x: 0, y: 0, width: 300, height: 500)
        engine.scaleFactor = 1.0
        engine.mount(in: hostLayer)

        engine.scaleFactor = 3.0
        XCTAssertEqual(engine.scaleFactor, 3.0)
    }

    // MARK: - 7. Inspector Overlay Toggle

    func testInspectorOverlayToggle() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 300, height: 500)
        engine.bounds = hostLayer.bounds
        engine.mount(in: hostLayer)

        XCTAssertFalse(engine.isInspectorOverlayEnabled)
        XCTAssertNil(engine.inspectorLayer.superlayer)

        // Enable inspector
        engine.isInspectorOverlayEnabled = true
        XCTAssertNotNil(engine.inspectorLayer.superlayer)
        XCTAssertGreaterThan(engine.inspectorLayer.sublayers?.count ?? 0, 0)

        // Disable inspector
        engine.isInspectorOverlayEnabled = false
        XCTAssertNil(engine.inspectorLayer.superlayer)
    }

    // MARK: - 8. Diagnostics Dump

    func testDiagnosticsDump() {
        let root = SmokeScene.makeRoot()
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 300, height: 500)
        engine.bounds = hostLayer.bounds
        engine.mount(in: hostLayer)

        let dump = engine.dumpDiagnostics()
        XCTAssertTrue(dump.contains("Prism Host Diagnostics"))
        XCTAssertTrue(dump.contains("Element Tree"))
        XCTAssertTrue(dump.contains("Layout Trace"))
        XCTAssertTrue(dump.contains("CALayer Tree"))
        XCTAssertTrue(dump.contains("Total Layers:"))
    }

    // MARK: - 9. Platform Host View Bridge

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func testHostNSViewBridge() {
        let root = SmokeScene.makeRoot()
        let hostView = HostNSView(element: root)

        var boundsChanged = false
        hostView.onBoundsChange = { _ in boundsChanged = true }

        hostView.frame = CGRect(x: 0, y: 0, width: 500, height: 400)
        hostView.layout()

        XCTAssertTrue(boundsChanged)
        XCTAssertEqual(hostView.engine.bounds.width, 500)

        hostView.isInspectorOverlayEnabled = true
        XCTAssertTrue(hostView.engine.isInspectorOverlayEnabled)

        hostView.teardown()
    }
    #endif

    #if canImport(UIKit)
    func testHostUIViewBridge() {
        let root = SmokeScene.makeRoot()
        let hostView = HostUIView(element: root)

        var boundsChanged = false
        hostView.onBoundsChange = { _ in boundsChanged = true }

        hostView.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        hostView.layoutSubviews()

        XCTAssertTrue(boundsChanged)
        XCTAssertEqual(hostView.engine.bounds.width, 375)

        hostView.isInspectorOverlayEnabled = true
        XCTAssertTrue(hostView.engine.isInspectorOverlayEnabled)

        hostView.teardown()
    }
    #endif

}
