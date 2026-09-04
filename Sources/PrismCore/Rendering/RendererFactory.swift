import Foundation
import QuartzCore

/// Factory for instantiating the appropriate `LayerRenderer` for a given `RenderElement`.
@MainActor
public enum RendererFactory {
    /// Creates and returns a concrete `LayerRenderer` implementation matching the element's kind.
    public static func create(for element: RenderElement) -> LayerRenderer {
        switch element.kind {
        case .text:
            return TextRenderer(elementID: element.id)
        case .shape:
            return ShapeRenderer(elementID: element.id)
        case .icon:
            return IconRenderer(elementID: element.id)
        case .textEditor:
            return TextEditorRenderer(elementID: element.id)
        case .scrollArea:
            return ScrollAreaRenderer(elementID: element.id)
        case .image:
            return ImageRenderer(elementID: element.id)
        case .stack, .spacer, .custom, .group, .empty, .portal:
            return ContainerRenderer(elementID: element.id)
        }
    }
}
