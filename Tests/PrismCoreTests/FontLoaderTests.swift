import XCTest
@testable import PrismCore

final class FontLoaderTests: XCTestCase {

    func testFileNotFoundError() {
        let fakeURL = URL(fileURLWithPath: "/path/does/not/exist/CustomFont.ttf")
        XCTAssertThrowsError(try FontLoader.register(fromURL: fakeURL)) { error in
            XCTAssertEqual(error as? FontLoaderError, .fileNotFound(fakeURL))
        }
    }

    func testBundleResourceNotFoundError() {
        XCTAssertThrowsError(try FontLoader.register(fromBundle: .main, name: "NoSuchFontInBundle.ttf")) { error in
            XCTAssertEqual(error as? FontLoaderError, .bundleResourceNotFound(name: "NoSuchFontInBundle.ttf"))
        }
    }
}
