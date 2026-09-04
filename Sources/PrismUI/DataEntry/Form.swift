import Foundation
import CoreGraphics
import PrismCore

/// Form container managing group submission, validation lifecycle, and focus traversal.
public struct Form: Component {
    public let children: [RenderElement]
    public var onSubmit: (@Sendable @MainActor () -> Void)? = nil

    public init(
        onSubmit: (@Sendable @MainActor () -> Void)? = nil,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.onSubmit = onSubmit
        self.children = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 16) {
            Group {
                children
            }
        }
        .focusScope(id: "formScope", trapsFocus: false)
    }
}
