import Foundation
@_exported import PrismCore

/// Content fitting modes for aspect ratio containers.
public enum AspectRatioContentMode: String, Sendable, Equatable {
    case fit
    case fill
}

/// A container layout component that constrains its dimensions to a fixed width-to-height ratio ($w / h$).
public struct AspectRatio: Component {
    public let ratio: Double
    public let contentMode: AspectRatioContentMode
    public let content: [RenderElement]

    public init(
        _ ratio: Double,
        contentMode: AspectRatioContentMode = .fit,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.ratio = max(0.001, ratio)
        self.contentMode = contentMode
        self.content = content()
    }

    /// Calculates resolved width and height satisfying the ratio given available constraints.
    public func resolveSize(availableWidth: Double?, availableHeight: Double?) -> (width: Double, height: Double) {
        switch (availableWidth, availableHeight) {
        case (let w?, nil):
            return (width: w, height: w / ratio)
        case (nil, let h?):
            return (width: h * ratio, height: h)
        case (let w?, let h?):
            switch contentMode {
            case .fit:
                if w / ratio <= h {
                    return (width: w, height: w / ratio)
                } else {
                    return (width: h * ratio, height: h)
                }
            case .fill:
                if w / ratio >= h {
                    return (width: w, height: w / ratio)
                } else {
                    return (width: h * ratio, height: h)
                }
            }
        case (nil, nil):
            return (width: 100 * ratio, height: 100)
        }
    }

    public func body(context: ComponentContext) -> RenderElement {
        var props = ElementProps()
        props.custom["aspectRatio"] = String(ratio)
        props.custom["contentMode"] = contentMode.rawValue

        return RenderElement(
            id: ElementID(typeName: "AspectRatio"),
            kind: .custom("AspectRatio"),
            props: props,
            modifiers: [],
            children: content
        )
    }
}

public extension Component {
    /// Wraps the component in an `AspectRatio` container.
    func aspectRatio(_ ratio: Double, contentMode: AspectRatioContentMode = .fit) -> some Component {
        AspectRatio(ratio, contentMode: contentMode) {
            render()
        }
    }
}
