import Foundation
import PrismUI

/// Predefined theme presets bundled with the Prism Showcase application.
///
/// These presets demonstrate Prism's design token resolution, custom palettes,
/// and live appearance switching without modifying global library defaults.
public enum ShowcaseThemePresets {

    // MARK: - Light Theme
    public static let light = Theme(
        id: .light,
        colors: ThemeColors.defaultLight,
        typography: Typography(),
        spacing: Spacing(),
        radius: Radius(),
        shadow: .md,
        motion: Motion()
    )

    // MARK: - Dark Theme
    public static let dark = Theme(
        id: .dark,
        colors: ThemeColors.defaultDark,
        typography: Typography(),
        spacing: Spacing(),
        radius: Radius(),
        shadow: .md,
        motion: Motion()
    )

    // MARK: - Midnight Theme (Deep Dark Navy)
    public static let midnightColors = ThemeColors(
        background: Color.hex("#0A1128"),
        foreground: Color.hex("#F1F5F9"),
        primary: Color.hex("#38BDF8"),
        primaryForeground: Color.hex("#0A1128"),
        secondary: Color.hex("#1E293B"),
        secondaryForeground: Color.hex("#F1F5F9"),
        muted: Color.hex("#1E293B"),
        mutedForeground: Color.hex("#94A3B8"),
        border: Color.hex("#253248"),
        destructive: Color.hex("#F87171"),
        destructiveForeground: Color.hex("#0A1128"),
        accent: Color.hex("#1E293B"),
        accentForeground: Color.hex("#38BDF8"),
        custom: [
            "surface": Color.hex("#0F172A"),
            "focus": Color.hex("#38BDF8")
        ]
    )

    public static let midnight = Theme(
        id: .midnight,
        colors: midnightColors,
        typography: Typography(),
        spacing: Spacing(),
        radius: Radius(),
        shadow: .md,
        motion: Motion()
    )

    // MARK: - Forest Theme (Natural Sage & Emerald)
    public static let forestColors = ThemeColors(
        background: Color.hex("#F4F7F4"),
        foreground: Color.hex("#1B2D20"),
        primary: Color.hex("#2D6A4F"),
        primaryForeground: .white,
        secondary: Color.hex("#E8EFE9"),
        secondaryForeground: Color.hex("#1B2D20"),
        muted: Color.hex("#E8EFE9"),
        mutedForeground: Color.hex("#52796F"),
        border: Color.hex("#D1E0D4"),
        destructive: Color.hex("#C92A2A"),
        destructiveForeground: .white,
        accent: Color.hex("#D8F3DC"),
        accentForeground: Color.hex("#1B4332"),
        custom: [
            "surface": Color.hex("#FFFFFF"),
            "focus": Color.hex("#2D6A4F")
        ]
    )

    public static let forest = Theme(
        id: .forest,
        colors: forestColors,
        typography: Typography(),
        spacing: Spacing(),
        radius: Radius(),
        shadow: .md,
        motion: Motion()
    )

    // MARK: - Sand Theme (Warm Desert Linen & Terracotta)
    public static let sandColors = ThemeColors(
        background: Color.hex("#FAF7F2"),
        foreground: Color.hex("#2C2523"),
        primary: Color.hex("#C86D51"),
        primaryForeground: .white,
        secondary: Color.hex("#F0EBE1"),
        secondaryForeground: Color.hex("#2C2523"),
        muted: Color.hex("#F0EBE1"),
        mutedForeground: Color.hex("#8C7E75"),
        border: Color.hex("#E3DACD"),
        destructive: Color.hex("#BA3C2A"),
        destructiveForeground: .white,
        accent: Color.hex("#F5EBE0"),
        accentForeground: Color.hex("#874836"),
        custom: [
            "surface": Color.hex("#FFFFFF"),
            "focus": Color.hex("#C86D51")
        ]
    )

    public static let sand = Theme(
        id: .sand,
        colors: sandColors,
        typography: Typography(),
        spacing: Spacing(),
        radius: Radius(),
        shadow: .md,
        motion: Motion()
    )

    /// Array of all 5 bundled themes.
    public static let allThemes: [Theme] = [light, dark, midnight, forest, sand]
}

/// Bundled PrismConfig configuration for the showcase application.
public enum ShowcaseConfig {
    /// Constructs a validated PrismConfig containing all 5 bundled showcase themes.
    public static func makeConfig() -> PrismConfig {
        let baseTokens = BaseTokens(
            typography: Typography(),
            spacing: Spacing(),
            radius: Radius(),
            shadow: .md,
            motion: Motion()
        )

        let defs: [ThemeDefinition] = [
            ThemeDefinition(
                id: .light,
                parentID: nil,
                colors: Colors(
                    background: ThemeColors.defaultLight.background,
                    foreground: ThemeColors.defaultLight.foreground,
                    primary: ThemeColors.defaultLight.primary,
                    primaryForeground: ThemeColors.defaultLight.primaryForeground,
                    secondary: ThemeColors.defaultLight.secondary,
                    secondaryForeground: ThemeColors.defaultLight.secondaryForeground,
                    muted: ThemeColors.defaultLight.muted,
                    mutedForeground: ThemeColors.defaultLight.mutedForeground,
                    border: ThemeColors.defaultLight.border,
                    destructive: ThemeColors.defaultLight.destructive,
                    destructiveForeground: ThemeColors.defaultLight.destructiveForeground,
                    accent: ThemeColors.defaultLight.accent,
                    accentForeground: ThemeColors.defaultLight.accentForeground
                )
            ),
            ThemeDefinition(
                id: .dark,
                parentID: nil,
                colors: Colors(
                    background: ThemeColors.defaultDark.background,
                    foreground: ThemeColors.defaultDark.foreground,
                    primary: ThemeColors.defaultDark.primary,
                    primaryForeground: ThemeColors.defaultDark.primaryForeground,
                    secondary: ThemeColors.defaultDark.secondary,
                    secondaryForeground: ThemeColors.defaultDark.secondaryForeground,
                    muted: ThemeColors.defaultDark.muted,
                    mutedForeground: ThemeColors.defaultDark.mutedForeground,
                    border: ThemeColors.defaultDark.border,
                    destructive: ThemeColors.defaultDark.destructive,
                    destructiveForeground: ThemeColors.defaultDark.destructiveForeground,
                    accent: ThemeColors.defaultDark.accent,
                    accentForeground: ThemeColors.defaultDark.accentForeground
                )
            ),
            ThemeDefinition(
                id: .midnight,
                parentID: nil,
                colors: Colors(
                    background: ShowcaseThemePresets.midnightColors.background,
                    foreground: ShowcaseThemePresets.midnightColors.foreground,
                    primary: ShowcaseThemePresets.midnightColors.primary,
                    primaryForeground: ShowcaseThemePresets.midnightColors.primaryForeground,
                    secondary: ShowcaseThemePresets.midnightColors.secondary,
                    secondaryForeground: ShowcaseThemePresets.midnightColors.secondaryForeground,
                    muted: ShowcaseThemePresets.midnightColors.muted,
                    mutedForeground: ShowcaseThemePresets.midnightColors.mutedForeground,
                    border: ShowcaseThemePresets.midnightColors.border,
                    destructive: ShowcaseThemePresets.midnightColors.destructive,
                    destructiveForeground: ShowcaseThemePresets.midnightColors.destructiveForeground,
                    accent: ShowcaseThemePresets.midnightColors.accent,
                    accentForeground: ShowcaseThemePresets.midnightColors.accentForeground,
                    custom: ShowcaseThemePresets.midnightColors.custom
                )
            ),
            ThemeDefinition(
                id: .forest,
                parentID: nil,
                colors: Colors(
                    background: ShowcaseThemePresets.forestColors.background,
                    foreground: ShowcaseThemePresets.forestColors.foreground,
                    primary: ShowcaseThemePresets.forestColors.primary,
                    primaryForeground: ShowcaseThemePresets.forestColors.primaryForeground,
                    secondary: ShowcaseThemePresets.forestColors.secondary,
                    secondaryForeground: ShowcaseThemePresets.forestColors.secondaryForeground,
                    muted: ShowcaseThemePresets.forestColors.muted,
                    mutedForeground: ShowcaseThemePresets.forestColors.mutedForeground,
                    border: ShowcaseThemePresets.forestColors.border,
                    destructive: ShowcaseThemePresets.forestColors.destructive,
                    destructiveForeground: ShowcaseThemePresets.forestColors.destructiveForeground,
                    accent: ShowcaseThemePresets.forestColors.accent,
                    accentForeground: ShowcaseThemePresets.forestColors.accentForeground,
                    custom: ShowcaseThemePresets.forestColors.custom
                )
            ),
            ThemeDefinition(
                id: .sand,
                parentID: nil,
                colors: Colors(
                    background: ShowcaseThemePresets.sandColors.background,
                    foreground: ShowcaseThemePresets.sandColors.foreground,
                    primary: ShowcaseThemePresets.sandColors.primary,
                    primaryForeground: ShowcaseThemePresets.sandColors.primaryForeground,
                    secondary: ShowcaseThemePresets.sandColors.secondary,
                    secondaryForeground: ShowcaseThemePresets.sandColors.secondaryForeground,
                    muted: ShowcaseThemePresets.sandColors.muted,
                    mutedForeground: ShowcaseThemePresets.sandColors.mutedForeground,
                    border: ShowcaseThemePresets.sandColors.border,
                    destructive: ShowcaseThemePresets.sandColors.destructive,
                    destructiveForeground: ShowcaseThemePresets.sandColors.destructiveForeground,
                    accent: ShowcaseThemePresets.sandColors.accent,
                    accentForeground: ShowcaseThemePresets.sandColors.accentForeground,
                    custom: ShowcaseThemePresets.sandColors.custom
                )
            )
        ]

        // Forced unwrap is safe because definition set is statically known and validated.
        return try! PrismConfig(baseTokens: baseTokens, definitions: defs)
    }

    /// Singleton bundled config.
    public static let bundled: PrismConfig = makeConfig()
}

/// Isolated preference storage for showcase theme selection.
@MainActor
public final class ShowcasePreferences {
    private static let key = "prism.showcase.themeSelection"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if ProcessInfo.processInfo.arguments.contains("-showcaseReset") {
            reset()
        }
    }

    public var themeSelection: ThemeSelection {
        get {
            guard let raw = defaults.string(forKey: Self.key) else {
                return .system
            }
            if raw == "system" { return .system }
            return .explicit(ThemeID(raw))
        }
        set {
            switch newValue {
            case .system:
                defaults.set("system", forKey: Self.key)
            case .explicit(let id):
                defaults.set(id.rawValue, forKey: Self.key)
            }
        }
    }

    public func reset() {
        defaults.removeObject(forKey: Self.key)
    }
}
