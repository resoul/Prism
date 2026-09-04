import Foundation
import PrismCore

extension Component {
    /// Binds an animation to a specific state value change.
    public func animation<V: Equatable>(_ animation: Animation?, value: V) -> RenderElement {
        render().animation(animation)
    }
}

extension RenderElement {
    /// Binds an animation to a specific state value change on a RenderElement.
    public func animation<V: Equatable>(_ animation: Animation?, value: V) -> RenderElement {
        self.animation(animation)
    }
}
