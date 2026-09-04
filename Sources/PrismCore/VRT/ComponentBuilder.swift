import Foundation

/// Result builder constructing arrays of `RenderElement`s.
@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock() -> [RenderElement] {
        []
    }

    public static func buildBlock(_ components: ComponentConvertible...) -> [RenderElement] {
        components.flatMap { $0.asRenderElements(in: .default) }
    }

    public static func buildOptional(_ component: [RenderElement]?) -> [RenderElement] {
        component ?? []
    }

    public static func buildEither(first component: [RenderElement]) -> [RenderElement] {
        component
    }

    public static func buildEither(second component: [RenderElement]) -> [RenderElement] {
        component
    }

    public static func buildArray(_ components: [[RenderElement]]) -> [RenderElement] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: ComponentConvertible) -> [RenderElement] {
        expression.asRenderElements(in: .default)
    }

    public static func buildExpression(_ expression: [RenderElement]) -> [RenderElement] {
        expression
    }

    public static func buildExpression(_ expression: RenderElement) -> [RenderElement] {
        [expression]
    }
}
