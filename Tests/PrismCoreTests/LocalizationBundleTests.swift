import XCTest
@testable import PrismCore

final class LocalizationBundleTests: XCTestCase {

    func testInterpolationInKey() {
        let name = "Alex"
        let count = 42
        let key: LocalizedStringKey = "Hello, \(name)! You have \(count) messages."

        XCTAssertEqual(key.key, "Hello, %@! You have %lld messages.")
        XCTAssertEqual(key.arguments, ["Alex", "42"])
    }

    func testInMemoryTableRegistrationAndLookup() {
        let bundle = LocalizationBundle(isDevelopmentMode: false)
        bundle.registerStrings([
            "welcome.title": "Welcome to Prism",
            "greeting.user": "Hello, %@!"
        ], localeIdentifier: "en_US")

        let locale = Locale(identifier: "en_US")

        let title = bundle.localizedString(forKey: "welcome.title", locale: locale)
        XCTAssertEqual(title, "Welcome to Prism")

        let greetingKey: LocalizedStringKey = "greeting.user"
        let greetingWithArg = LocalizedStringKey("greeting.user", arguments: ["Sarah"])
        let greeting = bundle.localizedString(forKey: greetingWithArg, locale: locale)
        XCTAssertEqual(greeting, "Hello, Sarah!")
    }

    func testMissingKeyFallbackReleaseVsDevelopment() {
        let releaseBundle = LocalizationBundle(isDevelopmentMode: false)
        let releaseFallback = releaseBundle.localizedString(forKey: "missing.key.test")
        XCTAssertEqual(releaseFallback, "missing.key.test")

        let devBundle = LocalizationBundle(isDevelopmentMode: true)
        let devFallback = devBundle.localizedString(forKey: "missing.key.test")
        XCTAssertEqual(devFallback, "[MISSING: \"missing.key.test\"]")
    }

    func testPluralFormsEnglish() {
        let bundle = LocalizationBundle()
        bundle.registerPlurals([
            "cart.items": [
                .zero: "No items in your cart",
                .one: "1 item in your cart",
                .other: "%lld items in your cart"
            ]
        ], localeIdentifier: "en")

        let enLocale = Locale(identifier: "en")
        XCTAssertEqual(bundle.localizedPlural(forKey: "cart.items", count: 0, locale: enLocale), "No items in your cart")
        XCTAssertEqual(bundle.localizedPlural(forKey: "cart.items", count: 1, locale: enLocale), "1 item in your cart")
        XCTAssertEqual(bundle.localizedPlural(forKey: "cart.items", count: 5, locale: enLocale), "5 items in your cart")
    }

    func testPluralFormsSlavic() {
        let bundle = LocalizationBundle()
        bundle.registerPlurals([
            "files.count": [
                .one: "%lld файл",
                .few: "%lld файла",
                .many: "%lld файлов",
                .other: "%lld файла"
            ]
        ], localeIdentifier: "ru")

        let ruLocale = Locale(identifier: "ru")
        XCTAssertEqual(bundle.localizedPlural(forKey: "files.count", count: 1, locale: ruLocale), "1 файл")
        XCTAssertEqual(bundle.localizedPlural(forKey: "files.count", count: 3, locale: ruLocale), "3 файла")
        XCTAssertEqual(bundle.localizedPlural(forKey: "files.count", count: 5, locale: ruLocale), "5 файлов")
        XCTAssertEqual(bundle.localizedPlural(forKey: "files.count", count: 21, locale: ruLocale), "21 файл")
        XCTAssertEqual(bundle.localizedPlural(forKey: "files.count", count: 24, locale: ruLocale), "24 файла")
    }

    func testPseudoLocalization() {
        let bundle = LocalizationBundle(pseudoLocalizationEnabled: true)
        let transformed = bundle.applyPseudoLocalization(to: "Hello World")
        XCTAssertTrue(transformed.hasPrefix("[--- "))
        XCTAssertTrue(transformed.hasSuffix(" ---]"))
        XCTAssertTrue(transformed.contains("é"))
        XCTAssertTrue(transformed.contains("ö"))
    }
}
