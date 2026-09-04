import Foundation
import CoreGraphics
import PrismCore

/// Sliding toggle switch control.
public struct Switch: Component {
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

    public func disabled(_ disabled: Bool = true) -> Switch {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let active = isOn.wrappedValue

        var props = ElementProps()
        props.custom["isOn"] = active ? "true" : "false"
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        if let label {
            props.custom["label"] = label
        }

        let trackColor = active ? Color.hex("#2563EB") : Color.hex("#CBD5E1")

        var element = HStack(spacing: 8) {
            Rectangle(cornerRadius: 12)
                .frame(width: 44, height: 24)
                .background(trackColor)

            if let label {
                Text(label)
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)

        element.props.custom.merge(props.custom) { _, new in new }
        return element
    }
}
