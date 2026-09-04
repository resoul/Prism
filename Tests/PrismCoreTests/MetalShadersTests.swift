import XCTest
import Metal
import QuartzCore
import simd
@testable import PrismCore

final class MetalShadersTests: XCTestCase {
    func testShaderCompilationFromMSLSource() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is not available on this host environment.")
        }

        let pipelines = try MetalPipelines.build(device: device)
        XCTAssertNotNil(pipelines.sdfRectPipeline)
        XCTAssertNotNil(pipelines.glassPipeline)
        XCTAssertNotNil(pipelines.meshGradientPipeline)
    }

    func testUniformMemoryLayouts() {
        // Verify byte alignments and strides for SIMD/MSL compatibility
        XCTAssertEqual(MemoryLayout<SDFRectUniforms>.size, 48)
        XCTAssertEqual(MemoryLayout<GlassUniforms>.size, 32)
        XCTAssertEqual(MemoryLayout<MetalMeshPoint>.size, 32)
        XCTAssertEqual(MemoryLayout<MeshGradientUniforms>.size, 16)
    }

    @MainActor
    func testMetalLayerLifecycleAndResize() {
        let context = MetalDeviceContext.shared
        guard context.isSupported else { return }

        let layer = MetalLayer(context: context)
        XCTAssertEqual(layer.metalLayer.pixelFormat, .bgra8Unorm)

        layer.updateFrame(CGRect(x: 0, y: 0, width: 200, height: 100), contentsScale: 2.0)
        XCTAssertEqual(layer.metalLayer.drawableSize, CGSize(width: 400, height: 200))

        // Scale update to 3.0
        layer.updateFrame(CGRect(x: 0, y: 0, width: 200, height: 100), contentsScale: 3.0)
        XCTAssertEqual(layer.metalLayer.drawableSize, CGSize(width: 600, height: 300))

        // Clean purge
        layer.purgeResources()
        XCTAssertNil(layer.nextDrawable())
    }

    @MainActor
    func testMetalEffectRendererFallbackWhenUnsupported() {
        let testContext = MetalDeviceContext()
        testContext.setSimulatedUnsupported(true)

        let renderer = MetalEffectRenderer(elementID: ElementID(typeName: "Card"), context: testContext)

        // 1. SDF fallback
        let sdfElement = RenderElement(
            id: ElementID(typeName: "SDFCard"),
            kind: .custom("Card"),
            modifiers: [.sdfRoundedRect(cornerRadius: 16, borderWidth: 2, borderColor: .white, fill: .black)]
        )
        let frame = LayoutFrame(x: 0, y: 0, width: 150, height: 80)
        renderer.update(element: sdfElement, frame: frame, context: .default)


        XCTAssertEqual(renderer.rootLayer.cornerRadius, 16)
        XCTAssertEqual(renderer.rootLayer.borderWidth, 2)
        XCTAssertEqual(renderer.rootLayer.backgroundColor, Color.black.cgColor)

        // 2. Glassmorphism fallback
        let glassElement = RenderElement(
            id: ElementID(typeName: "GlassCard"),
            kind: .custom("Card"),
            modifiers: [.glassmorphism(blurRadius: 20, tint: Color(red: 1, green: 1, blue: 1, alpha: 0.5), saturation: 1.0)]
        )
        renderer.update(element: glassElement, frame: frame, context: .default)
        XCTAssertEqual(renderer.rootLayer.cornerRadius, 12)
        XCTAssertEqual(renderer.rootLayer.backgroundColor, Color(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor)

        // 3. Destroy cleanup
        renderer.destroy()
    }
}
