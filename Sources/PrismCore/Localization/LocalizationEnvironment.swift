import Foundation

/// Unified environment context governing localization, text direction, and accessibility text scaling.
public struct LocalizationEnvironment: Equatable, Sendable {
    public var locale: Locale
    public var layoutDirection: LayoutDirection
    public var contentSizeCategory: ContentSizeCategory
    public var dynamicTypeConfig: DynamicTypeConfig
    public var pseudoLocalization: Bool

    public init(
        locale: Locale = .current,
        layoutDirection: LayoutDirection? = nil,
        contentSizeCategory: ContentSizeCategory = .large,
        dynamicTypeConfig: DynamicTypeConfig = .standard,
        pseudoLocalization: Bool = false
    ) {
        self.locale = locale
        self.layoutDirection = layoutDirection ?? LayoutDirection.natural(for: locale)
        self.contentSizeCategory = contentSizeCategory
        self.dynamicTypeConfig = dynamicTypeConfig
        self.pseudoLocalization = pseudoLocalization
    }

    public static let standard = LocalizationEnvironment()

    /// Resolves a localized string key within this environment.
    public func localized(_ key: LocalizedStringKey, bundle: Bundle? = nil) -> LocalizedText {
        let text = LocalizationBundle.shared.localizedString(forKey: key, locale: locale, bundle: bundle)
        return LocalizedText(string: text, key: key, direction: layoutDirection)
    }

    /// Resolves a pluralized localized string within this environment.
    public func localizedPlural(key: String, count: Int) -> LocalizedText {
        let text = LocalizationBundle.shared.localizedPlural(forKey: key, count: count, locale: locale)
        return LocalizedText(string: text, key: nil, direction: layoutDirection)
    }

    /// Resolves directional edge insets into absolute coordinate insets for this layout direction.
    public func resolveInsets(_ insets: DirectionalEdgeInsets) -> AbsoluteEdgeInsets {
        insets.resolved(for: layoutDirection)
    }

    /// Resolves semantic horizontal alignment into absolute left/center/right.
    public func resolveAlignment(_ alignment: HorizontalAlignment) -> AbsoluteHorizontalAlignment {
        alignment.absolute(for: layoutDirection)
    }

    /// Creates an updated environment with a new locale, automatically updating natural reading direction.
    public func withLocale(_ newLocale: Locale) -> LocalizationEnvironment {
        var copy = self
        copy.locale = newLocale
        copy.layoutDirection = LayoutDirection.natural(for: newLocale)
        return copy
    }

    /// Creates an updated environment overriding the reading direction.
    public func withDirection(_ newDirection: LayoutDirection) -> LocalizationEnvironment {
        var copy = self
        copy.layoutDirection = newDirection
        return copy
    }

    /// Creates an updated environment updating the Dynamic Type content size category.
    public func withContentSizeCategory(_ newCategory: ContentSizeCategory) -> LocalizationEnvironment {
        var copy = self
        copy.contentSizeCategory = newCategory
        return copy
    }
}
