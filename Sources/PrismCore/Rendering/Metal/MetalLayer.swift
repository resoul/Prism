import Foundation
import Metal
import QuartzCore
import PrismLogging

/// Encapsulates a `CAMetalLayer` lifecycle, Retina scale factor, color space, resize policy,
/// and teardown cleanup for compositing with CALayer trees.
@MainActor
public final class MetalLayer {
    public let metalLayer: CAMetalLayer
    private weak var deviceContext: MetalDeviceContext?
    private var isPurged = false

    public init(context: MetalDeviceContext = .shared) {
        self.deviceContext = context
        self.metalLayer = CAMetalLayer()
        if let device = context.device {
            self.metalLayer.device = device
        }
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.isOpaque = false
        self.metalLayer.contentsGravity = .resizeAspectFill

        // Default to sRGB color space
        if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
            self.metalLayer.colorspace = colorSpace
        }
    }

    /// Updates the layer frame, scaling factor, and drawable dimensions.
    public func updateFrame(_ frame: CGRect, contentsScale: CGFloat) {
        guard !isPurged else { return }
        metalLayer.frame = frame
        metalLayer.contentsScale = contentsScale

        let pixelWidth = max(1, Int(ceil(frame.width * contentsScale)))
        let pixelHeight = max(1, Int(ceil(frame.height * contentsScale)))
        let newDrawableSize = CGSize(width: pixelWidth, height: pixelHeight)

        if metalLayer.drawableSize != newDrawableSize {
            metalLayer.drawableSize = newDrawableSize
        }
    }

    /// Obtains the next drawable for rendering, or nil if purged or unavailable.
    public func nextDrawable() -> CAMetalDrawable? {
        guard !isPurged, metalLayer.device != nil else { return nil }
        guard metalLayer.drawableSize.width > 0 && metalLayer.drawableSize.height > 0 else { return nil }
        return metalLayer.nextDrawable()
    }

    /// Releases GPU drawables, decouples sublayers, and cleans up buffers upon unmount or backgrounding.
    public func purgeResources() {
        guard !isPurged else { return }
        isPurged = true
        metalLayer.removeFromSuperlayer()
        metalLayer.contents = nil
        PrismLogging.render.debug("MetalLayer resources purged on unmount.")
    }
}
