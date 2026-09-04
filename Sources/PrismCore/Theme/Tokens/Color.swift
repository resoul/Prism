import Foundation
import CoreGraphics

/// Platform-agnostic, immutable color representation in RGBA space.
///
/// Encapsulates color components without exposing UIKit (`UIColor`) or AppKit (`NSColor`).
public struct Color: Hashable, Sendable, CustomStringConvertible {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat
    public let rawHex: String?
    public let isMalformedHex: Bool

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
        self.alpha = max(0, min(1, alpha))
        self.rawHex = nil
        self.isMalformedHex = false
    }

    private init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, rawHex: String, isMalformed: Bool) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.rawHex = rawHex
        self.isMalformedHex = isMalformed
    }

    public var description: String {
        if let rawHex {
            return "Color(\(rawHex))"
        }
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        let a = String(format: "%.2f", alpha)
        return "Color(r: \(r), g: \(g), b: \(b), a: \(a))"
    }

    /// Converts to CoreGraphics CGColor for CALayer rendering.
    public var cgColor: CGColor {
        CGColor(
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            components: [red, green, blue, alpha]
        ) ?? CGColor(gray: 0, alpha: alpha)
    }

    /// Returns a new Color with modified opacity.
    public func opacity(_ newAlpha: CGFloat) -> Color {
        Color(red: red, green: green, blue: blue, alpha: max(0, min(1, newAlpha)))
    }

    // MARK: - Hex Parsing & Creation

    /// Creates a Color from a hex string, recording validation state for PrismConfig diagnostics.
    public static func hex(_ hexString: String) -> Color {
        do {
            return try Color(validatingHex: hexString)
        } catch {
            return Color(red: 0, green: 0, blue: 0, alpha: 1, rawHex: hexString, isMalformed: true)
        }
    }

    /// Creates a Color from a hex string or throws an error if invalid.
    public init(validatingHex hexString: String) throws {
        var cleanHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }

        let length = cleanHex.count
        guard length == 3 || length == 4 || length == 6 || length == 8 else {
            throw ColorHexError.invalidLength(hexString)
        }

        guard let hexNumber = UInt64(cleanHex, radix: 16) else {
            throw ColorHexError.invalidCharacters(hexString)
        }

        let r, g, b, a: CGFloat

        switch length {
        case 3: // RGB (12-bit)
            r = CGFloat((hexNumber & 0xF00) >> 8) / 15.0
            g = CGFloat((hexNumber & 0x0F0) >> 4) / 15.0
            b = CGFloat(hexNumber & 0x00F) / 15.0
            a = 1.0
        case 4: // RGBA (16-bit)
            r = CGFloat((hexNumber & 0xF000) >> 12) / 15.0
            g = CGFloat((hexNumber & 0x0F00) >> 8) / 15.0
            b = CGFloat((hexNumber & 0x00F0) >> 4) / 15.0
            a = CGFloat(hexNumber & 0x000F) / 15.0
        case 6: // RRGGBB (24-bit)
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
            a = 1.0
        case 8: // RRGGBBAA (32-bit)
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000FF) / 255.0
        default:
            throw ColorHexError.invalidLength(hexString)
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Predefined Static Colors
    public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
}

public enum ColorHexError: Error, Equatable, Sendable {
    case invalidLength(String)
    case invalidCharacters(String)
}

/// Fully resolved, complete semantic color palette for an active theme.
public struct ThemeColors: Equatable, Sendable {
    public let background: Color
    public let foreground: Color
    public let primary: Color
    public let primaryForeground: Color
    public let secondary: Color
    public let secondaryForeground: Color
    public let muted: Color
    public let mutedForeground: Color
    public let border: Color
    public let destructive: Color
    public let destructiveForeground: Color
    public let accent: Color
    public let accentForeground: Color
    public let custom: [String: Color]

    public init(
        background: Color,
        foreground: Color,
        primary: Color,
        primaryForeground: Color,
        secondary: Color,
        secondaryForeground: Color,
        muted: Color,
        mutedForeground: Color,
        border: Color,
        destructive: Color,
        destructiveForeground: Color,
        accent: Color,
        accentForeground: Color,
        custom: [String: Color] = [:]
    ) {
        self.background = background
        self.foreground = foreground
        self.primary = primary
        self.primaryForeground = primaryForeground
        self.secondary = secondary
        self.secondaryForeground = secondaryForeground
        self.muted = muted
        self.mutedForeground = mutedForeground
        self.border = border
        self.destructive = destructive
        self.destructiveForeground = destructiveForeground
        self.accent = accent
        self.accentForeground = accentForeground
        self.custom = custom
    }

    public static let defaultLight = ThemeColors(
        background: .white,
        foreground: Color(red: 0.06, green: 0.09, blue: 0.16),
        primary: Color(red: 0.39, green: 0.36, blue: 1.0),
        primaryForeground: .white,
        secondary: Color(red: 0.95, green: 0.96, blue: 0.98),
        secondaryForeground: Color(red: 0.06, green: 0.09, blue: 0.16),
        muted: Color(red: 0.95, green: 0.96, blue: 0.98),
        mutedForeground: Color(red: 0.39, green: 0.45, blue: 0.55),
        border: Color(red: 0.89, green: 0.91, blue: 0.94),
        destructive: Color(red: 0.88, green: 0.11, blue: 0.28),
        destructiveForeground: .white,
        accent: Color(red: 0.95, green: 0.96, blue: 0.98),
        accentForeground: Color(red: 0.06, green: 0.09, blue: 0.16),
        custom: [:]
    )
}

/// Declarative color specification used in PrismConfig and theme definitions.
public struct Colors: Equatable, Sendable {
    public var background: Color?
    public var foreground: Color?
    public var primary: Color?
    public var primaryForeground: Color?
    public var secondary: Color?
    public var secondaryForeground: Color?
    public var muted: Color?
    public var mutedForeground: Color?
    public var border: Color?
    public var destructive: Color?
    public var destructiveForeground: Color?
    public var accent: Color?
    public var accentForeground: Color?
    public var custom: [String: Color]

    public init(
        background: Color? = nil,
        foreground: Color? = nil,
        primary: Color? = nil,
        primaryForeground: Color? = nil,
        secondary: Color? = nil,
        secondaryForeground: Color? = nil,
        muted: Color? = nil,
        mutedForeground: Color? = nil,
        border: Color? = nil,
        destructive: Color? = nil,
        destructiveForeground: Color? = nil,
        accent: Color? = nil,
        accentForeground: Color? = nil,
        custom: [String: Color] = [:]
    ) {
        self.background = background
        self.foreground = foreground
        self.primary = primary
        self.primaryForeground = primaryForeground
        self.secondary = secondary
        self.secondaryForeground = secondaryForeground
        self.muted = muted
        self.mutedForeground = mutedForeground
        self.border = border
        self.destructive = destructive
        self.destructiveForeground = destructiveForeground
        self.accent = accent
        self.accentForeground = accentForeground
        self.custom = custom
    }

    /// Convenience initializer for minimal overrides matching the DSL pattern (background, muted, primary).
    public init(
        background: Color? = nil,
        muted: Color? = nil,
        primary: Color? = nil
    ) {
        self.init(
            background: background,
            primary: primary,
            muted: muted
        )
    }

    /// Resolves this configuration into a complete ThemeColors palette against a parent or default.
    public func resolve(inheritingFrom parent: ThemeColors? = nil) -> ThemeColors {
        let base = parent ?? ThemeColors.defaultLight
        return ThemeColors(
            background: background ?? base.background,
            foreground: foreground ?? base.foreground,
            primary: primary ?? base.primary,
            primaryForeground: primaryForeground ?? base.primaryForeground,
            secondary: secondary ?? base.secondary,
            secondaryForeground: secondaryForeground ?? base.secondaryForeground,
            muted: muted ?? base.muted,
            mutedForeground: mutedForeground ?? base.mutedForeground,
            border: border ?? base.border,
            destructive: destructive ?? base.destructive,
            destructiveForeground: destructiveForeground ?? base.destructiveForeground,
            accent: accent ?? base.accent,
            accentForeground: accentForeground ?? base.accentForeground,
            custom: base.custom.merging(custom) { _, new in new }
        )
    }

    /// Merges overrides on top of this Colors definition.
    public func merging(overrides: Colors) -> Colors {
        var result = self
        if let bg = overrides.background { result.background = bg }
        if let fg = overrides.foreground { result.foreground = fg }
        if let p = overrides.primary { result.primary = p }
        if let pf = overrides.primaryForeground { result.primaryForeground = pf }
        if let s = overrides.secondary { result.secondary = s }
        if let sf = overrides.secondaryForeground { result.secondaryForeground = sf }
        if let m = overrides.muted { result.muted = m }
        if let mf = overrides.mutedForeground { result.mutedForeground = mf }
        if let b = overrides.border { result.border = b }
        if let d = overrides.destructive { result.destructive = d }
        if let df = overrides.destructiveForeground { result.destructiveForeground = df }
        if let a = overrides.accent { result.accent = a }
        if let af = overrides.accentForeground { result.accentForeground = af }
        for (k, v) in overrides.custom {
            result.custom[k] = v
        }
        return result
    }

    /// Returns all malformed hex strings contained within this specification.
    public var malformedHexList: [String] {
        var list: [String] = []
        let allColors = [
            background, foreground, primary, primaryForeground,
            secondary, secondaryForeground, muted, mutedForeground,
            border, destructive, destructiveForeground, accent, accentForeground
        ].compactMap { $0 } + Array(custom.values)

        for color in allColors where color.isMalformedHex {
            if let raw = color.rawHex {
                list.append(raw)
            }
        }
        return list
    }
}
