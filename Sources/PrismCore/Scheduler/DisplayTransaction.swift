import Foundation
import CoreGraphics

/// Immutable, Sendable display payload containing precomputed layout or visual assets
/// prepared on background threads for atomic, zero-overhead CALayer synchronization on MainActor.
public struct DisplayTransaction: Sendable {
    /// Identifier of the target element.
    public let elementID: ElementID

    /// Optional pre-decoded and downsampled image bitmap.
    public let image: CGImage?

    /// Optional pre-measured dimension size.
    public let measuredSize: CGSize?

    /// Arbitrary metadata payload computed off-main-thread.
    public let customPayload: [String: String]

    public init(
        elementID: ElementID,
        image: CGImage? = nil,
        measuredSize: CGSize? = nil,
        customPayload: [String: String] = [:]
    ) {
        self.elementID = elementID
        self.image = image
        self.measuredSize = measuredSize
        self.customPayload = customPayload
    }
}
