import XCTest
@testable import PrismCore

final class DemoThemeContractTests: XCTestCase {

    func testAuthoringContractExample() throws {
        let appConfig = PrismConfig {
            BaseTokens {
                Typography(
                    body: .init(family: "Inter", weight: .regular),
                    heading: .init(family: "Inter", weight: .semibold),
                    mono: .init(family: "JetBrains Mono", weight: .regular),
                    display: .init(family: "Inter", weight: .bold),
                    baseSize: 16,
                    scale: .majorThird
                )

                Spacing(base: 4)
                Radius(sm: 6, md: 10, lg: 16, full: 9_999)
                Motion(fast: .milliseconds(150), normal: .milliseconds(250))
            }

            Theme(.light) {
                Colors(
                    background: .hex("#FFFFFF"),
                    foreground: .hex("#0F172A"),
                    primary: .hex("#635BFF"),
                    muted: .hex("#F1F5F9"),
                    mutedForeground: .hex("#64748B"),
                    border: .hex("#E2E8F0"),
                    destructive: .hex("#E11D48")
                )
            }

            Theme(.dark, extending: .light) {
                Colors(
                    background: .hex("#0F172A"),
                    foreground: .hex("#F8FAFC"),
                    primary: .hex("#8B85FF"),
                    muted: .hex("#1E293B"),
                    mutedForeground: .hex("#94A3B8"),
                    border: .hex("#334155"),
                    destructive: .hex("#FB7185")
                )
            }

            Theme(.midnight, extending: .dark) {
                Colors(
                    background: .hex("#020617"),
                    muted: .hex("#0F172A"),
                    primary: .hex("#38BDF8")
                )
            }
        }

        let appTheme = Theme(config: appConfig)
        XCTAssertEqual(appTheme.id, ThemeID.light)
        XCTAssertEqual(appTheme.spacing.base, 4)
        XCTAssertEqual(appTheme.radius.full, 9_999)

        let midnight = try appConfig.resolveTheme(for: .midnight)
        XCTAssertEqual(midnight.colors.background, Color.hex("#020617"))
        XCTAssertEqual(midnight.colors.foreground, Color.hex("#F8FAFC")) // inherited from dark
        XCTAssertEqual(midnight.colors.border, Color.hex("#334155"))     // inherited from dark
        XCTAssertEqual(midnight.colors.primary, Color.hex("#38BDF8"))    // overridden in midnight
    }
}
