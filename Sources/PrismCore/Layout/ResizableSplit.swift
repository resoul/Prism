import Foundation

public enum SplitDirection: String, Sendable { case horizontal, vertical }

/// Pure split-panel state with bounded ratio and reversible pointer capture.
public struct ResizableSplit: Sendable, Equatable {
    public let direction: SplitDirection; public let minimumRatio: Double; public let maximumRatio: Double
    public private(set) var ratio: Double; public private(set) var isCapturing: Bool
    private var captureOrigin: Double?
    public init(direction: SplitDirection = .horizontal, ratio: Double = 0.5, minimumRatio: Double = 0.1, maximumRatio: Double = 0.9) {
        self.direction = direction; self.minimumRatio = min(minimumRatio, maximumRatio); self.maximumRatio = max(minimumRatio, maximumRatio)
        self.ratio = min(max(ratio, self.minimumRatio), self.maximumRatio); self.isCapturing = false
    }
    public mutating func setRatio(_ proposed: Double) { guard proposed.isFinite else { return }; ratio = min(max(proposed, minimumRatio), maximumRatio) }
    public mutating func beginCapture() { captureOrigin = ratio; isCapturing = true }
    public mutating func updateCapture(delta: Double, availableExtent: Double) { guard isCapturing, availableExtent > 0 else { return }; setRatio((captureOrigin ?? ratio) + delta / availableExtent) }
    public mutating func endCapture() { captureOrigin = nil; isCapturing = false }
    public mutating func cancelCapture() { if let captureOrigin { ratio = captureOrigin }; endCapture() }
    public mutating func keyboardResize(steps: Int, rtl: Bool = false, step: Double = 0.02) { setRatio(ratio + Double(steps) * step * (rtl ? -1 : 1)) }
}
