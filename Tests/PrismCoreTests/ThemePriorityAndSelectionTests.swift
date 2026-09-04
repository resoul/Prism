import XCTest
@testable import PrismCore

final class ThemePriorityAndSelectionTests: XCTestCase {

    var sampleConfig: PrismConfig!

    override func setUp() {
        super.setUp()
        sampleConfig = PrismConfig {
            Theme(.light) {
                Colors(background: .hex("#FFFFFF"), primary: .hex("#111111"))
            }
            Theme(.dark, extending: .light) {
                Colors(background: .hex("#1E1E1E"), primary: .hex("#EEEEEE"))
            }
            Theme(.midnight, extending: .dark) {
                Colors(background: .hex("#020617"), primary: .hex("#38BDF8"))
            }
        }
    }

    func testPrioritySystemMapping() {
        let mapping = SystemThemeMapping(light: .light, dark: .midnight)

        // When system is light, system mapping resolves to .light
        var env = ThemeEnvironment(
            config: sampleConfig,
            selection: .system,
            systemMapping: mapping,
            currentSystemScheme: .light
        )
        XCTAssertEqual(env.resolvedTheme.id, .light)
        XCTAssertEqual(env.resolvedTheme.colors.background, Color.hex("#FFFFFF"))

        // When system is dark, system mapping resolves to .midnight
        env = env.withSystemScheme(.dark)
        XCTAssertEqual(env.resolvedTheme.id, .midnight)
        XCTAssertEqual(env.resolvedTheme.colors.background, Color.hex("#020617"))
    }

    func testPriorityExplicitSelectionOverridesSystem() {
        let mapping = SystemThemeMapping(light: .light, dark: .midnight)

        let env = ThemeEnvironment(
            config: sampleConfig,
            selection: .explicit(.dark),
            systemMapping: mapping,
            currentSystemScheme: .light // System is light, but user explicitly chose dark
        )

        XCTAssertEqual(env.resolvedTheme.id, .dark)
        XCTAssertEqual(env.resolvedTheme.colors.background, Color.hex("#1E1E1E"))
    }

    func testPrioritySubtreeOverrideBeatsAll() {
        let mapping = SystemThemeMapping(light: .light, dark: .midnight)

        // Environment has user explicit .dark, but subtree overrides with .midnight
        let baseEnv = ThemeEnvironment(
            config: sampleConfig,
            selection: .explicit(.dark),
            systemMapping: mapping,
            currentSystemScheme: .light
        )

        let subtreeEnv = baseEnv.withSubtreeOverride(.midnight)
        XCTAssertEqual(subtreeEnv.resolvedTheme.id, .midnight)
        XCTAssertEqual(subtreeEnv.resolvedTheme.colors.background, Color.hex("#020617"))
    }

    func testSubstituteThemeInTestWithoutPlatformHost() {
        let testTheme = Theme(
            id: "test-theme",
            colors: ThemeColors(
                background: Color(red: 0.1, green: 0.2, blue: 0.3),
                foreground: .white,
                primary: .white,
                primaryForeground: .black,
                secondary: .clear,
                secondaryForeground: .white,
                muted: .clear,
                mutedForeground: .white,
                border: .white,
                destructive: .white,
                destructiveForeground: .black,
                accent: .clear,
                accentForeground: .white
            )
        )

        XCTAssertEqual(testTheme.id, "test-theme")
        XCTAssertEqual(testTheme.colors.background.red, 0.1, accuracy: 0.01)
    }
}
