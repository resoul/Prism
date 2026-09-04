import Foundation

/// Text and layout direction across the UI hierarchy.
public enum LayoutDirection: String, Sendable, CaseIterable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"

    public var isRTL: Bool {
        self == .rightToLeft
    }

    public var isLTR: Bool {
        self == .leftToRight
    }

    /// Determines the natural layout direction for a given BCP-47 language code or locale identifier.
    public static func natural(for locale: Locale) -> LayoutDirection {
        let languageCode: String
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, *) {
            languageCode = locale.language.languageCode?.identifier ?? "en"
        } else {
            languageCode = locale.languageCode ?? "en"
        }

        // Common Right-to-Left language codes: Arabic, Hebrew, Persian, Urdu, Yiddish, Dhivehi, Kurdish, Sindhi, Uighur
        let rtlLanguages: Set<String> = [
            "ar", "he", "fa", "ur", "yi", "dv", "ku", "sd", "ug", "ps"
        ]

        return rtlLanguages.contains(languageCode.lowercased()) ? .rightToLeft : .leftToRight
    }
}
