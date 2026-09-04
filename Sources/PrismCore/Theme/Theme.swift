import Foundation
import CoreText

/// Immutable, fully-resolved design theme ready for rendering.
///
/// Guaranteed to contain complete tokens with no missing fallbacks.
public struct Theme: Equatable, Sendable {
    public let id: ThemeID
    public let colors: ThemeColors
    public let typography: Typography
    public let spacing: Spacing
    public let radius: Radius
    public let shadow: Shadow
    public let motion: Motion
    public let definition: ThemeDefinition?

    public init(
        id: ThemeID,
        colors: ThemeColors,
        typography: Typography = Typography(),
        spacing: Spacing = Spacing(),
        radius: Radius = Radius(),
        shadow: Shadow = .md,
        motion: Motion = Motion()
    ) {
        self.id = id
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radius = radius
        self.shadow = shadow
        self.motion = motion
        self.definition = nil
    }

    /// DSL initializer for declaring a theme within a PrismConfig builder.
    public init(
        _ id: ThemeID,
        extending parentID: ThemeID? = nil,
        colors: () -> Colors
    ) {
        self.id = id
        self.colors = ThemeColors.defaultLight
        self.typography = Typography()
        self.spacing = Spacing()
        self.radius = Radius()
        self.shadow = .md
        self.motion = Motion()
        self.definition = ThemeDefinition(id: id, parentID: parentID, colors: colors())
    }

    /// Resolves a CTFont instance using this theme's typography configuration with optional Dynamic Type scaling.
    public func font(
        for style: TextStyle,
        role: FontRole = .body,
        contentSizeCategory: ContentSizeCategory = .large,
        dynamicTypeConfig: DynamicTypeConfig? = nil,
        italic: Bool = false
    ) -> CTFont {
        FontResolver.shared.resolve(
            style: style,
            role: role,
            in: typography,
            contentSizeCategory: contentSizeCategory,
            dynamicTypeConfig: dynamicTypeConfig,
            italic: italic
        )
    }

    /// Convenience initializer to resolve a theme from a PrismConfig.
    public init(config: PrismConfig, themeID: ThemeID? = nil) throws {
        self = try config.resolveTheme(for: themeID)
    }

    /// Default baseline theme used as safety fallback.
    public static func fallbackDefault(id: ThemeID = .light) -> Theme {
        Theme(
            id: id,
            colors: ThemeColors.defaultLight,
            typography: Typography(),
            spacing: Spacing(),
            radius: Radius(),
            shadow: .md,
            motion: Motion()
        )
    }
}
