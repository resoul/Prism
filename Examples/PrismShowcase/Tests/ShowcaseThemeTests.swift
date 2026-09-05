import XCTest
import PrismUI
@testable import PrismCore

@MainActor
final class ShowcaseThemeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActionRegistry.shared.reset()
        ShowcasePreferences().reset()
    }

    override func tearDown() {
        ActionRegistry.shared.reset()
        ShowcasePreferences().reset()
        super.tearDown()
    }

    func testBundledThemesResolveWithoutMissingTokens() throws {
        let config = ShowcaseConfig.bundled

        let expectedThemeIDs: [ThemeID] = [.light, .dark, .midnight, .forest, .sand]
        for themeID in expectedThemeIDs {
            let theme = try config.resolveTheme(for: themeID)
            XCTAssertEqual(theme.id, themeID)

            let c = theme.colors
            // Ensure essential semantic colors are present
            XCTAssertNotNil(c.background)
            XCTAssertNotNil(c.foreground)
            XCTAssertNotNil(c.primary)
            XCTAssertNotNil(c.primaryForeground)
            XCTAssertNotNil(c.secondary)
            XCTAssertNotNil(c.secondaryForeground)
            XCTAssertNotNil(c.muted)
            XCTAssertNotNil(c.mutedForeground)
            XCTAssertNotNil(c.border)
            XCTAssertNotNil(c.destructive)
            XCTAssertNotNil(c.destructiveForeground)

            // Base tokens inherited
            XCTAssertNotNil(theme.typography)
            XCTAssertNotNil(theme.spacing)
            XCTAssertNotNil(theme.radius)
            XCTAssertNotNil(theme.shadow)
            XCTAssertNotNil(theme.motion)
        }
    }

    func testSemanticContrastPairs() throws {
        let config = ShowcaseConfig.bundled
        let themes = try [
            config.resolveTheme(for: .light),
            config.resolveTheme(for: .dark),
            config.resolveTheme(for: .midnight),
            config.resolveTheme(for: .forest),
            config.resolveTheme(for: .sand)
        ]

        for theme in themes {
            let c = theme.colors
            // Foreground and background must not be identical
            XCTAssertNotEqual(c.background, c.foreground, "Theme \(theme.id) has identical bg and fg")
            XCTAssertNotEqual(c.primary, c.primaryForeground, "Theme \(theme.id) has identical primary and primaryFg")
            XCTAssertNotEqual(c.destructive, c.destructiveForeground, "Theme \(theme.id) has identical destructive and destructiveFg")
        }
    }

    func testLiveThemeSwitchingPreservesUserState() {
        let store = ShowcaseStore()
        store.selectTheme(.light)

        store.increment()
        store.increment()
        store.setInputText("Preserve this input")
        store.submitInput()
        store.scrollBy(75)

        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.inputText, "Preserve this input")
        XCTAssertEqual(store.submittedText, "Preserve this input")
        XCTAssertEqual(store.scrollOffset, 75.0)
        XCTAssertEqual(store.activeThemeID, .light)

        // Switch to Midnight
        store.selectTheme(.midnight)
        XCTAssertEqual(store.activeThemeID, .midnight)
        XCTAssertEqual(store.activeTheme.colors.background, ShowcaseThemePresets.midnightColors.background)
        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.inputText, "Preserve this input")
        XCTAssertEqual(store.submittedText, "Preserve this input")
        XCTAssertEqual(store.scrollOffset, 75.0)

        // Switch to Forest
        store.selectTheme(.forest)
        XCTAssertEqual(store.activeThemeID, .forest)
        XCTAssertEqual(store.activeTheme.colors.background, ShowcaseThemePresets.forestColors.background)
        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.inputText, "Preserve this input")
        XCTAssertEqual(store.submittedText, "Preserve this input")
        XCTAssertEqual(store.scrollOffset, 75.0)

        // Switch to Sand
        store.selectTheme(.sand)
        XCTAssertEqual(store.activeThemeID, .sand)
        XCTAssertEqual(store.activeTheme.colors.background, ShowcaseThemePresets.sandColors.background)
        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.inputText, "Preserve this input")
        XCTAssertEqual(store.submittedText, "Preserve this input")
        XCTAssertEqual(store.scrollOffset, 75.0)

        // Switch to Dark
        store.selectTheme(.dark)
        XCTAssertEqual(store.activeThemeID, .dark)
        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.inputText, "Preserve this input")
        XCTAssertEqual(store.submittedText, "Preserve this input")
        XCTAssertEqual(store.scrollOffset, 75.0)

        store.teardown()
    }

    func testSystemColorSchemeAdaptation() {
        let store = ShowcaseStore()
        store.selectTheme(.system)

        // Initially light system scheme
        store.setSystemColorScheme(.light)
        XCTAssertEqual(store.activeThemeID, .light)

        // System switches to dark
        store.setSystemColorScheme(.dark)
        XCTAssertEqual(store.activeThemeID, .dark)

        // Explicit theme overrides system scheme
        store.selectTheme(.midnight)
        XCTAssertEqual(store.activeThemeID, .midnight)

        // System scheme changes should not override explicit selection
        store.setSystemColorScheme(.light)
        XCTAssertEqual(store.activeThemeID, .midnight)

        store.teardown()
    }

    func testPreferencesPersistenceAndReset() {
        let suite = "test.showcase.preferences.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let prefs = ShowcasePreferences(defaults: defaults)

        XCTAssertEqual(prefs.themeSelection, .system)

        prefs.themeSelection = .midnight
        XCTAssertEqual(prefs.themeSelection, .midnight)

        // New instance with same defaults reads persisted value
        let prefs2 = ShowcasePreferences(defaults: defaults)
        XCTAssertEqual(prefs2.themeSelection, .midnight)

        // Reset
        prefs2.reset()
        XCTAssertEqual(prefs2.themeSelection, .system)

        defaults.removePersistentDomain(forName: suite)
    }

    func testThemeUpdatesPropagateToHostView() {
        let store = ShowcaseStore()
        let host = HostNSView(element: store.rootElement(), theme: store.activeTheme)
        var themeChangeCount = 0

        store.onThemeChange = { theme in
            host.setTheme(theme)
            themeChangeCount += 1
        }

        XCTAssertEqual(host.theme?.id, .light)

        store.selectTheme(.midnight)
        XCTAssertEqual(themeChangeCount, 1)
        XCTAssertEqual(host.theme?.id, .midnight)

        store.selectTheme(.forest)
        XCTAssertEqual(themeChangeCount, 2)
        XCTAssertEqual(host.theme?.id, .forest)

        host.teardown()
        store.teardown()
    }

    func testExtendingWithSixthCustomTheme() throws {
        // Runnable example of extending ShowcaseConfig with a 6th custom theme
        let customID = ThemeID("lavender")
        let lavenderColors = ThemeColors(
            background: Color.hex("#F7F5FB"),
            foreground: Color.hex("#2E2836"),
            primary: Color.hex("#7C3AED"),
            primaryForeground: .white,
            secondary: Color.hex("#EDE9FE"),
            secondaryForeground: Color.hex("#2E2836"),
            muted: Color.hex("#EDE9FE"),
            mutedForeground: Color.hex("#797189"),
            border: Color.hex("#DDD6FE"),
            destructive: Color.hex("#DC2626"),
            destructiveForeground: .white,
            accent: Color.hex("#DDD6FE"),
            accentForeground: Color.hex("#5B21B6")
        )

        let def = ThemeDefinition(
            id: customID,
            parentID: nil,
            colors: Colors(
                background: lavenderColors.background,
                foreground: lavenderColors.foreground,
                primary: lavenderColors.primary,
                primaryForeground: lavenderColors.primaryForeground,
                secondary: lavenderColors.secondary,
                secondaryForeground: lavenderColors.secondaryForeground,
                muted: lavenderColors.muted,
                mutedForeground: lavenderColors.mutedForeground,
                border: lavenderColors.border,
                destructive: lavenderColors.destructive,
                destructiveForeground: lavenderColors.destructiveForeground,
                accent: lavenderColors.accent,
                accentForeground: lavenderColors.accentForeground
            )
        )

        var allDefs = ShowcaseConfig.bundled.definitions
        allDefs.append(def)

        let extendedConfig = try PrismConfig(
            baseTokens: ShowcaseConfig.bundled.baseTokens,
            definitions: allDefs
        )

        let resolved = try extendedConfig.resolveTheme(for: customID)
        XCTAssertEqual(resolved.id, customID)
        XCTAssertEqual(resolved.colors.background, Color.hex("#F7F5FB"))
        XCTAssertEqual(resolved.colors.primary, Color.hex("#7C3AED"))
    }
}
