import Foundation
import CoreGraphics
import PrismCore

/// Modal dialog window presented above application content with a focus trap and dimmed backdrop.
public struct Dialog: Component {
    public let isPresented: Bool
    public let title: String
    public let onDismiss: @Sendable () -> Void
    public let content: [RenderElement]
    public let actions: [RenderElement]

    public init(
        isPresented: Bool,
        title: String,
        onDismiss: @escaping @Sendable () -> Void,
        @ComponentBuilder content: () -> [RenderElement],
        @ComponentBuilder actions: () -> [RenderElement] = { [] }
    ) {
        self.isPresented = isPresented
        self.title = title
        self.onDismiss = onDismiss
        self.content = content()
        self.actions = actions()
    }

    public init(
        isPresented: Binding<Bool>,
        title: String,
        @ComponentBuilder content: () -> [RenderElement],
        @ComponentBuilder actions: () -> [RenderElement] = { [] }
    ) {
        self.init(
            isPresented: isPresented.wrappedValue,
            title: title,
            onDismiss: { isPresented.wrappedValue = false },
            content: content,
            actions: actions
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        guard isPresented else {
            return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
        }

        // 1. Dimmed Backdrop Scrim
        let backdropID = ElementID(typeName: "Backdrop")
        var backdrop = RenderElement(
            id: backdropID,
            kind: .shape(.rectangle(cornerRadius: 0)),
            modifiers: [
                .background(Color(red: 0, green: 0, blue: 0, alpha: 0.5)),
                .testID("dialog_backdrop")
            ]
        )
        backdrop.props.custom["role"] = "presentation"

        // 2. Dialog Window
        let titleElement = RenderElement(
            id: ElementID(typeName: "Text", key: "dialog_title"),
            kind: .text(title)
        )

        let contentStack = RenderElement(
            id: ElementID(typeName: "Stack", key: "dialog_body"),
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 8.0),
            children: content
        )

        let actionsStack = RenderElement(
            id: ElementID(typeName: "Stack", key: "dialog_actions"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8.0),
            children: actions
        )

        let dialogCardID = ElementID(typeName: "DialogCard")
        var dialogProps = ElementProps(accessibilityLabel: title)
        dialogProps.custom["role"] = "dialog"
        dialogProps.custom["modal"] = "true"

        let surfaceColor = context.theme?.colors.background ?? Color.hex("#FFFFFF")
        let dialogCard = RenderElement(
            id: dialogCardID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 16.0),
            props: dialogProps,
            modifiers: [
                .padding(.init(top: 24, leading: 24, bottom: 20, trailing: 24)),
                .background(surfaceColor),
                .testID("dialog_window")
            ],
            children: [titleElement, contentStack, actionsStack]
        )

        // 3. Modal Overlay Portal
        let modalContainerID = ElementID(typeName: "DialogContainer")
        let modalContainer = RenderElement(
            id: modalContainerID,
            kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
            children: [backdrop, dialogCard]
        )

        return modalContainer.portal(layer: .modal)
    }
}
