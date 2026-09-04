import Foundation
import CoreGraphics
import PrismCore

/// Rounded square tile featuring a central icon with accent styling and optional notification badge.
public struct IconTile: Component {
    public let iconSource: IconSource
    public let size: Double
    public let iconSize: Double
    public let badgeCount: Int?

    public init(
        icon: IconSource,
        size: Double = 48.0,
        iconSize: Double = 24.0,
        badgeCount: Int? = nil
    ) {
        self.iconSource = icon
        self.size = size
        self.iconSize = iconSize
        self.badgeCount = badgeCount
    }

    public init(
        systemImage: String,
        size: Double = 48.0,
        iconSize: Double = 24.0,
        badgeCount: Int? = nil
    ) {
        self.init(icon: .sf(name: systemImage), size: size, iconSize: iconSize, badgeCount: badgeCount)
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

        var children: [RenderElement] = [iconElement]

        if let badgeCount, badgeCount > 0 {
            let badge = Badge("\(badgeCount)", variant: .destructive, size: .sm)
            children.append(badge.body(context: context))
        }

        let tileID = ElementID(typeName: "IconTile")
        let surfaceColor = context.theme?.colors.secondary ?? Color.hex("#F1F5F9")
        return RenderElement(
            id: tileID,
            kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
            modifiers: [
                .width(size),
                .height(size),
                .background(surfaceColor)
            ],
            children: children
        )
    }
}
