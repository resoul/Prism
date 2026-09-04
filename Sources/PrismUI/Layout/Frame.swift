import Foundation
import CoreGraphics
import PrismCore

/// Layout container applying explicit width, height, and boundary constraints to child content.
public struct Frame: Component {
    public let width: Double?
    public let height: Double?
    public let minWidth: Double?
    public let maxWidth: Double?
    public let minHeight: Double?
    public let maxHeight: Double?
    public let alignment: StackAlignment
    private let content: [RenderElement]

    public init(
        width: Double? = nil,
        height: Double? = nil,
        minWidth: Double? = nil,
        maxWidth: Double? = nil,
        minHeight: Double? = nil,
        maxHeight: Double? = nil,
        alignment: StackAlignment = .center,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        let frameID = ElementID(typeName: "Frame")
        var modifiers: [ElementModifier] = []

        if let width { modifiers.append(.width(width)) }
        if let height { modifiers.append(.height(height)) }
        if let minWidth { modifiers.append(.minWidth(minWidth)) }
        if let maxWidth { modifiers.append(.maxWidth(maxWidth)) }
        if let minHeight { modifiers.append(.minHeight(minHeight)) }
        if let maxHeight { modifiers.append(.maxHeight(maxHeight)) }

        return RenderElement(
            id: frameID,
            kind: .stack(axis: .vertical, alignment: alignment, spacing: 0),
            modifiers: modifiers,
            children: content
        )
    }
}
