import XCTest
import CoreGraphics
@testable import PrismCore

final class ImagePipelineTests: XCTestCase {

    func testImageMemoryCacheInsertionAndEviction() {
        let cache = ImageMemoryCache(costLimit: 1_000) // Small byte limit

        let img1 = createTestCGImage(width: 10, height: 10) // 10*10*4 = 400 bytes
        let key1 = ImageCacheKey(source: .named("img1"), targetSize: CGSize(width: 10, height: 10), scaleFactor: 1.0)
        cache.store(img1, for: key1)

        XCTAssertNotNil(cache.image(for: key1))
        XCTAssertEqual(cache.totalCost, 400)

        let img2 = createTestCGImage(width: 10, height: 10) // 400 bytes
        let key2 = ImageCacheKey(source: .named("img2"), targetSize: CGSize(width: 10, height: 10), scaleFactor: 1.0)
        cache.store(img2, for: key2)
        XCTAssertEqual(cache.totalCost, 800)

        // Storing a third 400-byte image pushes total to 1200 > 1000 limit, evicting img1 (LRU)
        let img3 = createTestCGImage(width: 10, height: 10)
        let key3 = ImageCacheKey(source: .named("img3"), targetSize: CGSize(width: 10, height: 10), scaleFactor: 1.0)
        cache.store(img3, for: key3)

        XCTAssertNil(cache.image(for: key1), "Oldest entry should be evicted under memory pressure")
        XCTAssertNotNil(cache.image(for: key2))
        XCTAssertNotNil(cache.image(for: key3))
    }

    func testImageLoaderWithDirectCGImage() async throws {
        let testImage = createTestCGImage(width: 50, height: 50)
        let loader = ImageLoader(cache: ImageMemoryCache())

        let loaded = try await loader.loadImage(
            source: .cgImage(testImage),
            targetSize: CGSize(width: 50, height: 50),
            scaleFactor: 1.0
        )

        XCTAssertEqual(loaded.width, 50)
        XCTAssertEqual(loaded.height, 50)
    }

    // MARK: - Helper

    private func createTestCGImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
}
