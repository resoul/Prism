import Foundation
import CoreGraphics

/// Source representation for image visual primitives.
public enum ImageSource: Hashable, Sendable, CustomStringConvertible {
    /// Remote or file URL.
    case url(URL)

    /// Named asset located in an optional bundle.
    case named(String, bundle: Bundle? = nil)

    /// Raw encoded image data (JPEG, PNG, WebP, etc.).
    case data(Data)

    /// In-memory CoreGraphics bitmap image.
    case cgImage(CGImage)

    public var description: String {
        switch self {
        case .url(let url):
            // Redact query parameters for privacy
            return "url(\(url.scheme ?? "")://\(url.host ?? "")\(url.path))"
        case .named(let name, let bundle):
            return "named(\(name), bundle: \(bundle?.bundleIdentifier ?? "main"))"
        case .data(let data):
            return "data(\(data.count) bytes)"
        case .cgImage(let image):
            return "cgImage(\(image.width)x\(image.height))"
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .url(let url):
            hasher.combine(0)
            hasher.combine(url)
        case .named(let name, let bundle):
            hasher.combine(1)
            hasher.combine(name)
            hasher.combine(bundle?.bundleIdentifier)
        case .data(let data):
            hasher.combine(2)
            hasher.combine(data)
        case .cgImage(let image):
            hasher.combine(3)
            hasher.combine(image.width)
            hasher.combine(image.height)
        }
    }

    public static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        switch (lhs, rhs) {
        case (.url(let l), .url(let r)):
            return l == r
        case (.named(let lName, let lBundle), .named(let rName, let rBundle)):
            return lName == rName && lBundle?.bundleIdentifier == rBundle?.bundleIdentifier
        case (.data(let l), .data(let r)):
            return l == r
        case (.cgImage(let l), .cgImage(let r)):
            return l === r
        default:
            return false
        }
    }
}

/// Content scaling mode defining how an image fits within its display frame.
public enum ImageContentMode: String, Sendable, Equatable, Codable {
    /// Scale image to maintain aspect ratio while filling entire frame (may clip).
    case fill

    /// Scale image to fit within frame while preserving aspect ratio (letterbox).
    case fit

    /// Non-uniformly stretch image to completely fill frame bounds.
    case stretch

    /// Center image at original resolution without scaling.
    case center
}
