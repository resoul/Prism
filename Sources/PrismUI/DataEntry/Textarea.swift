import Foundation
import CoreGraphics
import PrismCore

/// Multi-line interactive text editing component.
public struct Textarea: Component {
    public let binding: Binding<String>
    public var placeholder: String = ""
    public var minLines: Int = 3
    public var maxLines: Int? = nil
    public var isDisabled: Bool = false
    public var isReadOnly: Bool = false

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        minLines: Int = 3
    ) {
        self.placeholder = placeholder
        self.binding = text
        self.minLines = minLines
    }

    public init(text: Binding<String>, minLines: Int = 3) {
        self.placeholder = ""
        self.binding = text
        self.minLines = minLines
    }

    // MARK: - Modifiers

    public func placeholder(_ text: String) -> Textarea {
        var copy = self
        copy.placeholder = text
        return copy
    }

    public func minLines(_ lines: Int) -> Textarea {
        var copy = self
        copy.minLines = max(1, lines)
        return copy
    }

    public func maxLines(_ lines: Int?) -> Textarea {
        var copy = self
        copy.maxLines = lines
        return copy
    }

    public func disabled(_ disabled: Bool = true) -> Textarea {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func readOnly(_ readOnly: Bool = true) -> Textarea {
        var copy = self
        copy.isReadOnly = readOnly
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let textValue = binding.wrappedValue

        var props = ElementProps()
        props.custom["text"] = textValue
        props.custom["placeholder"] = placeholder
        props.custom["minLines"] = String(minLines)
        if let max = maxLines {
            props.custom["maxLines"] = String(max)
        }
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        props.custom["isReadOnly"] = isReadOnly ? "true" : "false"

        let calculatedHeight = Double(minLines) * 20.0 + 20.0

        return RenderElement(
            id: ElementID(typeName: "Textarea"),
            kind: .textEditor(mode: .text, multiline: true),
            props: props,
            children: []
        )
        .height(calculatedHeight)
        .background(Color.white)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
