import Foundation
import CoreGraphics
import PrismCore

/// Two-state interactive toggle button.
public struct Toggle: Component {
    public let isOn: Binding<Bool>
    public let title: String
    public var isDisabled: Bool = false

    public init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self.isOn = isOn
    }

    public func disabled(_ disabled: Bool = true) -> Toggle {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let active = isOn.wrappedValue

        var props = ElementProps()
        props.custom["isOn"] = active ? "true" : "false"
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        props.custom["title"] = title

        let bg = active ? Color.hex("#2563EB") : Color.hex("#F1F5F9")
        let fg = active ? Color.white : Color.hex("#0F172A")

        var element = HStack(spacing: 6) {
            Text(title)
                .foregroundColor(fg)
        }
        .height(32)
        .padding(DirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .background(bg)
        .opacity(isDisabled ? 0.5 : 1.0)

        element.props.custom.merge(props.custom) { _, new in new }
        return element
    }
}
