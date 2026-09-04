import Foundation
import PrismCore

/// Rectangular vector primitive with optional corner radius.
public struct Rectangle: Component {
    public let cornerRadius: Double
    public var fillColor: Color?

    public init(cornerRadius: Double = 0) {
        self.cornerRadius = cornerRadius
        self.fillColor = nil
    }

    public func fill(_ color: Color) -> Rectangle {
        var copy = self
        copy.fillColor = color
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        var modifiers: [ElementModifier] = []
        if let fillColor {
            modifiers.append(.background(fillColor))
        }

        return RenderElement(
            id: ElementID(typeName: "Rectangle"),
            kind: .shape(.rectangle(cornerRadius: cornerRadius)),
            modifiers: modifiers
        )
    }
}

/// Circular vector primitive.
public struct Circle: Component {
    public var fillColor: Color?

    public init() {
        self.fillColor = nil
    }

    public func fill(_ color: Color) -> Circle {
        var copy = self
        copy.fillColor = color
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        var modifiers: [ElementModifier] = []
        if let fillColor {
            modifiers.append(.background(fillColor))
        }

        return RenderElement(
            id: ElementID(typeName: "Circle"),
            kind: .shape(.circle),
            modifiers: modifiers
        )
    }
}
