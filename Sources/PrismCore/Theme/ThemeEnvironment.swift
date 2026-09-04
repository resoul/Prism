import Foundation

/// Priority order for theme resolution:
/// 1. Subtree theme override (highest priority, used in previews, catalog, isolated scenes)
/// 2. User's explicit ThemeSelection (`ThemeSelection.explicit(ThemeID)`)
/// 3. SystemThemeMapping evaluated against the current system ColorScheme (`ThemeSelection.system`)
public struct ThemeEnvironment: Equatable, Sendable {
    public var config: PrismConfig
    public var selection: ThemeSelection
    public var systemMapping: SystemThemeMapping
    public var currentSystemScheme: ColorScheme
    public var subtreeOverride: ThemeID?

    public init(
        config: PrismConfig,
        selection: ThemeSelection = .system,
        systemMapping: SystemThemeMapping = SystemThemeMapping(),
        currentSystemScheme: ColorScheme = .light,
        subtreeOverride: ThemeID? = nil
    ) {
        self.config = config
        self.selection = selection
        self.systemMapping = systemMapping
        self.currentSystemScheme = currentSystemScheme
        self.subtreeOverride = subtreeOverride
    }

    /// Resolves the active Theme following the documented three-tier priority hierarchy.
    ///
    /// Throws when the selected or overridden theme is not declared in `config`.
    /// This keeps invalid configuration from silently reaching a rendering pass.
    public func resolvedTheme() throws -> Theme {
        let targetID: ThemeID

        if let overrideID = subtreeOverride {
            // Priority 1: Subtree override
            targetID = overrideID
        } else {
            switch selection {
            case .explicit(let explicitID):
                // Priority 2: Explicit user selection
                targetID = explicitID
            case .system:
                // Priority 3: System scheme mapping
                targetID = systemMapping.resolve(for: currentSystemScheme)
            }
        }

        return try config.resolveTheme(for: targetID)
    }

    /// Produces an environment fork with a localized subtree theme override.
    public func withSubtreeOverride(_ overrideID: ThemeID) -> ThemeEnvironment {
        var copy = self
        copy.subtreeOverride = overrideID
        return copy
    }

    /// Produces an environment fork updating the system ColorScheme.
    public func withSystemScheme(_ scheme: ColorScheme) -> ThemeEnvironment {
        var copy = self
        copy.currentSystemScheme = scheme
        return copy
    }

    /// Produces an environment fork updating the user's ThemeSelection.
    public func withSelection(_ newSelection: ThemeSelection) -> ThemeEnvironment {
        var copy = self
        copy.selection = newSelection
        return copy
    }
}

/// Contract for providing theme context down an element hierarchy.
public protocol ThemeProviderProtocol: Sendable {
    var themeEnvironment: ThemeEnvironment { get }
    var currentTheme: Theme { get }
}
