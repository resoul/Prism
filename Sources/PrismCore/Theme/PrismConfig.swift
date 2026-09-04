import Foundation
import CoreGraphics

/// Diagnostic validation errors detected during PrismConfig validation and theme resolution.
public enum ConfigValidationError: Error, Equatable, Sendable {
    case duplicateThemeID(ThemeID)
    case missingParentTheme(child: ThemeID, parent: ThemeID)
    case inheritanceCycle([ThemeID])
    case negativeSpacing(CGFloat)
    case negativeRadius(CGFloat)
    case emptyFontFamily(FontRole)
    case invalidHexColor(String)
    case missingRequiredTheme(ThemeID)
    case invalidBaseSize(CGFloat)
}

/// Token collection defining typography, spacing, radius, shadow, and motion inherited by all themes.
public struct BaseTokens: Equatable, Sendable {
    public var typography: Typography
    public var spacing: Spacing
    public var radius: Radius
    public var shadow: Shadow
    public var motion: Motion

    public init(
        typography: Typography = Typography(),
        spacing: Spacing = Spacing(),
        radius: Radius = Radius(),
        shadow: Shadow = .md,
        motion: Motion = Motion()
    ) {
        self.typography = typography
        self.spacing = spacing
        self.radius = radius
        self.shadow = shadow
        self.motion = motion
    }

    public init(@BaseTokensBuilder _ items: () -> [BaseTokenItem]) {
        var typ = Typography()
        var sp = Spacing()
        var rad = Radius()
        var sh = Shadow.md
        var mot = Motion()

        for item in items() {
            switch item {
            case .typography(let t): typ = t
            case .spacing(let s): sp = s
            case .radius(let r): rad = r
            case .shadow(let s): sh = s
            case .motion(let m): mot = m
            }
        }

        self.init(typography: typ, spacing: sp, radius: rad, shadow: sh, motion: mot)
    }

    public func validate() throws {
        do {
            try typography.validate()
        } catch let TypographyValidationError.emptyFontFamily(role) {
            throw ConfigValidationError.emptyFontFamily(role)
        } catch let TypographyValidationError.invalidBaseSize(size) {
            throw ConfigValidationError.invalidBaseSize(size)
        }

        do {
            try spacing.validate()
        } catch let SpacingValidationError.negativeValue(v) {
            throw ConfigValidationError.negativeSpacing(v)
        }

        do {
            try radius.validate()
        } catch let RadiusValidationError.negativeValue(v) {
            throw ConfigValidationError.negativeRadius(v)
        }
    }
}

public enum BaseTokenItem: Sendable {
    case typography(Typography)
    case spacing(Spacing)
    case radius(Radius)
    case shadow(Shadow)
    case motion(Motion)
}

@resultBuilder
public struct BaseTokensBuilder {
    public static func buildExpression(_ item: Typography) -> BaseTokenItem { .typography(item) }
    public static func buildExpression(_ item: Spacing) -> BaseTokenItem { .spacing(item) }
    public static func buildExpression(_ item: Radius) -> BaseTokenItem { .radius(item) }
    public static func buildExpression(_ item: Shadow) -> BaseTokenItem { .shadow(item) }
    public static func buildExpression(_ item: Motion) -> BaseTokenItem { .motion(item) }

    public static func buildBlock(_ components: BaseTokenItem...) -> [BaseTokenItem] {
        components
    }
}

/// Raw definition of a named theme before resolution.
public struct ThemeDefinition: Equatable, Sendable {
    public let id: ThemeID
    public let parentID: ThemeID?
    public let colors: Colors
    public let typography: Typography?
    public let spacing: Spacing?
    public let radius: Radius?
    public let shadow: Shadow?
    public let motion: Motion?

    public init(
        id: ThemeID,
        parentID: ThemeID? = nil,
        colors: Colors,
        typography: Typography? = nil,
        spacing: Spacing? = nil,
        radius: Radius? = nil,
        shadow: Shadow? = nil,
        motion: Motion? = nil
    ) {
        self.id = id
        self.parentID = parentID
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radius = radius
        self.shadow = shadow
        self.motion = motion
    }
}

public enum PrismConfigItem: Sendable {
    case baseTokens(BaseTokens)
    case theme(ThemeDefinition)
}

@resultBuilder
public struct PrismConfigBuilder {
    public static func buildExpression(_ item: BaseTokens) -> PrismConfigItem {
        .baseTokens(item)
    }

    public static func buildExpression(_ item: ThemeDefinition) -> PrismConfigItem {
        .theme(item)
    }

    public static func buildExpression(_ item: Theme) -> PrismConfigItem {
        if let def = item.definition {
            return .theme(def)
        }
        return .theme(ThemeDefinition(id: item.id, parentID: nil, colors: Colors()))
    }

    public static func buildBlock(_ components: PrismConfigItem...) -> [PrismConfigItem] {
        components
    }

    public static func buildArray(_ components: [[PrismConfigItem]]) -> [PrismConfigItem] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [PrismConfigItem]?) -> [PrismConfigItem] {
        component ?? []
    }

    public static func buildEither(first component: [PrismConfigItem]) -> [PrismConfigItem] {
        component
    }

    public static func buildEither(second component: [PrismConfigItem]) -> [PrismConfigItem] {
        component
    }
}

/// Pure, immutable design configuration for the application.
///
/// Contains declared base tokens, named themes, and resolution logic without global state.
public struct PrismConfig: Equatable, Sendable {
    public let baseTokens: BaseTokens
    public let definitions: [ThemeDefinition]
    public let resolvedThemes: [ThemeID: Theme]

    public init(
        baseTokens: BaseTokens = BaseTokens(),
        definitions: [ThemeDefinition] = []
    ) throws {
        self.baseTokens = baseTokens
        self.definitions = definitions
        self.resolvedThemes = try PrismConfig.resolve(baseTokens: baseTokens, definitions: definitions)
    }

    public init(@PrismConfigBuilder _ items: () -> [PrismConfigItem]) {
        var base = BaseTokens()
        var defs: [ThemeDefinition] = []

        for item in items() {
            switch item {
            case .baseTokens(let b):
                base = b
            case .theme(let d):
                defs.append(d)
            }
        }

        self.baseTokens = base
        self.definitions = defs
        let resolved = (try? PrismConfig.resolve(baseTokens: base, definitions: defs)) ?? [:]
        self.resolvedThemes = resolved
    }

    /// Validates the configuration and throws detailed diagnostic errors.
    public func validate() throws {
        try baseTokens.validate()

        // Check malformed hex colors
        for def in definitions {
            let malformed = def.colors.malformedHexList
            if let first = malformed.first {
                throw ConfigValidationError.invalidHexColor(first)
            }
        }

        // Check duplicate IDs
        var seen = Set<ThemeID>()
        for def in definitions {
            if seen.contains(def.id) {
                throw ConfigValidationError.duplicateThemeID(def.id)
            }
            seen.insert(def.id)
        }

        let defMap = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })

        // Check missing parents
        for def in definitions {
            if let parent = def.parentID {
                if !defMap.keys.contains(parent) {
                    throw ConfigValidationError.missingParentTheme(child: def.id, parent: parent)
                }
            }
        }

        // Check inheritance cycles
        for def in definitions {
            var path: [ThemeID] = []
            try PrismConfig.detectCycle(id: def.id, defMap: defMap, path: &path)
        }
    }

    private static func detectCycle(id: ThemeID, defMap: [ThemeID: ThemeDefinition], path: inout [ThemeID]) throws {
        if let index = path.firstIndex(of: id) {
            let cycle = Array(path[index...]) + [id]
            throw ConfigValidationError.inheritanceCycle(cycle)
        }
        path.append(id)
        if let parentID = defMap[id]?.parentID {
            try detectCycle(id: parentID, defMap: defMap, path: &path)
        }
        path.removeLast()
    }

    /// Resolves themes in topological order from base tokens and definitions.
    private static func resolve(baseTokens: BaseTokens, definitions: [ThemeDefinition]) throws -> [ThemeID: Theme] {
        let config = PrismConfig(unvalidatedBaseTokens: baseTokens, definitions: definitions)
        try config.validate()

        let defMap = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
        var resolved: [ThemeID: Theme] = [:]

        func resolveNode(id: ThemeID) -> Theme {
            if let cached = resolved[id] {
                return cached
            }

            guard let def = defMap[id] else {
                return Theme.fallbackDefault(id: id)
            }

            let parentTheme: Theme? = def.parentID != nil ? resolveNode(id: def.parentID!) : nil

            let colors = def.colors.resolve(inheritingFrom: parentTheme?.colors)
            let typography = def.typography ?? parentTheme?.typography ?? baseTokens.typography
            let spacing = def.spacing ?? parentTheme?.spacing ?? baseTokens.spacing
            let radius = def.radius ?? parentTheme?.radius ?? baseTokens.radius
            let shadow = def.shadow ?? parentTheme?.shadow ?? baseTokens.shadow
            let motion = def.motion ?? parentTheme?.motion ?? baseTokens.motion

            let theme = Theme(
                id: def.id,
                colors: colors,
                typography: typography,
                spacing: spacing,
                radius: radius,
                shadow: shadow,
                motion: motion
            )

            resolved[id] = theme
            return theme
        }

        for def in definitions {
            _ = resolveNode(id: def.id)
        }

        return resolved
    }

    private init(unvalidatedBaseTokens: BaseTokens, definitions: [ThemeDefinition]) {
        self.baseTokens = unvalidatedBaseTokens
        self.definitions = definitions
        self.resolvedThemes = [:]
    }

    /// Resolves a complete Theme for the specified ThemeID.
    public func resolveTheme(for themeID: ThemeID) throws -> Theme {
        try resolveTheme(for: Optional(themeID))
    }

    /// Resolves a complete Theme for the specified ThemeID or defaults to `.light` or the primary theme.
    public func resolveTheme(for themeID: ThemeID? = nil) throws -> Theme {
        try validate()

        if let requested = themeID {
            if let found = resolvedThemes[requested] {
                return found
            }
            throw ConfigValidationError.missingRequiredTheme(requested)
        }

        // Default to .light if available, otherwise first declared theme, otherwise fallbackDefault
        if let light = resolvedThemes[.light] {
            return light
        }
        if let first = definitions.first, let found = resolvedThemes[first.id] {
            return found
        }
        return Theme.fallbackDefault(id: .light)
    }
}
