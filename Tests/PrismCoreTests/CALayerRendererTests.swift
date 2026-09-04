import XCTest
import QuartzCore
@testable import PrismCore

@MainActor
final class CALayerRendererTests: XCTestCase {

    // MARK: - 1. Renderer Factory Mapping

    func testRendererFactoryMapping() {
        let textElement = RenderElement(
            id: ElementID(typeName: "Text", key: "title"),
            kind: .text("Hello Prism")
        )
        let shapeElement = RenderElement(
            id: ElementID(typeName: "Shape", key: "rect"),
            kind: .shape(.rectangle(cornerRadius: 8))
        )
        let stackElement = RenderElement(
            id: ElementID(typeName: "Stack", key: "stack"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 10)
        )

        let textRenderer = RendererFactory.create(for: textElement)
        let shapeRenderer = RendererFactory.create(for: shapeElement)
        let stackRenderer = RendererFactory.create(for: stackElement)

        XCTAssertTrue(textRenderer is TextRenderer)
        XCTAssertTrue(shapeRenderer is ShapeRenderer)
        XCTAssertTrue(stackRenderer is ContainerRenderer)
        XCTAssertTrue(textRenderer.rootLayer is CATextLayer)
    }

    // MARK: - 2. P0 Scene Layer Hierarchy and Frames

    func testP0SceneHierarchyAndFrames() {
        let containerElement = RenderElement(
            id: ElementID(typeName: "Container", key: "root"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 8)
        )
        let containerRenderer = ContainerRenderer(elementID: containerElement.id)
        let rootFrame = LayoutFrame(x: 0, y: 0, width: 320, height: 480)
        containerRenderer.update(element: containerElement, frame: rootFrame, context: .default)

        XCTAssertEqual(containerRenderer.rootLayer.bounds, CGRect(x: 0, y: 0, width: 320, height: 480))
        XCTAssertEqual(containerRenderer.rootLayer.position, CGPoint(x: 160, y: 240))

        let titleElement = RenderElement(
            id: ElementID(typeName: "Text", key: "title"),
            kind: .text("Prism Title")
        ).background(Color(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0))

        let rectElement = RenderElement(
            id: ElementID(typeName: "Shape", key: "rect"),
            kind: .shape(.rectangle(cornerRadius: 12))
        ).background(Color(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0))

        let circleElement = RenderElement(
            id: ElementID(typeName: "Shape", key: "circle"),
            kind: .shape(.circle)
        ).background(Color(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0))

        let children: [(RenderElement, LayoutFrame)] = [
            (titleElement, LayoutFrame(x: 16, y: 16, width: 288, height: 40)),
            (rectElement, LayoutFrame(x: 16, y: 64, width: 100, height: 100)),
            (circleElement, LayoutFrame(x: 130, y: 64, width: 60, height: 60))
        ]

        containerRenderer.updateChildren(children: children, context: .default)

        XCTAssertEqual(containerRenderer.childRenderers.count, 3)
        XCTAssertEqual(containerRenderer.rootLayer.sublayers?.count, 3)

        // Title text layer checks
        guard let titleRenderer = containerRenderer.childRenderers[titleElement.id] as? TextRenderer else {
            XCTFail("Missing title renderer")
            return
        }
        XCTAssertEqual(titleRenderer.textLayer.bounds, CGRect(x: 0, y: 0, width: 288, height: 40))
        XCTAssertEqual(titleRenderer.textLayer.position, CGPoint(x: 160, y: 36))

        // Rect shape layer checks
        guard let rectRenderer = containerRenderer.childRenderers[rectElement.id] as? ShapeRenderer else {
            XCTFail("Missing rect renderer")
            return
        }
        XCTAssertEqual(rectRenderer.rootLayer.cornerRadius, 12)
        XCTAssertEqual(rectRenderer.rootLayer.bounds, CGRect(x: 0, y: 0, width: 100, height: 100))

        // Circle shape layer checks
        guard let circleRenderer = containerRenderer.childRenderers[circleElement.id] as? ShapeRenderer else {
            XCTFail("Missing circle renderer")
            return
        }
        XCTAssertEqual(circleRenderer.rootLayer.cornerRadius, 30) // min(60, 60) / 2
    }

    // MARK: - 3. Idempotent Re-Render (Zero Duplicate Layers / Zero Leaks)

    func testIdempotentReRenderZeroDuplicateLayers() {
        let containerElement = RenderElement(
            id: ElementID(typeName: "Container", key: "root"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 8)
        )
        let containerRenderer = ContainerRenderer(elementID: containerElement.id)
        let rootFrame = LayoutFrame(x: 0, y: 0, width: 300, height: 300)
        containerRenderer.update(element: containerElement, frame: rootFrame, context: .default)

        let child1 = RenderElement(id: ElementID(typeName: "Text", key: "c1"), kind: .text("Item 1"))
        let child2 = RenderElement(id: ElementID(typeName: "Shape", key: "c2"), kind: .shape(.circle))
        let child3 = RenderElement(id: ElementID(typeName: "Shape", key: "c3"), kind: .shape(.rectangle(cornerRadius: 4)))

        let children: [(RenderElement, LayoutFrame)] = [
            (child1, LayoutFrame(x: 0, y: 0, width: 100, height: 20)),
            (child2, LayoutFrame(x: 0, y: 30, width: 40, height: 40)),
            (child3, LayoutFrame(x: 0, y: 80, width: 100, height: 50))
        ]

        // Initial render pass
        containerRenderer.updateChildren(children: children, context: .default)

        let initialSublayerCount = containerRenderer.rootLayer.sublayers?.count ?? 0
        let initialTotalLayerCount = LayerDiagnostics.totalLayerCount(containerRenderer.rootLayer)

        XCTAssertEqual(initialSublayerCount, 3)
        XCTAssertEqual(initialTotalLayerCount, 4) // Root + 3 children

        // Perform 100 repeated render passes with the identical tree
        for _ in 1...100 {
            containerRenderer.updateChildren(children: children, context: .default)
        }

        // Must strictly preserve layer count: zero accumulation, zero duplicate layers
        let postSublayerCount = containerRenderer.rootLayer.sublayers?.count ?? 0
        let postTotalLayerCount = LayerDiagnostics.totalLayerCount(containerRenderer.rootLayer)

        XCTAssertEqual(postSublayerCount, initialSublayerCount)
        XCTAssertEqual(postTotalLayerCount, initialTotalLayerCount)
    }

    // MARK: - 4. Dynamic Tree Mutations: Child Removal & Disposal

    func testDynamicChildRemovalAndDisposal() {
        let container = ContainerRenderer(elementID: ElementID(typeName: "Container", key: "root"))
        let child1 = RenderElement(id: ElementID(typeName: "Text", key: "c1"), kind: .text("Item 1"))
        let child2 = RenderElement(id: ElementID(typeName: "Text", key: "c2"), kind: .text("Item 2"))
        let child3 = RenderElement(id: ElementID(typeName: "Text", key: "c3"), kind: .text("Item 3"))

        let f = LayoutFrame(x: 0, y: 0, width: 50, height: 20)
        container.updateChildren(children: [(child1, f), (child2, f), (child3, f)], context: .default)

        XCTAssertEqual(container.rootLayer.sublayers?.count, 3)
        let removedLayer = container.childRenderers[child2.id]?.rootLayer
        XCTAssertNotNil(removedLayer?.superlayer)

        // Pass 2: Remove child2
        container.updateChildren(children: [(child1, f), (child3, f)], context: .default)

        XCTAssertEqual(container.rootLayer.sublayers?.count, 2)
        XCTAssertNil(container.childRenderers[child2.id])
        XCTAssertNil(removedLayer?.superlayer, "Removed child layer must be detached from superlayer")

        // Destroy container
        container.destroy()
        XCTAssertEqual(container.childRenderers.count, 0)
    }

    // MARK: - 5. Scale Factor / Retina Sharpness

    func testScaleFactorApplication() {
        let textElement = RenderElement(id: ElementID(typeName: "Text", key: "retina"), kind: .text("Hi"))
        let textRenderer = TextRenderer(elementID: textElement.id)
        let frame = LayoutFrame(x: 0, y: 0, width: 100, height: 30)

        // Scale @1x
        textRenderer.update(element: textElement, frame: frame, context: RenderContext(scaleFactor: 1.0))
        XCTAssertEqual(textRenderer.textLayer.contentsScale, 1.0)

        // Scale @2x (Retina)
        textRenderer.update(element: textElement, frame: frame, context: RenderContext(scaleFactor: 2.0))
        XCTAssertEqual(textRenderer.textLayer.contentsScale, 2.0)

        // Scale @3x (Super Retina)
        textRenderer.update(element: textElement, frame: frame, context: RenderContext(scaleFactor: 3.0))
        XCTAssertEqual(textRenderer.textLayer.contentsScale, 3.0)
    }

    // MARK: - 6. Sublayer Deterministic Z-Index Ordering

    func testSublayerZIndexOrdering() {
        let container = ContainerRenderer(elementID: ElementID(typeName: "Container", key: "root"))
        let f = LayoutFrame(x: 0, y: 0, width: 50, height: 20)

        let elemHigh = RenderElement(id: ElementID(typeName: "Text", key: "high"), kind: .text("High")).zIndex(100)
        let elemLow = RenderElement(id: ElementID(typeName: "Text", key: "low"), kind: .text("Low")).zIndex(5)
        let elemMid = RenderElement(id: ElementID(typeName: "Text", key: "mid"), kind: .text("Mid")).zIndex(50)

        // Added in order: High, Low, Mid
        container.updateChildren(children: [(elemHigh, f), (elemLow, f), (elemMid, f)], context: .default)

        // Sublayers must be sorted ascending by zPosition
        guard let sublayers = container.rootLayer.sublayers, sublayers.count == 3 else {
            XCTFail("Expected 3 sublayers")
            return
        }

        XCTAssertEqual(sublayers[0].zPosition, 5.0)
        XCTAssertEqual(sublayers[1].zPosition, 50.0)
        XCTAssertEqual(sublayers[2].zPosition, 100.0)
    }

    // MARK: - 7. Offscreen Rendering Hazard Diagnostics

    func testOffscreenRenderingHazardDetection() {
        let safeLayer = CALayer()
        safeLayer.masksToBounds = true
        XCTAssertFalse(LayerDiagnostics.hasOffscreenRenderingHazard(safeLayer))

        let shadowOnlyLayer = CALayer()
        shadowOnlyLayer.shadowOpacity = 0.5
        shadowOnlyLayer.shadowColor = CGColor(gray: 0, alpha: 1)
        XCTAssertFalse(LayerDiagnostics.hasOffscreenRenderingHazard(shadowOnlyLayer))

        let hazardLayer = CALayer()
        hazardLayer.masksToBounds = true
        hazardLayer.shadowOpacity = 0.5
        hazardLayer.shadowColor = CGColor(gray: 0, alpha: 1)
        XCTAssertTrue(LayerDiagnostics.hasOffscreenRenderingHazard(hazardLayer))

        let dumpStr = LayerDiagnostics.dumpLayerTree(hazardLayer)
        XCTAssertTrue(dumpStr.contains("offscreen-hazard"))
    }

    // MARK: - 8. Long Unicode Text & Alignment

    func testLongUnicodeTextAndWrapping() {
        let unicodeText = "Привет, мир! 🚀 Многострочный длинный текст на русском языке с эмодзи ✨ и символами."
        let textElement = RenderElement(
            id: ElementID(typeName: "Text", key: "unicode"),
            kind: .text(unicodeText),
            props: ElementProps(custom: ["alignment": "center"])
        )

        let renderer = TextRenderer(elementID: textElement.id)
        renderer.update(
            element: textElement,
            frame: LayoutFrame(x: 0, y: 0, width: 200, height: 100),
            context: .default
        )

        XCTAssertTrue(renderer.textLayer.isWrapped)
        XCTAssertEqual(renderer.textLayer.alignmentMode, .center)
        XCTAssertNotNil(renderer.textLayer.string)
    }
}
