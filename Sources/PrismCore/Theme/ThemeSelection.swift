import Foundation

/// System appearance mode.
public enum ColorScheme: String, Sendable, CaseIterable {
    case light
    case dark
}

/// User's selected theme mode.
public enum ThemeSelection: Hashable, Sendable {
    case system
    case explicit(ThemeID)

    public static let light = ThemeSelection.explicit(.light)
    public static let dark = ThemeSelection.explicit(.dark)
    public static let midnight = ThemeSelection.explicit(.midnight)

    public static func named(_ id: ThemeID) -> ThemeSelection {
        .explicit(id)
    }
}

/// Mapping determining which ThemeID to activate when `ThemeSelection.system` is active.
public struct SystemThemeMapping: Equatable, Sendable {
    public var light: ThemeID
    public var dark: ThemeID

    public init(light: ThemeID = .light, dark: ThemeID = .dark) {
        self.light = light
        self.dark = dark
    }

    /// Resolves the concrete ThemeID for the current system ColorScheme.
    public func resolve(for scheme: ColorScheme) -> ThemeID {
        switch scheme {
        case .light: return light
        case .dark: return dark
        }
    }
}
