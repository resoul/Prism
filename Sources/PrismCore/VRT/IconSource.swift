import Foundation
import CoreGraphics

/// Source specification for vector and raster icon primitives.
public enum IconSource: Hashable, @unchecked Sendable, CustomStringConvertible {
    /// Apple SF Symbols by system symbol name.
    case sf(name: String)
    /// SVG asset loaded by name from a registered icon pack or bundle.
    case svg(named: String, bundle: String? = nil)
    /// SVG loaded directly from a file URL.
    case svgURL(URL)
    /// Pre-compiled vector `CGPath` with reference `viewBox`.
    case path(CGPath, viewBox: CGRect)
    /// Bitmap or PDF raster fallback asset.
    case raster(named: String, bundle: String? = nil)

    public var description: String {
        switch self {
        case .sf(let name):
            return "sf(\"\(name)\")"
        case .svg(let name, let bundle):
            if let bundle { return "svg(\"\(name)\", bundle: \"\(bundle)\")" }
            return "svg(\"\(name)\")"
        case .svgURL(let url):
            return "svgURL(\(url.path))"
        case .path(_, let viewBox):
            return "path(viewBox: \(viewBox))"
        case .raster(let name, let bundle):
            if let bundle { return "raster(\"\(name)\", bundle: \"\(bundle)\")" }
            return "raster(\"\(name)\")"
        }
    }

    public static func == (lhs: IconSource, rhs: IconSource) -> Bool {
        switch (lhs, rhs) {
        case (.sf(let a), .sf(let b)):
            return a == b
        case (.svg(let a, let b), .svg(let c, let d)):
            return a == c && b == d
        case (.svgURL(let a), .svgURL(let b)):
            return a == b
        case (.path(let p1, let v1), .path(let p2, let v2)):
            return v1 == v2 && (p1 === p2 || CFEqual(p1, p2))
        case (.raster(let a, let b), .raster(let c, let d)):
            return a == c && b == d
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .sf(let name):
            hasher.combine(0)
            hasher.combine(name)
        case .svg(let name, let bundle):
            hasher.combine(1)
            hasher.combine(name)
            hasher.combine(bundle)
        case .svgURL(let url):
            hasher.combine(2)
            hasher.combine(url)
        case .path(let path, let viewBox):
            hasher.combine(3)
            hasher.combine(viewBox.origin.x)
            hasher.combine(viewBox.origin.y)
            hasher.combine(viewBox.width)
            hasher.combine(viewBox.height)
            hasher.combine(CFHash(path))
        case .raster(let name, let bundle):
            hasher.combine(4)
            hasher.combine(name)
            hasher.combine(bundle)
        }
    }
}

// MARK: - Sizing & Styling

/// Predefined standard icon dimensions adhering to design token scales.
public enum IconSize: Hashable, Sendable, Equatable {
    /// Extra Small: 12pt (subtext, badges, dense tables).
    case xs
    /// Small: 16pt (inline tags, secondary button actions).
    case sm
    /// Medium: 20pt (standard buttons, form inputs).
    case md
    /// Large: 24pt (navigation bars, prominent cards).
    case lg
    /// Extra Large: 32pt (hero banners, empty state illustrations).
    case xl
    /// Explicit point dimension.
    case custom(Double)

    public var points: Double {
        switch self {
        case .xs: return 12
        case .sm: return 16
        case .md: return 20
        case .lg: return 24
        case .xl: return 32
        case .custom(let val): return max(0, val)
        }
    }
}

/// Symbol stroke weight (primarily applied to SF Symbols).
public enum IconWeight: String, Hashable, Sendable, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
}

/// Rendering colorization mode for vector icons.
public enum IconRenderingMode: String, Hashable, Sendable, CaseIterable {
    /// Re-tints the icon with the specified foreground/tint color.
    case monochrome
    /// Preserves original vector shape colors declared in the asset.
    case multicolor
    /// Renders symbol tiers with hierarchical opacity levels.
    case hierarchical
}

// MARK: - Modifiers

extension RenderElement {
    /// Specifies the icon's dimensions using semantic tokens or custom points.
    public func iconSize(_ size: IconSize) -> RenderElement {
        var copy = self
        copy.props.custom["iconSize"] = String(size.points)
        return copy
    }

    /// Specifies the icon's dimensions in points.
    public func iconSize(_ points: Double) -> RenderElement {
        iconSize(.custom(points))
    }

    /// Configures the icon's tint color.
    public func iconColor(_ color: Color) -> RenderElement {
        var copy = self
        copy.props.custom["iconColor"] = color.hexString
        return copy
    }

    /// Configures the stroke weight for SF Symbols.
    public func iconWeight(_ weight: IconWeight) -> RenderElement {
        var copy = self
        copy.props.custom["iconWeight"] = weight.rawValue
        return copy
    }

    /// Configures the vector rendering mode (monochrome vs multicolor).
    public func renderingMode(_ mode: IconRenderingMode) -> RenderElement {
        var copy = self
        copy.props.custom["iconRenderingMode"] = mode.rawValue
        return copy
    }
}

extension Component {
    /// Specifies the icon's dimensions using semantic tokens or custom points.
    public func iconSize(_ size: IconSize) -> RenderElement {
        render().iconSize(size)
    }

    /// Specifies the icon's dimensions in points.
    public func iconSize(_ points: Double) -> RenderElement {
        render().iconSize(points)
    }

    /// Configures the icon's tint color.
    public func iconColor(_ color: Color) -> RenderElement {
        render().iconColor(color)
    }

    /// Configures the stroke weight for SF Symbols.
    public func iconWeight(_ weight: IconWeight) -> RenderElement {
        render().iconWeight(weight)
    }

    /// Configures the vector rendering mode (monochrome vs multicolor).
    public func renderingMode(_ mode: IconRenderingMode) -> RenderElement {
        render().renderingMode(mode)
    }
}
