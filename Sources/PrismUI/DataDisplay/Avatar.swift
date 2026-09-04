import Foundation
import CoreGraphics
import PrismCore

/// Size tier for an Avatar.
public enum AvatarSize: Sendable, Equatable {
    case sm
    case md
    case lg
    case custom(Double)

    public var dimension: Double {
        switch self {
        case .sm: return 28.0
        case .md: return 40.0
        case .lg: return 56.0
        case .custom(let d): return d
        }
    }

    public var fontSize: Double {
        dimension * 0.4
    }
}

/// Visual avatar element displaying user/entity profile photos with automatic fallback to text initials.
public struct Avatar: Component {
    public let source: ImageSource?
    public let initials: String?
    public let size: AvatarSize

    public init(
        source: ImageSource? = nil,
        initials: String? = nil,
        size: AvatarSize = .md
    ) {
        self.source = source
        self.initials = initials
        self.size = size
    }

    public init(
        url: URL?,
        initials: String? = nil,
        size: AvatarSize = .md
    ) {
        self.source = url.map { .url($0) }
        self.initials = initials
        self.size = size
    }

    public func body(context: ComponentContext) -> RenderElement {
        let dim = size.dimension
        let avatarID = ElementID(typeName: "Avatar")

        if let source {
            // Render remote/bundled image with circular clipping
            let imageElement = RenderElement(
                id: ElementID(typeName: "Image", key: "photo"),
                kind: .image(source: source),
                modifiers: [
                    .width(dim),
                    .height(dim)
                ]
            )

            return RenderElement(
                id: avatarID,
                kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
                modifiers: [
                    .width(dim),
                    .height(dim)
                ],
                children: [imageElement]
            )
        } else {
            // Fallback initials container
            let text = initials ?? "?"
            let initialsText = RenderElement(
                id: ElementID(typeName: "Text", key: "initials"),
                kind: .text(text),
                props: ElementProps(accessibilityLabel: text)
            )

            let surface = context.theme?.colors.muted ?? Color.hex("#E2E8F0")
            let backgroundShape = RenderElement(
                id: ElementID(typeName: "Circle", key: "background"),
                kind: .shape(.circle),
                modifiers: [
                    .width(dim),
                    .height(dim),
                    .background(surface)
                ]
            )

            return RenderElement(
                id: avatarID,
                kind: .stack(axis: .vertical, alignment: .center, spacing: 0),
                modifiers: [
                    .width(dim),
                    .height(dim)
                ],
                children: [backgroundShape, initialsText]
            )
        }
    }
}
