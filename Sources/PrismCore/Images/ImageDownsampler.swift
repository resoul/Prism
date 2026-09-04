import Foundation
import CoreGraphics
import ImageIO

/// Utility for decoding and downsampling full-resolution images off the main thread
/// to match the target display frame and retina scale factor, conserving GPU/RAM resources.
public enum ImageDownsampler: Sendable {

    /// Decodes and downsamples image data to the specified target dimensions.
    ///
    /// - Parameters:
    ///   - data: Encoded image data (JPEG, PNG, WebP, etc.).
    ///   - targetSize: Desired display size in points.
    ///   - scaleFactor: Display scale multiplier (e.g. 2.0 or 3.0 for Retina).
    /// - Returns: A decoded, downsampled `CGImage`, or `nil` if decoding fails.
    public static func downsample(
        data: Data,
        to targetSize: CGSize,
        scaleFactor: Double = 2.0
    ) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        return downsample(imageSource: imageSource, to: targetSize, scaleFactor: scaleFactor)
    }

    /// Decodes and downsamples from a local or accessible file URL.
    public static func downsample(
        fileURL: URL,
        to targetSize: CGSize,
        scaleFactor: Double = 2.0
    ) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, imageSourceOptions) else {
            return nil
        }

        return downsample(imageSource: imageSource, to: targetSize, scaleFactor: scaleFactor)
    }

    private static func downsample(
        imageSource: CGImageSource,
        to targetSize: CGSize,
        scaleFactor: Double
    ) -> CGImage? {
        let maxDimension = max(targetSize.width, targetSize.height) * CGFloat(scaleFactor)
        let maxPixelSize = max(1.0, maxDimension)

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
    }
}
