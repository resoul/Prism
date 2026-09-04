import XCTest
@testable import PrismCore

final class ThemeGraphValidationTests: XCTestCase {

    func testDuplicateThemeID() {
        let config = PrismConfig {
            Theme(.light) { Colors(background: .hex("#FFFFFF")) }
            Theme(.light) { Colors(background: .hex("#000000")) }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(error as? ConfigValidationError, .duplicateThemeID(.light))
        }
    }

    func testMissingParentTheme() {
        let config = PrismConfig {
            Theme(.dark, extending: .light) {
                Colors(background: .hex("#000000"))
            }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(
                error as? ConfigValidationError,
                .missingParentTheme(child: .dark, parent: .light)
            )
        }
    }

    func testInheritanceCycleDirect() {
        let config = PrismConfig {
            Theme("A", extending: "B") { Colors() }
            Theme("B", extending: "A") { Colors() }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            guard case .inheritanceCycle = error as? ConfigValidationError else {
                XCTFail("Expected inheritanceCycle error, got \(error)")
                return
            }
        }
    }

    func testInheritanceCycleIndirect() {
        let config = PrismConfig {
            Theme("A", extending: "C") { Colors() }
            Theme("B", extending: "A") { Colors() }
            Theme("C", extending: "B") { Colors() }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            guard case .inheritanceCycle = error as? ConfigValidationError else {
                XCTFail("Expected inheritanceCycle error, got \(error)")
                return
            }
        }
    }

    func testNegativeSpacing() {
        let config = PrismConfig {
            BaseTokens {
                Spacing(base: -4)
            }
            Theme(.light) { Colors() }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(error as? ConfigValidationError, .negativeSpacing(-4))
        }
    }

    func testNegativeRadius() {
        let config = PrismConfig {
            BaseTokens {
                Radius(sm: -2)
            }
            Theme(.light) { Colors() }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(error as? ConfigValidationError, .negativeRadius(-2))
        }
    }

    func testEmptyFontFamily() {
        let config = PrismConfig {
            BaseTokens {
                Typography(body: FontConfig(family: "   ", weight: .regular))
            }
            Theme(.light) { Colors() }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(error as? ConfigValidationError, .emptyFontFamily(.body))
        }
    }

    func testInvalidHexColorInTheme() {
        let config = PrismConfig {
            Theme(.light) {
                Colors(background: .hex("not-a-color"))
            }
        }

        XCTAssertThrowsError(try config.validate()) { error in
            XCTAssertEqual(error as? ConfigValidationError, .invalidHexColor("not-a-color"))
        }
    }
}
