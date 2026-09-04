import XCTest
@testable import PrismUI

final class MetalEffectsTests: XCTestCase {
    func testMeshGradientGridConstruction() {
        let colors: [Color] = [
            Color(red: 1, green: 0, blue: 0),
            Color(red: 0, green: 1, blue: 0),
            Color(red: 0, green: 0, blue: 1),
            Color(red: 1, green: 1, blue: 0)
        ]

        let mesh = MeshGradient(columns: 2, rows: 2, colors: colors, width: 200, height: 100)
        let element = mesh.render()

        XCTAssertEqual(element.kind, .custom("MeshGradient"))
        let style = element.resolvedStyle
        XCTAssertEqual(style.width, 200)
        XCTAssertEqual(style.height, 100)
        XCTAssertNotNil(style.meshGradient)
        XCTAssertEqual(style.meshGradient?.width, 2)
        XCTAssertEqual(style.meshGradient?.height, 2)
        XCTAssertEqual(style.meshGradient?.points.count, 4)
    }

    func testEffectModifiersOnComponent() {
        let card = Text("Card Content")
            .sdfRoundedRect(cornerRadius: 18, borderWidth: 1.5, borderColor: .white, fill: .black)
            .glassmorphism(blurRadius: 15, tint: Color(red: 1, green: 1, blue: 1, alpha: 0.3), saturation: 1.1)

        let style = card.resolvedStyle
        XCTAssertNotNil(style.sdfRoundedRect)
        XCTAssertEqual(style.sdfRoundedRect?.cornerRadius, 18)
        XCTAssertEqual(style.sdfRoundedRect?.borderWidth, 1.5)

        XCTAssertNotNil(style.glassmorphism)
        XCTAssertEqual(style.glassmorphism?.blurRadius, 15)
        XCTAssertEqual(style.glassmorphism?.saturation, 1.1)
    }

    func testMetalEffectsDemoSceneBuilding() {
        let demo = MetalEffectsDemo()
        let element = demo.render()

        XCTAssertEqual(element.children.count, 4)
        // Verify mesh gradient child exists
        XCTAssertTrue(element.children.contains(where: { $0.kind == .custom("MeshGradient") }))
    }
}
