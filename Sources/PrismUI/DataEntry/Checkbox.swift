import Foundation
import CoreGraphics
import PrismCore

/// Accessible checkbox toggle with optional label and animated checkmark.
public struct Checkbox: Component {
    public let isOn: Binding<Bool>
    public var label: String? = nil
    public var isDisabled: Bool = false

    public init(isOn: Binding<Bool>, label: String? = nil) {
        self.isOn = isOn
        self.label = label
    }

    public init(_ label: String, isOn: Binding<Bool>) {
        self.isOn = isOn
        self.label = label
    }

    public func disabled(_ disabled: Bool = true) -> Checkbox {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let checked = isOn.wrappedValue

        var props = ElementProps()
        props.custom["isChecked"] = checked ? "true" : "false"
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        if let label {
            props.custom["label"] = label
        }

        var element = HStack(spacing: 8) {
            Rectangle(cornerRadius: 4)
                .frame(width: 18, height: 18)
                .background(checked ? Color.hex("#2563EB") : Color.white)

            if let label {
                Text(label)
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)

        element.props.custom.merge(props.custom) { _, new in new }
        return element
    }
}
