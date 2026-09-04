import XCTest
@testable import PrismCore
import CoreGraphics

final class ColorTests: XCTestCase {

    func testTableDrivenHexParsingValid() throws {
        struct TestCase {
            let hex: String
            let expectedRed: CGFloat
            let expectedGreen: CGFloat
            let expectedBlue: CGFloat
            let expectedAlpha: CGFloat
        }

        let testCases: [TestCase] = [
            TestCase(hex: "#FFFFFF", expectedRed: 1.0, expectedGreen: 1.0, expectedBlue: 1.0, expectedAlpha: 1.0),
            TestCase(hex: "FFFFFF", expectedRed: 1.0, expectedGreen: 1.0, expectedBlue: 1.0, expectedAlpha: 1.0),
            TestCase(hex: "#000000", expectedRed: 0.0, expectedGreen: 0.0, expectedBlue: 0.0, expectedAlpha: 1.0),
            TestCase(hex: "#FFF", expectedRed: 1.0, expectedGreen: 1.0, expectedBlue: 1.0, expectedAlpha: 1.0),
            TestCase(hex: "000", expectedRed: 0.0, expectedGreen: 0.0, expectedBlue: 0.0, expectedAlpha: 1.0),
            TestCase(hex: "#FF0000", expectedRed: 1.0, expectedGreen: 0.0, expectedBlue: 0.0, expectedAlpha: 1.0),
            TestCase(hex: "#00FF00", expectedRed: 0.0, expectedGreen: 1.0, expectedBlue: 0.0, expectedAlpha: 1.0),
            TestCase(hex: "#0000FF", expectedRed: 0.0, expectedGreen: 0.0, expectedBlue: 1.0, expectedAlpha: 1.0),
            TestCase(hex: "#FFFFFFFF", expectedRed: 1.0, expectedGreen: 1.0, expectedBlue: 1.0, expectedAlpha: 1.0),
            TestCase(hex: "#00000080", expectedRed: 0.0, expectedGreen: 0.0, expectedBlue: 0.0, expectedAlpha: 128.0 / 255.0),
            TestCase(hex: "#F008", expectedRed: 1.0, expectedGreen: 0.0, expectedBlue: 0.0, expectedAlpha: 8.0 / 15.0),
        ]

        for testCase in testCases {
            let color = try Color(validatingHex: testCase.hex)
            XCTAssertEqual(color.red, testCase.expectedRed, accuracy: 0.01, "Failed red for \(testCase.hex)")
            XCTAssertEqual(color.green, testCase.expectedGreen, accuracy: 0.01, "Failed green for \(testCase.hex)")
            XCTAssertEqual(color.blue, testCase.expectedBlue, accuracy: 0.01, "Failed blue for \(testCase.hex)")
            XCTAssertEqual(color.alpha, testCase.expectedAlpha, accuracy: 0.01, "Failed alpha for \(testCase.hex)")
        }
    }

    func testTableDrivenHexParsingInvalid() {
        let invalidHexes = [
            "",
            "#",
            "#F",
            "#12",
            "#12345",
            "#1234567",
            "#123456789",
            "#GGGGGG",
            "#ZZZ",
            "hello-world"
        ]

        for hex in invalidHexes {
            XCTAssertThrowsError(try Color(validatingHex: hex), "Expected error for invalid hex: \(hex)")
            let color = Color.hex(hex)
            XCTAssertTrue(color.isMalformedHex, "Expected malformed flag for \(hex)")
        }
    }

    func testOpacityModification() {
        let color = Color(red: 1, green: 0, blue: 0, alpha: 1)
        let modified = color.opacity(0.5)
        XCTAssertEqual(modified.alpha, 0.5)
        XCTAssertEqual(modified.red, 1.0)
    }

    func testCGColorCreation() {
        let color = Color(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.9)
        let cgColor = color.cgColor
        XCTAssertEqual(cgColor.alpha, 0.9, accuracy: 0.001)
        XCTAssertEqual(cgColor.numberOfComponents, 4)
    }
}
