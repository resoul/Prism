import Foundation
import CoreGraphics
import PrismCore

/// Title typography primitive for Cards.
public struct CardTitle: Component {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "CardTitle"),
            kind: .text(text)
        )
    }
}

/// Descriptive text primitive for Cards.
public struct CardDescription: Component {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "CardDescription"),
            kind: .text(text),
            modifiers: [.opacity(0.7)]
        )
    }
}

/// Header section within a Card hosting title and description.
public struct CardHeader: Component {
    private let content: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "CardHeader"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 4.0),
            modifiers: [.padding(.init(top: 16, leading: 16, bottom: 8, trailing: 16))],
            children: content
        )
    }
}

/// Main body section within a Card.
public struct CardContent: Component {
    private let content: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "CardContent"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 8.0),
            modifiers: [.padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16))],
            children: content
        )
    }
}

/// Action and button footer section within a Card.
public struct CardFooter: Component {
    private let content: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "CardFooter"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8.0),
            modifiers: [.padding(.init(top: 8, leading: 16, bottom: 16, trailing: 16))],
            children: content
        )
    }
}

/// Structured container component presenting grouped content with a surface card background and border.
public struct Card: Component {
    private let content: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.content = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        let cardID = ElementID(typeName: "Card")
        let surfaceColor = context.theme?.colors.background ?? Color.hex("#FFFFFF")
        return RenderElement(
            id: cardID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            modifiers: [
                .background(surfaceColor),
                .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            ],
            children: content
        )
    }
}
