import Foundation
import CoreGraphics
import PrismCore

/// Declarative image primitive displaying remote, bundled, or in-memory bitmap graphics
/// with off-main-thread decoding and retina downsampling.
public struct Image: Component {
    private let source: ImageSource
    private var contentMode: ImageContentMode = .fit
    private var cornerRadius: Double = 0.0
    private var isFadeEnabled: Bool = true
    private var placeholderBuilder: (@Sendable () -> RenderElement)?

    public init(_ source: ImageSource) {
        self.source = source
    }

    public init(url: URL) {
        self.source = .url(url)
    }

    public init(named: String, bundle: Bundle? = nil) {
        self.source = .named(named, bundle: bundle)
    }

    public init(cgImage: CGImage) {
        self.source = .cgImage(cgImage)
    }

    /// Sets the scaling mode when mapping the image into its display frame.
    public func contentMode(_ mode: ImageContentMode) -> Image {
        var copy = self
        copy.contentMode = mode
        return copy
    }

    /// Sets rounded corner radius for the image layer.
    public func cornerRadius(_ radius: Double) -> Image {
        var copy = self
        copy.cornerRadius = radius
        return copy
    }

    /// Attaches an optional placeholder view to display while the image is loading.
    public func placeholder(@ComponentBuilder _ builder: @escaping @Sendable () -> [RenderElement]) -> Image {
        var copy = self
        copy.placeholderBuilder = {
            let elements = builder()
            return elements.first ?? RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
        }
        return copy
    }

    /// Configures whether a smooth cross-fade animation is played when the image finishes loading.
    public func fade(_ enabled: Bool = true) -> Image {
        var copy = self
        copy.isFadeEnabled = enabled
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        var props = ElementProps()
        props.custom["contentMode"] = contentMode.rawValue
        props.custom["cornerRadius"] = String(cornerRadius)
        props.custom["isFadeEnabled"] = isFadeEnabled ? "true" : "false"

        var children: [RenderElement] = []
        if let placeholder = placeholderBuilder?() {
            children.append(placeholder)
        }

        return RenderElement(
            id: ElementID(typeName: "Image"),
            kind: .image(source: source),
            props: props,
            modifiers: [],
            children: children
        )
    }
}
