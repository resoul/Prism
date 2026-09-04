import Foundation
import CoreGraphics
import PrismCore

/// Radio group container managing single-choice selection among items.
public struct RadioGroup: Component {
    public let children: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.children = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 8) {
            Group {
                children
            }
        }
        .render()
    }
}

/// An individual radio selection option within a RadioGroup.
public struct RadioItem<Value: Hashable & Sendable>: Component {
    public let value: Value
    public let selected: Binding<Value>
    public let label: String
    public var isDisabled: Bool = false

    public init(
        value: Value,
        selected: Binding<Value>,
        label: String,
        isDisabled: Bool = false
    ) {
        self.value = value
        self.selected = selected
        self.label = label
        self.isDisabled = isDisabled
    }

    public func disabled(_ disabled: Bool = true) -> RadioItem {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let isSelected = (selected.wrappedValue == value)

        var props = ElementProps()
        props.custom["isSelected"] = isSelected ? "true" : "false"
        props.custom["isDisabled"] = isDisabled ? "true" : "false"
        props.custom["label"] = label

        var element = HStack(spacing: 8) {
            Circle()
                .frame(width: 18, height: 18)
                .background(isSelected ? Color.hex("#2563EB") : Color.white)

            Text(label)
        }
        .opacity(isDisabled ? 0.5 : 1.0)

        element.props.custom.merge(props.custom) { _, new in new }
        return element
    }
}
