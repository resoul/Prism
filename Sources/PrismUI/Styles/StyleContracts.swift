import Foundation
import CoreGraphics
import PrismCore

// MARK: - Button Style Contract

public struct ButtonConfiguration: Sendable {
    public let label: RenderElement
    public let isPressed: Bool
    public let isEnabled: Bool
    public let isLoading: Bool

    public init(
        label: RenderElement,
        isPressed: Bool = false,
        isEnabled: Bool = true,
        isLoading: Bool = false
    ) {
        self.label = label
        self.isPressed = isPressed
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
}

public protocol ButtonStyle: Sendable {
    func makeBody(configuration: ButtonConfiguration, context: ComponentContext) -> RenderElement
}

public struct DefaultButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: ButtonConfiguration, context: ComponentContext) -> RenderElement {
        let primaryColor = context.theme?.colors.primary ?? Color.hex("#2563EB")
        var modifiers: [ElementModifier] = [
            .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16)),
            .background(primaryColor)
        ]

        if !configuration.isEnabled {
            modifiers.append(.opacity(0.5))
        } else if configuration.isPressed {
            modifiers.append(.opacity(0.8))
        }

        return RenderElement(
            id: ElementID(typeName: "StyledButton"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 6.0),
            modifiers: modifiers,
            children: [configuration.label]
        )
    }
}

// MARK: - Input Style Contract

public struct InputConfiguration: Sendable {
    public let placeholder: String?
    public let isFocused: Bool
    public let hasError: Bool
    public let isEnabled: Bool

    public init(
        placeholder: String? = nil,
        isFocused: Bool = false,
        hasError: Bool = false,
        isEnabled: Bool = true
    ) {
        self.placeholder = placeholder
        self.isFocused = isFocused
        self.hasError = hasError
        self.isEnabled = isEnabled
    }
}

public protocol InputStyle: Sendable {
    func makeBody(configuration: InputConfiguration, context: ComponentContext) -> RenderElement
}

public struct DefaultInputStyle: InputStyle {
    public init() {}

    public func makeBody(configuration: InputConfiguration, context: ComponentContext) -> RenderElement {
        let surfaceColor = context.theme?.colors.secondary ?? Color.hex("#F1F5F9")
        var modifiers: [ElementModifier] = [
            .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12)),
            .background(surfaceColor)
        ]

        if !configuration.isEnabled {
            modifiers.append(.opacity(0.5))
        }

        return RenderElement(
            id: ElementID(typeName: "StyledInput"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 0),
            modifiers: modifiers
        )
    }
}

// MARK: - Card Style Contract

public struct CardConfiguration: Sendable {
    public let content: [RenderElement]

    public init(content: [RenderElement]) {
        self.content = content
    }
}

public protocol CardStyle: Sendable {
    func makeBody(configuration: CardConfiguration, context: ComponentContext) -> RenderElement
}

public struct DefaultCardStyle: CardStyle {
    public init() {}

    public func makeBody(configuration: CardConfiguration, context: ComponentContext) -> RenderElement {
        let surfaceColor = context.theme?.colors.background ?? Color.hex("#FFFFFF")
        return RenderElement(
            id: ElementID(typeName: "StyledCard"),
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            modifiers: [
                .background(surfaceColor),
                .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            ],
            children: configuration.content
        )
    }
}
