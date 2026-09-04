import Foundation
import CoreGraphics
import PrismCore

/// Visual hairline separator dividing adjacent sections of content.
public struct Divider: Component {
    public let axis: LayoutAxis
    public let thickness: Double
    public let color: Color?

    public init(
        _ axis: LayoutAxis = .horizontal,
        thickness: Double = 1.0,
        color: Color? = nil
    ) {
        self.axis = axis
        self.thickness = thickness
        self.color = color
    }

    public func body(context: ComponentContext) -> RenderElement {
        let dividerID = ElementID(typeName: "Divider")
        let lineColor = color ?? (context.theme?.colors.border ?? Color.hex("#E2E8F0"))
        var modifiers: [ElementModifier] = [
            .background(lineColor)
        ]

        if axis == .horizontal {
            modifiers.append(.height(thickness))
        } else {
            modifiers.append(.width(thickness))
        }

        var props = ElementProps()
        props.custom["role"] = "separator"
        props.custom["orientation"] = axis == .horizontal ? "horizontal" : "vertical"

        return RenderElement(
            id: dividerID,
            kind: .shape(.rectangle(cornerRadius: 0)),
            props: props,
            modifiers: modifiers
        )
    }
}
