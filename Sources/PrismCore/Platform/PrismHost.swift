import Foundation
import CoreGraphics

/// Contract for native platform host views embedding a Prism Virtual Render Tree.
@MainActor
public protocol PrismHost: AnyObject {
    var bounds: CGRect { get }
    var scaleFactor: Double { get }
    var safeAreaDirectionalInsets: DirectionalEdgeInsets { get }
    var colorScheme: ColorScheme { get }
    var isInspectorOverlayEnabled: Bool { get set }

    func render()
    func teardown()
}
