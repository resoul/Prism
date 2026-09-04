import Foundation
import CoreGraphics
import PrismCore

/// Form field wrapper providing consistent layout for labels, required markers,
/// helper text captions, and validation error messages.
public struct Field: Component {
    public var label: String? = nil
    public var isRequired: Bool = false
    public var helperText: String? = nil
    public var error: String? = nil
    public let content: RenderElement

    public init(
        _ label: String? = nil,
        isRequired: Bool = false,
        helperText: String? = nil,
        error: String? = nil,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.label = label
        self.isRequired = isRequired
        self.helperText = helperText
        self.error = error
        let elements = content()
        self.content = elements.first ?? RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
    }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 4) {
            if let label {
                HStack(spacing: 2) {
                    Text(label)
                    if isRequired {
                        Text("*")
                    }
                }
            }

            content

            if let error, !error.isEmpty {
                Text(error)
            } else if let helperText, !helperText.isEmpty {
                Text(helperText)
            }
        }
        .render()
    }
}
