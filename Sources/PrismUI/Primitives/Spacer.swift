import Foundation
import PrismCore

/// Flexible space element expanding along the major axis of its enclosing stack container.
public struct Spacer: Component {
    public let minLength: Double?

    public init(minLength: Double? = nil) {
        self.minLength = minLength
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Spacer"),
            kind: .spacer(minLength: minLength)
        )
    }
}
