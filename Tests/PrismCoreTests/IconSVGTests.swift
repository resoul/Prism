import XCTest
import CoreGraphics
import QuartzCore
@testable import PrismCore
@testable import PrismUI

final class IconSVGTests: XCTestCase {

    // MARK: - Path Parser Tests

    func testPathParserBasicCommands() {
        let pathString = "M 10 20 L 30 40 H 50 V 60 Z"
        let path = SVGPathParser.parse(pathString)
        XCTAssertFalse(path.isEmpty)
        let bounds = path.boundingBox
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
    }

    func testPathParserCubicAndQuadCurves() {
        let pathString = "M 0 0 C 10 20 30 40 50 50 S 70 80 100 100 Q 120 140 150 150 T 200 200 Z"
        let path = SVGPathParser.parse(pathString)
        XCTAssertFalse(path.isEmpty)
    }

    func testPathParserEllipticalArc() {
        let pathString = "M 10 80 A 45 45 0 0 0 125 125 Z"
        let path = SVGPathParser.parse(pathString)
        XCTAssertFalse(path.isEmpty)
        let bounds = path.boundingBox
        XCTAssertGreaterThan(bounds.width, 0)
    }

    func testPathParserRelativeCommands() {
        let pathString = "m 10 10 l 20 20 h 10 v 10 c 5 5 10 10 15 15 z"
        let path = SVGPathParser.parse(pathString)
        XCTAssertFalse(path.isEmpty)
    }

    // MARK: - SVG Parser Shape Tests

    func testParseBasicShapes() throws {
        let svg = """
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
            <rect x="10" y="10" width="30" height="40" rx="4" ry="4" fill="#FF0000" stroke="#000000" stroke-width="2"/>
            <circle cx="70" cy="30" r="20" fill="#00FF00"/>
            <ellipse cx="50" cy="80" rx="25" ry="15" fill="#0000FF"/>
            <line x1="0" y1="0" x2="100" y2="100" stroke="#FFFF00" stroke-width="1"/>
            <polyline points="0,0 20,40 40,20" fill="none" stroke="#FF00FF"/>
            <polygon points="50,50 60,70 40,70" fill="#00FFFF"/>
        </svg>
        """
        guard let data = svg.data(using: .utf8) else {
            XCTFail("Failed to encode SVG")
            return
        }

        let doc = try SVGParser.parse(data: data)
        XCTAssertEqual(doc.viewBox, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(doc.shapes.count, 6)

        let rectShape = doc.shapes[0]
        XCTAssertEqual(rectShape.fillColor, Color(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(rectShape.strokeWidth, 2.0)
    }

    func testGroupInheritance() throws {
        let svg = """
        <svg viewBox="0 0 200 200">
            <g fill="#AABBCC" stroke="#112233" stroke-width="3" opacity="0.5">
                <circle cx="50" cy="50" r="20"/>
                <circle cx="100" cy="100" r="20" fill="#FFAA00"/>
            </g>
        </svg>
        """
        guard let data = svg.data(using: .utf8) else {
            XCTFail("Failed to encode SVG")
            return
        }

        let doc = try SVGParser.parse(data: data)
        XCTAssertEqual(doc.shapes.count, 2)

        let c1 = doc.shapes[0]
        XCTAssertEqual(c1.fillColor, Color.hex("#AABBCC"))
        XCTAssertEqual(c1.strokeWidth, 3)
        XCTAssertEqual(c1.opacity, 0.5)

        let c2 = doc.shapes[1]
        XCTAssertEqual(c2.fillColor, Color.hex("#FFAA00"))
        XCTAssertEqual(c2.strokeWidth, 3)
        XCTAssertEqual(c2.opacity, 0.5)
    }

    // MARK: - Security & Rejection Tests

    func testRejectsScriptTag() {
        let svg = """
        <svg viewBox="0 0 100 100">
            <script>alert('pwned');</script>
            <circle cx="10" cy="10" r="5"/>
        </svg>
        """
        guard let data = svg.data(using: .utf8) else {
            XCTFail("Failed to encode SVG")
            return
        }

        XCTAssertThrowsError(try SVGParser.parse(data: data)) { error in
            guard let svgError = error as? SVGError else {
                XCTFail("Expected SVGError, got \(error)")
                return
            }
            if case .securityViolation(let reason) = svgError {
                XCTAssertTrue(reason.contains("script"))
            } else {
                XCTFail("Expected .securityViolation, got \(svgError)")
            }
        }
    }

    func testRejectsForeignObjectAndExternalEntities() {
        let svg = """
        <svg viewBox="0 0 100 100">
            <foreignObject width="50" height="50">
                <div>Attack</div>
            </foreignObject>
        </svg>
        """
        guard let data = svg.data(using: .utf8) else {
            XCTFail("Failed to encode SVG")
            return
        }

        XCTAssertThrowsError(try SVGParser.parse(data: data)) { error in
            guard let svgError = error as? SVGError else {
                XCTFail("Expected SVGError")
                return
            }
            if case .securityViolation(let reason) = svgError {
                XCTAssertTrue(reason.contains("foreignObject"))
            } else {
                XCTFail("Expected .securityViolation")
            }
        }
    }

    func testRejectsExternalHrefURL() {
        let svg = """
        <svg viewBox="0 0 100 100">
            <image href="https://example.com/leak.png" width="10" height="10"/>
        </svg>
        """
        guard let data = svg.data(using: .utf8) else {
            XCTFail("Failed to encode SVG")
            return
        }

        XCTAssertThrowsError(try SVGParser.parse(data: data)) { error in
            guard let svgError = error as? SVGError else {
                XCTFail("Expected SVGError")
                return
            }
            if case .securityViolation(let reason) = svgError {
                XCTAssertTrue(reason.lowercased().contains("external"))
            } else {
                XCTFail("Expected .securityViolation")
            }
        }
    }

    // MARK: - Fixture Tests

    func testFixturesLoading() throws {
        let fixtureDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/SVG")

        let starURL = fixtureDir.appendingPathComponent("star.svg")
        let starData = try Data(contentsOf: starURL)
        let starDoc = try SVGParser.parse(data: starData)
        XCTAssertEqual(starDoc.viewBox, CGRect(x: 0, y: 0, width: 24, height: 24))
        XCTAssertFalse(starDoc.shapes.isEmpty)

        let shapesURL = fixtureDir.appendingPathComponent("shapes.svg")
        let shapesData = try Data(contentsOf: shapesURL)
        let shapesDoc = try SVGParser.parse(data: shapesData)
        XCTAssertEqual(shapesDoc.shapes.count, 5)

        let scriptURL = fixtureDir.appendingPathComponent("security_script.svg")
        let scriptData = try Data(contentsOf: scriptURL)
        XCTAssertThrowsError(try SVGParser.parse(data: scriptData))

        let externalURL = fixtureDir.appendingPathComponent("security_external.svg")
        let externalData = try Data(contentsOf: externalURL)
        XCTAssertThrowsError(try SVGParser.parse(data: externalData))
    }

    // MARK: - Icon Cache Tests

    func testIconCacheDiskInvalidation() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("test_cache.svg")
        let svgContent1 = """
        <svg viewBox="0 0 10 10">
            <circle cx="5" cy="5" r="5" fill="#FF0000"/>
        </svg>
        """
        try svgContent1.write(to: fileURL, atomically: true, encoding: .utf8)

        guard let doc1 = IconCache.shared.document(for: fileURL) else {
            XCTFail("Expected doc1 from cache")
            return
        }
        XCTAssertEqual(doc1.shapes.count, 1)

        // Read again, should hit cache
        guard let docCached = IconCache.shared.document(for: fileURL) else {
            XCTFail("Expected docCached from cache")
            return
        }
        XCTAssertEqual(docCached.shapes.count, 1)

        // Sleep briefly to ensure new modification timestamp
        Thread.sleep(forTimeInterval: 1.05)

        let svgContent2 = """
        <svg viewBox="0 0 20 20">
            <circle cx="5" cy="5" r="5"/>
            <rect x="0" y="0" width="10" height="10"/>
        </svg>
        """
        try svgContent2.write(to: fileURL, atomically: true, encoding: .utf8)

        guard let doc2 = IconCache.shared.document(for: fileURL) else {
            XCTFail("Expected doc2 from cache")
            return
        }
        XCTAssertEqual(doc2.shapes.count, 2)
        XCTAssertEqual(doc2.viewBox, CGRect(x: 0, y: 0, width: 20, height: 20))
    }

    // MARK: - Icon Registry Tests

    func testIconRegistryCollisionPolicies() throws {
        let registry = IconRegistry()
        try registry.register(source: .sf(name: "bell"), for: "app.notification")

        XCTAssertEqual(registry.source(for: "app.notification"), IconSource.sf(name: "bell"))

        // Overwrite policy
        let overwriteRegistry = IconRegistry()
        try overwriteRegistry.register(source: .sf(name: "bell"), for: "notif")
        try overwriteRegistry.register(source: .sf(name: "bell.fill"), for: "notif", collisionPolicy: .overwrite)
        XCTAssertEqual(overwriteRegistry.source(for: "notif"), IconSource.sf(name: "bell.fill"))

        // Ignore policy
        let ignoreRegistry = IconRegistry()
        try ignoreRegistry.register(source: .sf(name: "bell"), for: "notif")
        try ignoreRegistry.register(source: .sf(name: "bell.fill"), for: "notif", collisionPolicy: .ignore)
        XCTAssertEqual(ignoreRegistry.source(for: "notif"), IconSource.sf(name: "bell"))
    }

    // MARK: - Icon Component & Modifiers

    @MainActor
    func testIconComponentAndModifiers() {
        let icon = Icon("star.fill")
            .iconSize(.lg)
            .iconColor(.hex("#FFCC00"))
            .iconWeight(.bold)
            .renderingMode(.multicolor)

        XCTAssertEqual(icon.props.custom["iconSize"], "24.0")
        XCTAssertEqual(icon.props.custom["iconColor"], "#FFCC00")
        XCTAssertEqual(icon.props.custom["iconWeight"], "bold")
        XCTAssertEqual(icon.props.custom["iconRenderingMode"], "multicolor")
        XCTAssertEqual(icon.kind, .icon(source: .sf(name: "star.fill")))
    }

    // MARK: - Icon Renderer Tests

    @MainActor
    func testIconRendererVectorShapeLayers() throws {
        let element = RenderElement(
            id: ElementID(typeName: "Icon"),
            kind: .icon(source: .path(CGPath(rect: CGRect(x: 0, y: 0, width: 10, height: 10), transform: nil), viewBox: CGRect(x: 0, y: 0, width: 10, height: 10)))
        )
        .iconSize(24)
        .iconColor(.hex("#0000FF"))

        let renderer = IconRenderer(elementID: element.id)
        let frame = LayoutFrame(x: 0, y: 0, width: 24, height: 24)
        renderer.update(element: element, frame: frame, context: RenderContext(disableActions: true))

        XCTAssertEqual(renderer.rootLayer.sublayers?.count, 1)
        guard let shapeLayer = renderer.rootLayer.sublayers?.first as? CAShapeLayer else {
            XCTFail("Expected CAShapeLayer sublayer")
            return
        }
        XCTAssertNotNil(shapeLayer.path)
        XCTAssertNotNil(shapeLayer.fillColor)

        renderer.destroy()
        XCTAssertNil(renderer.rootLayer.superlayer)
    }
}
