import Foundation
import CoreGraphics
import PrismCore

/// Composite component pairing an icon and a text label with standard typographic alignment and accessibility.
public struct Label: Component {
    public let text: String
    public let iconSource: IconSource
    public let spacing: Double
    public let iconSize: Double

    public init(
        _ text: String,
        icon: IconSource,
        spacing: Double = 6.0,
        iconSize: Double = 16.0
    ) {
        self.text = text
        self.iconSource = icon
        self.spacing = spacing
        self.iconSize = iconSize
    }

    public init(
        _ text: String,
        systemImage: String,
        spacing: Double = 6.0,
        iconSize: Double = 16.0
    ) {
        self.init(text, icon: .sf(name: systemImage), spacing: spacing, iconSize: iconSize)
    }

    public func body(context: ComponentContext) -> RenderElement {
        let iconElement = RenderElement(
            id: ElementID(typeName: "Icon", key: "icon"),
            kind: .icon(source: iconSource),
            modifiers: [
                .width(iconSize),
                .height(iconSize)
            ]
        )

        let textElement = RenderElement(
            id: ElementID(typeName: "Text", key: "text"),
            kind: .text(text)
        )

        let labelID = ElementID(typeName: "Label")
        return RenderElement(
            id: labelID,
            kind: .stack(axis: .horizontal, alignment: .center, spacing: spacing),
            props: ElementProps(accessibilityLabel: text),
            children: [iconElement, textElement]
        )
    }
}
