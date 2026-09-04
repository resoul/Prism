import XCTest
@testable import PrismCore

final class ThemeInheritanceTests: XCTestCase {

    func testThemeInheritanceChain() throws {
        let config = try PrismConfig(
            baseTokens: BaseTokens(
                spacing: Spacing(base: 4),
                radius: Radius(sm: 6, md: 10, lg: 16)
            ),
            definitions: [
                ThemeDefinition(
                    id: .light,
                    colors: Colors(
                        background: .hex("#FFFFFF"),
                        foreground: .hex("#0F172A"),
                        primary: .hex("#635BFF"),
                        muted: .hex("#F1F5F9"),
                        mutedForeground: .hex("#64748B"),
                        border: .hex("#E2E8F0"),
                        destructive: .hex("#E11D48")
                    )
                ),
                ThemeDefinition(
                    id: .dark,
                    parentID: .light,
                    colors: Colors(
                        background: .hex("#0F172A"),
                        foreground: .hex("#F8FAFC"),
                        primary: .hex("#8B85FF"),
                        muted: .hex("#1E293B"),
                        mutedForeground: .hex("#94A3B8"),
                        border: .hex("#334155"),
                        destructive: .hex("#FB7185")
                    )
                ),
                ThemeDefinition(
                    id: .midnight,
                    parentID: .dark,
                    colors: Colors(
                        background: .hex("#020617"),
                        muted: .hex("#0F172A"),
                        primary: .hex("#38BDF8")
                    )
                )
            ]
        )

        let light = try config.resolveTheme(for: .light)
        let dark = try config.resolveTheme(for: .dark)
        let midnight = try config.resolveTheme(for: .midnight)

        // Light verification
        XCTAssertEqual(light.colors.background, Color.hex("#FFFFFF"))
        XCTAssertEqual(light.colors.foreground, Color.hex("#0F172A"))

        // Dark verification
        XCTAssertEqual(dark.colors.background, Color.hex("#0F172A"))
        XCTAssertEqual(dark.colors.foreground, Color.hex("#F8FAFC"))
        XCTAssertEqual(dark.colors.border, Color.hex("#334155"))

        // Midnight verification: overridden background, muted, primary; inherited border, foreground from dark
        XCTAssertEqual(midnight.colors.background, Color.hex("#020617"))
        XCTAssertEqual(midnight.colors.muted, Color.hex("#0F172A"))
        XCTAssertEqual(midnight.colors.primary, Color.hex("#38BDF8"))
        XCTAssertEqual(midnight.colors.foreground, Color.hex("#F8FAFC"), "Midnight should inherit foreground from Dark")
        XCTAssertEqual(midnight.colors.border, Color.hex("#334155"), "Midnight should inherit border from Dark")
        XCTAssertEqual(midnight.colors.destructive, Color.hex("#FB7185"), "Midnight should inherit destructive from Dark")

        // Tokens completeness check
        XCTAssertEqual(midnight.spacing.base, 4)
        XCTAssertEqual(midnight.radius.sm, 6)
    }
}
