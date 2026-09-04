import Foundation
import CoreText
import CoreGraphics

/// Thread-safe key identifying a unique typographic face.
public struct FontCacheKey: Hashable, Sendable {
    public let family: String
    public let weight: FontWeight
    public let size: CGFloat
    public let italic: Bool
    public let tracking: CGFloat

    public init(
        family: String,
        weight: FontWeight,
        size: CGFloat,
        italic: Bool = false,
        tracking: CGFloat = 0
    ) {
        self.family = family
        self.weight = weight
        self.size = size
        self.italic = italic
        self.tracking = tracking
    }
}

/// A non-fatal event emitted when custom typography cannot be resolved exactly.
///
/// PrismCore deliberately exposes this as a callback rather than importing PrismLogging,
/// preserving the package dependency direction. Applications may bridge it to their
/// preferred logging system.
public enum FontResolutionDiagnostic: Equatable, Sendable {
    case usedSystemFallback(
        requestedFamily: String,
        weight: FontWeight,
        size: CGFloat,
        italic: Bool
    )
}

/// Thread-safe resolver producing CTFont instances with full-key caching and system font fallbacks.
public final class FontResolver: @unchecked Sendable {
    public static let shared = FontResolver()

    private let lock = NSLock()
    private var cache: [FontCacheKey: CTFont] = [:]
    private let diagnosticHandler: (@Sendable (FontResolutionDiagnostic) -> Void)?

    public init(
        diagnosticHandler: (@Sendable (FontResolutionDiagnostic) -> Void)? = nil
    ) {
        self.diagnosticHandler = diagnosticHandler
    }

    /// Resolves a CTFont for the given style and role within a typography configuration.
    public func resolve(
        style: TextStyle,
        role: FontRole,
        in typography: Typography,
        italic: Bool = false
    ) -> CTFont {
        let config = typography.fontConfig(for: role)
        let size = typography.fontSize(for: style)
        return resolve(
            family: config.family,
            weight: config.weight,
            size: size,
            italic: italic,
            tracking: config.tracking
        )
    }

    /// Resolves a CTFont using explicit parameters with caching and system fallback.
    public func resolve(
        family: String,
        weight: FontWeight,
        size: CGFloat,
        italic: Bool = false,
        tracking: CGFloat = 0
    ) -> CTFont {
        let key = FontCacheKey(
            family: family,
            weight: weight,
            size: size,
            italic: italic,
            tracking: tracking
        )

        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let font = createCTFont(family: family, weight: weight, size: size, italic: italic)

        lock.lock()
        cache[key] = font
        lock.unlock()

        return font
    }

    /// Creates a CTFont attempting the specified family, with fallback to system UI font.
    private func createCTFont(
        family: String,
        weight: FontWeight,
        size: CGFloat,
        italic: Bool
    ) -> CTFont {
        let weightNumber = NSNumber(value: Float(weight.coreTextWeight))
        let slantNumber = NSNumber(value: italic ? 0.2 : 0.0)

        let traits: [CFString: Any] = [
            kCTFontWeightTrait: weightNumber,
            kCTFontSlantTrait: slantNumber
        ]

        let attributes: [CFString: Any] = [
            kCTFontFamilyNameAttribute: family as CFString,
            kCTFontTraitsAttribute: traits as CFDictionary
        ]

        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let customFont = CTFontCreateWithFontDescriptor(descriptor, size, nil)

        // Verify if requested family was matched. If CoreText returned a fallback (e.g. LastResort),
        // or if family name doesn't match and isn't available, construct native system font with weight trait.
        let resolvedFamily = CTFontCopyFamilyName(customFont) as String
        if !resolvedFamily.localizedCaseInsensitiveContains(family) && !isFamilyInstalled(family) {
            diagnosticHandler?(
                .usedSystemFallback(
                    requestedFamily: family,
                    weight: weight,
                    size: size,
                    italic: italic
                )
            )
            return createSystemFontFallback(weight: weight, size: size, italic: italic)
        }

        return customFont
    }

    /// Creates a native system UI font with the specified weight and slant.
    private func createSystemFontFallback(
        weight: FontWeight,
        size: CGFloat,
        italic: Bool
    ) -> CTFont {
        let baseSystemFont = CTFontCreateUIFontForLanguage(.system, size, nil)
            ?? CTFontCreateWithName(".AppleSystemUIFont" as CFString, size, nil)

        let weightNumber = NSNumber(value: Float(weight.coreTextWeight))
        let slantNumber = NSNumber(value: italic ? 0.2 : 0.0)

        let traits: [CFString: Any] = [
            kCTFontWeightTrait: weightNumber,
            kCTFontSlantTrait: slantNumber
        ]

        let attributes: [CFString: Any] = [
            kCTFontTraitsAttribute: traits as CFDictionary
        ]

        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        return CTFontCreateCopyWithAttributes(baseSystemFont, size, nil, descriptor)
    }

    private func isFamilyInstalled(_ family: String) -> Bool {
        let attributes: [CFString: Any] = [
            kCTFontFamilyNameAttribute: family as CFString
        ]
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let matching = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, nil)
        return matching != nil && CFArrayGetCount(matching) > 0
    }

    /// Clears the font cache.
    public func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    /// Number of cached font instances.
    public var cachedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
}
