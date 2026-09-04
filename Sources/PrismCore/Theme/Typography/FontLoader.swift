import Foundation
import CoreText

/// Diagnostic errors for dynamic font registration.
public enum FontLoaderError: Error, Equatable, Sendable {
    case fileNotFound(URL)
    case bundleResourceNotFound(name: String)
    case registrationFailed(String)
}

/// Dynamic font loader for registering custom TTF/OTF fonts from bundles and URLs.
public enum FontLoader {

    /// Registers a font file located within a specified Bundle.
    public static func register(
        fromBundle bundle: Bundle = .main,
        name: String,
        subdirectory: String? = nil
    ) throws {
        let nameWithoutExt: String
        let ext: String?

        if let dotIndex = name.lastIndex(of: ".") {
            nameWithoutExt = String(name[..<dotIndex])
            ext = String(name[name.index(after: dotIndex)...])
        } else {
            nameWithoutExt = name
            ext = "ttf"
        }

        guard let fontURL = bundle.url(forResource: nameWithoutExt, withExtension: ext, subdirectory: subdirectory) else {
            throw FontLoaderError.bundleResourceNotFound(name: name)
        }

        try register(fromURL: fontURL)
    }

    /// Registers a font from an explicit file URL into the process font table.
    public static func register(fromURL url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FontLoaderError.fileNotFound(url)
        }

        var errorRef: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)

        if !success {
            let errorDescription: String
            if let cfError = errorRef?.takeRetainedValue() {
                errorDescription = CFErrorCopyDescription(cfError) as String
            } else {
                errorDescription = "Unknown registration error"
            }
            throw FontLoaderError.registrationFailed(errorDescription)
        }
    }
}
