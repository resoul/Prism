import Foundation
import CoreGraphics
import PrismCore

/// Cross-platform semantic icon primitive supporting SF Symbols, custom SVGs, pre-compiled vector paths, and raster assets.
public struct Icon: Component {
    public let source: IconSource

    public init(_ source: IconSource) {
        self.source = source
    }

    /// Convenience initializer defaulting to SF Symbol or registered/bundled asset.
    public init(_ name: String, bundle: String? = nil) {
        if let bundle {
            self.source = .svg(named: name, bundle: bundle)
        } else {
            self.source = .sf(name: name)
        }
    }

    // MARK: - Semantic Static Factories

    public static func sf(_ name: String) -> Icon {
        Icon(.sf(name: name))
    }

    public static func svg(_ name: String, bundle: String? = nil) -> Icon {
        Icon(.svg(named: name, bundle: bundle))
    }

    public static func svgURL(_ url: URL) -> Icon {
        Icon(.svgURL(url))
    }

    public static func path(_ path: CGPath, viewBox: CGRect) -> Icon {
        Icon(.path(path, viewBox: viewBox))
    }

    public static func raster(_ name: String, bundle: String? = nil) -> Icon {
        Icon(.raster(named: name, bundle: bundle))
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Icon"),
            kind: .icon(source: source)
        )
    }
}
