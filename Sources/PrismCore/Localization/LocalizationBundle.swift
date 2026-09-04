import Foundation

/// Resolved localized text representation with associated layout direction metadata.
public struct LocalizedText: Equatable, Sendable, CustomStringConvertible {
    public let string: String
    public let key: LocalizedStringKey?
    public let direction: LayoutDirection

    public init(string: String, key: LocalizedStringKey? = nil, direction: LayoutDirection = .leftToRight) {
        self.string = string
        self.key = key
        self.direction = direction
    }

    public var description: String { string }
}

/// Plural categories supported by CLDR / Foundation localization.
public enum PluralCategory: String, Sendable, CaseIterable {
    case zero
    case one
    case two
    case few
    case many
    case other
}

/// Provider managing string tables, plural rules, missing key fallbacks and pseudo-localization.
public final class LocalizationBundle: @unchecked Sendable {
    public static let shared = LocalizationBundle()

    private let lock = NSLock()
    public var isDevelopmentMode: Bool
    public var pseudoLocalizationEnabled: Bool

    // In-memory string tables for testing and custom module tables: [LocaleIdentifier: [Table: [Key: Value]]]
    private var inMemoryTables: [String: [String: [String: String]]] = [:]

    // In-memory plural tables: [LocaleIdentifier: [Key: [PluralCategory: FormatString]]]
    private var inMemoryPlurals: [String: [String: [String: String]]] = [:]

    public init(isDevelopmentMode: Bool = false, pseudoLocalizationEnabled: Bool = false) {
        self.isDevelopmentMode = isDevelopmentMode
        self.pseudoLocalizationEnabled = pseudoLocalizationEnabled
    }

    /// Registers in-memory translation strings (useful for component tests and dynamic string packages).
    public func registerStrings(
        _ table: [String: String],
        tableName: String = "Localizable",
        localeIdentifier: String
    ) {
        lock.lock()
        defer { lock.unlock() }
        var tables = inMemoryTables[localeIdentifier] ?? [:]
        var existing = tables[tableName] ?? [:]
        for (k, v) in table { existing[k] = v }
        tables[tableName] = existing
        inMemoryTables[localeIdentifier] = tables
    }

    /// Registers in-memory plural translations for count-based formatting.
    public func registerPlurals(
        _ plurals: [String: [PluralCategory: String]],
        localeIdentifier: String
    ) {
        lock.lock()
        defer { lock.unlock() }
        var map = inMemoryPlurals[localeIdentifier] ?? [:]
        for (key, forms) in plurals {
            var stringForms: [String: String] = [:]
            for (cat, template) in forms {
                stringForms[cat.rawValue] = template
            }
            map[key] = stringForms
        }
        inMemoryPlurals[localeIdentifier] = map
    }

    /// Resolves a LocalizedStringKey into a localized string for the specified Locale.
    public func localizedString(
        forKey key: LocalizedStringKey,
        locale: Locale = .current,
        bundle: Bundle? = nil
    ) -> String {
        let tableName = key.tableName ?? "Localizable"
        let localeID = locale.identifier

        lock.lock()
        let inMemoryValue = inMemoryTables[localeID]?[tableName]?[key.key]
            ?? inMemoryTables[String(localeID.prefix(2))]?[tableName]?[key.key]
        lock.unlock()

        let rawFormat: String
        let isMissing: Bool

        if let inMemoryValue {
            rawFormat = inMemoryValue
            isMissing = false
        } else if let bundle = bundle {
            let bundleVal = bundle.localizedString(forKey: key.key, value: nil, table: tableName)
            if bundleVal != key.key {
                rawFormat = bundleVal
                isMissing = false
            } else {
                rawFormat = key.key
                isMissing = true
            }
        } else {
            rawFormat = key.key
            isMissing = true
        }

        let formatted: String
        if isMissing && isDevelopmentMode {
            formatted = "[MISSING: \"\(key.key)\"]"
        } else if key.arguments.isEmpty {
            formatted = rawFormat
        } else {
            formatted = String(format: rawFormat, arguments: key.arguments.map { $0 as CVarArg })
        }

        if pseudoLocalizationEnabled {
            return applyPseudoLocalization(to: formatted)
        }

        return formatted
    }

    /// Resolves plural forms for a count-based localizable string.
    public func localizedPlural(
        forKey key: String,
        count: Int,
        locale: Locale = .current
    ) -> String {
        let localeID = locale.identifier
        let category = resolvePluralCategory(for: count, locale: locale)

        lock.lock()
        let pluralTemplate = inMemoryPlurals[localeID]?[key]?[category.rawValue]
            ?? inMemoryPlurals[localeID]?[key]?[PluralCategory.other.rawValue]
            ?? inMemoryPlurals[String(localeID.prefix(2))]?[key]?[category.rawValue]
            ?? inMemoryPlurals[String(localeID.prefix(2))]?[key]?[PluralCategory.other.rawValue]
        lock.unlock()

        guard let template = pluralTemplate else {
            if isDevelopmentMode {
                return "[MISSING PLURAL: \"\(key)\" count=\(count)]"
            }
            return "\(count) \(key)"
        }

        let result = String(format: template, count)
        return pseudoLocalizationEnabled ? applyPseudoLocalization(to: result) : result
    }

    /// Determines plural category based on standard English/Romance and Slavic cardinality rules.
    public func resolvePluralCategory(for count: Int, locale: Locale) -> PluralCategory {
        let lang: String
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, *) {
            lang = locale.language.languageCode?.identifier.lowercased() ?? "en"
        } else {
            lang = locale.languageCode?.lowercased() ?? "en"
        }

        switch lang {
        case "ru", "uk", "be":
            // Slavic plural rules
            let mod10 = count % 10
            let mod100 = count % 100
            if mod10 == 1 && mod100 != 11 {
                return .one
            } else if (mod10 >= 2 && mod10 <= 4) && !(mod100 >= 12 && mod100 <= 14) {
                return .few
            } else if mod10 == 0 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 11 && mod100 <= 14) {
                return .many
            } else {
                return .other
            }
        default:
            // Standard Germanic / Romance rules (one vs other, with zero)
            if count == 0 {
                return .zero
            } else if count == 1 {
                return .one
            } else {
                return .other
            }
        }
    }

    /// Applies pseudo-localization expansion and character substitution to test UI elasticity.
    public func applyPseudoLocalization(to text: String) -> String {
        let substitutions: [Character: Character] = [
            "a": "ä", "A": "Å",
            "e": "é", "E": "É",
            "i": "í", "I": "Î",
            "o": "ö", "O": "Ö",
            "u": "ü", "U": "Û"
        ]

        var transformed = ""
        for char in text {
            transformed.append(substitutions[char] ?? char)
        }

        return "[--- \(transformed) ---]"
    }
}
