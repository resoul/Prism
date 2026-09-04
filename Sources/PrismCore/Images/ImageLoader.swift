import Foundation
import CoreGraphics
import PrismLogging

/// Asynchronous image loader managing caching, in-flight request deduplication,
/// background downsampling, and cell-reuse cancellation.
public final class ImageLoader: @unchecked Sendable {
    public static let shared = ImageLoader()

    private let session: URLSession
    private let cache: ImageMemoryCache
    private let lock = NSLock()
    private var inFlightTasks: [ImageCacheKey: Task<CGImage, any Error>] = [:]

    private static let logCategory = LogCategory("ui.images")

    public init(
        session: URLSession = .shared,
        cache: ImageMemoryCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    /// Loads and downsamples an image for the given source and target display size.
    ///
    /// - Parameters:
    ///   - source: The image source (URL, Data, Asset name, or CGImage).
    ///   - targetSize: Desired display size in points.
    ///   - scaleFactor: Display scale multiplier (Retina @2x/@3x).
    /// - Returns: A decoded, downsampled `CGImage`.
    public func loadImage(
        source: ImageSource,
        targetSize: CGSize,
        scaleFactor: Double = 2.0
    ) async throws -> CGImage {
        let key = ImageCacheKey(source: source, targetSize: targetSize, scaleFactor: scaleFactor)

        // 1. Check memory cache hit
        if let cached = cache.image(for: key) {
            return cached
        }

        // 2. Coalesce concurrent in-flight requests for the same key
        let task: Task<CGImage, any Error> = lock.withLock {
            if let existing = inFlightTasks[key] {
                return existing
            }
            let newTask = Task { [weak self, key, source, targetSize, scaleFactor] in
                guard let self = self else { throw CancellationError() }
                let image = try await self.fetchAndDownsample(source: source, targetSize: targetSize, scaleFactor: scaleFactor)
                self.cache.store(image, for: key)
                return image
            }
            inFlightTasks[key] = newTask
            return newTask
        }

        defer {
            _ = lock.withLock {
                inFlightTasks.removeValue(forKey: key)
            }
        }

        return try await task.value
    }

    // MARK: - Private Loading Implementation

    private func fetchAndDownsample(
        source: ImageSource,
        targetSize: CGSize,
        scaleFactor: Double
    ) async throws -> CGImage {
        switch source {
        case .cgImage(let image):
            return image

        case .data(let data):
            guard let downsampled = ImageDownsampler.downsample(data: data, to: targetSize, scaleFactor: scaleFactor) else {
                throw LoadableError(code: .decoding, message: "Failed to decode image from raw data.")
            }
            return downsampled

        case .named(let name, let bundle):
            let effectiveBundle = bundle ?? Bundle.main
            guard let url = effectiveBundle.url(forResource: name, withExtension: nil) else {
                throw LoadableError(code: .notFound, message: "Named image asset '\(name)' not found in bundle.")
            }
            guard let downsampled = ImageDownsampler.downsample(fileURL: url, to: targetSize, scaleFactor: scaleFactor) else {
                throw LoadableError(code: .decoding, message: "Failed to decode named image asset '\(name)'.")
            }
            return downsampled

        case .url(let url):
            if url.isFileURL {
                guard let downsampled = ImageDownsampler.downsample(fileURL: url, to: targetSize, scaleFactor: scaleFactor) else {
                    throw LoadableError(code: .decoding, message: "Failed to decode image from local file URL.")
                }
                return downsampled
            }

            // Remote URL fetch
            let (data, response) = try await session.data(from: url)
            try Task.checkCancellation()

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw LoadableError(code: .serverError, message: "HTTP \(http.statusCode) downloading image.")
            }

            guard let downsampled = ImageDownsampler.downsample(data: data, to: targetSize, scaleFactor: scaleFactor) else {
                throw LoadableError(code: .decoding, message: "Failed to decode remote image data.")
            }
            return downsampled
        }
    }
}
