import Foundation
import PrismCore

/// Semantic icon primitive (temporary placeholder awaiting Task 10 SVG subsystem).
public struct Icon: Component {
    public let name: String
    public let bundle: String?

    public init(_ name: String, bundle: String? = nil) {
        self.name = name
        self.bundle = bundle
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "Icon"),
            kind: .icon(name: name, bundle: bundle)
        )
    }
}
