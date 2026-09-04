import Foundation
import CoreGraphics
import PrismCore

/// Single-line interactive text input component.
public struct Input: Component {
    public let binding: Binding<String>
    public var placeholder: String = ""
    public var mode: TextInputMode = .text
    public var isDisabled: Bool = false
    public var isReadOnly: Bool = false
    public var leadingIcon: IconSource? = nil
    public var trailingIcon: IconSource? = nil

    public init(
        _ placeholder: String = "",
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.binding = text
    }

    public init(text: Binding<String>) {
        self.placeholder = ""
        self.binding = text
    }

    // MARK: - Modifiers

    public func placeholder(_ text: String) -> Input {
        var copy = self
        copy.placeholder = text
        return copy
    }

    public func mode(_ inputMode: TextInputMode) -> Input {
        var copy = self
        copy.mode = inputMode
        return copy
    }

    public func disabled(_ disabled: Bool = true) -> Input {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func readOnly(_ readOnly: Bool = true) -> Input {
        var copy = self
        copy.isReadOnly = readOnly
        return copy
    }

    public func leadingIcon(_ icon: IconSource) -> Input {
        var copy = self
        copy.leadingIcon = icon
        return copy
    }

    public func trailingIcon(_ icon: IconSource) -> Input {
        var copy = self
        copy.trailingIcon = icon
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let textValue = binding.wrappedValue

        var props = ElementProps()
        props.custom["text"] = textValue
        props.custom["placeholder"] = placeholder
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        props.custom["isReadOnly"] = isReadOnly ? "true" : "false"
        props.custom["mode"] = mode.rawValue

        let elementID = ElementID(typeName: "Input")

        return RenderElement(
            id: elementID,
            kind: .textEditor(mode: mode, multiline: false),
            props: props,
            children: []
        )
        .height(36.0)
        .background(Color.white)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
