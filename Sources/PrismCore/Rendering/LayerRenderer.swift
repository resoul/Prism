import Foundation
import QuartzCore

/// Protocol for objects that own and manage a CALayer hierarchy corresponding to a VRT node.
///
/// Invariant: All mutations to CALayer MUST occur strictly on `@MainActor`.
@MainActor
public protocol LayerRenderer: AnyObject {
    var elementID: ElementID { get }
    var rootLayer: CALayer { get }
    func update(element: RenderElement, frame: LayoutFrame, context: RenderContext)
    func destroy()
}
