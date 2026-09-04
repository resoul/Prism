import XCTest
@testable import PrismCore

final class ThemeGraphValidationTests: XCTestCase {

    func testDuplicateThemeID() {
        XCTAssertThrowsError(try PrismConfig {
            Theme(.light) { Colors(background: .hex("#FFFFFF")) }
            Theme(.light) { Colors(background: .hex("#000000")) }
        }) { error in
            XCTAssertEqual(error as? ConfigValidationError, .duplicateThemeID(.light))
        }
    }

    func testMissingParentTheme() {
        XCTAssertThrowsError(try PrismConfig {
            Theme(.dark, extending: .light) {
                Colors(background: .hex("#000000"))
            }
        }) { error in
            XCTAssertEqual(
                error as? ConfigValidationError,
                .missingParentTheme(child: .dark, parent: .light)
            )
        }
    }

    func testInheritanceCycleDirect() {
        XCTAssertThrowsError(try PrismConfig {
            Theme("A", extending: "B") { Colors() }
            Theme("B", extending: "A") { Colors() }
        }) { error in
            guard case .inheritanceCycle = error as? ConfigValidationError else {
                XCTFail("Expected inheritanceCycle error, got \(error)")
                return
            }
        }
    }

    func testInheritanceCycleIndirect() {
        XCTAssertThrowsError(try PrismConfig {
            Theme("A", extending: "C") { Colors() }
            Theme("B", extending: "A") { Colors() }
            Theme("C", extending: "B") { Colors() }
        }) { error in
            guard case .inheritanceCycle = error as? ConfigValidationError else {
                XCTFail("Expected inheritanceCycle error, got \(error)")
                return
            }
        }
    }

    func testNegativeSpacing() {
        XCTAssertThrowsError(try PrismConfig {
            BaseTokens {
                Spacing(base: -4)
            }
            Theme(.light) { Colors() }
        }) { error in
            XCTAssertEqual(error as? ConfigValidationError, .negativeSpacing(-4))
        }
    }

    func testNegativeRadius() {
        XCTAssertThrowsError(try PrismConfig {
            BaseTokens {
                Radius(sm: -2)
            }
            Theme(.light) { Colors() }
        }) { error in
            XCTAssertEqual(error as? ConfigValidationError, .negativeRadius(-2))
        }
    }

    func testEmptyFontFamily() {
        XCTAssertThrowsError(try PrismConfig {
            BaseTokens {
                Typography(body: FontConfig(family: "   ", weight: .regular))
            }
            Theme(.light) { Colors() }
        }) { error in
            XCTAssertEqual(error as? ConfigValidationError, .emptyFontFamily(.body))
        }
    }

    func testInvalidHexColorInTheme() {
        XCTAssertThrowsError(try PrismConfig {
            Theme(.light) {
                Colors(background: .hex("not-a-color"))
            }
        }) { error in
            XCTAssertEqual(error as? ConfigValidationError, .invalidHexColor("not-a-color"))
        }
    }
}
