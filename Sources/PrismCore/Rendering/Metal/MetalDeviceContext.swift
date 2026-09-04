import Foundation
import Metal
import QuartzCore
import PrismLogging

/// Thread-safe context managing the system `MTLDevice`, command queue, async pipeline compilation,
/// and GPU performance budgeting.
public final class MetalDeviceContext: @unchecked Sendable {
    public static let shared = MetalDeviceContext()

    private let lock = NSLock()
    private var _device: MTLDevice?
    private var _commandQueue: MTLCommandQueue?
    private var _isSimulatedUnsupported = false
    private var _pipelines: MetalPipelines?
    private var _isCompiling = false
    private var _compilationCallbacks: [(@Sendable (Bool) -> Void)] = []

    public init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self._device = device
            self._commandQueue = device.makeCommandQueue()
            PrismLogging.render.info("MetalDeviceContext initialized with device: \(device.name)")
        } else {
            PrismLogging.render.info("Metal is not available on this platform/device. Fallback path will be used.")
        }
    }

    /// Whether Metal is currently available and enabled.
    public var isSupported: Bool {
        lock.withLock {
            !_isSimulatedUnsupported && _device != nil && _commandQueue != nil
        }
    }

    /// Active Metal device, if available and not simulated-unsupported.
    public var device: MTLDevice? {
        lock.withLock {
            guard !_isSimulatedUnsupported else { return nil }
            return _device
        }
    }

    /// Active command queue, if available and not simulated-unsupported.
    public var commandQueue: MTLCommandQueue? {
        lock.withLock {
            guard !_isSimulatedUnsupported else { return nil }
            return _commandQueue
        }
    }

    /// Compiled pipelines, if compilation completed.
    public var pipelines: MetalPipelines? {
        lock.withLock {
            guard !_isSimulatedUnsupported else { return nil }
            return _pipelines
        }
    }

    /// Toggles simulated unsupported mode for automated fallback testing.
    public func setSimulatedUnsupported(_ unsupported: Bool) {
        lock.withLock {
            _isSimulatedUnsupported = unsupported
        }
    }

    /// Asynchronously compiles shader pipelines off the main thread.
    /// Does not block UI construction or rendering pass.
    public func preparePipelinesAsync(completion: (@Sendable (Bool) -> Void)? = nil) {
        lock.lock()
        if let completion {
            _compilationCallbacks.append(completion)
        }

        if _pipelines != nil {
            let callbacks = _compilationCallbacks
            _compilationCallbacks.removeAll()
            lock.unlock()
            for cb in callbacks { cb(true) }
            return
        }

        guard let device = _device, !_isSimulatedUnsupported else {
            let callbacks = _compilationCallbacks
            _compilationCallbacks.removeAll()
            lock.unlock()
            for cb in callbacks { cb(false) }
            return
        }

        if _isCompiling {
            lock.unlock()
            return
        }

        _isCompiling = true
        lock.unlock()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let pipelines = try MetalPipelines.build(device: device)
                let callbacks = self.lock.withLock {
                    self._pipelines = pipelines
                    self._isCompiling = false
                    let cbs = self._compilationCallbacks
                    self._compilationCallbacks.removeAll()
                    return cbs
                }

                PrismLogging.render.info("Metal shader pipelines compiled successfully.")
                for cb in callbacks { cb(true) }
            } catch {
                let callbacks = self.lock.withLock {
                    self._isCompiling = false
                    let cbs = self._compilationCallbacks
                    self._compilationCallbacks.removeAll()
                    return cbs
                }

                PrismLogging.render.error("Failed to compile Metal pipelines: \(error.localizedDescription)")
                for cb in callbacks { cb(false) }
            }
        }
    }


    /// Synchronously ensures pipelines are compiled (for tests or pre-warming).
    @discardableResult
    public func ensurePipelinesSync() -> Bool {
        lock.lock()
        if _pipelines != nil {
            lock.unlock()
            return true
        }
        guard let device = _device, !_isSimulatedUnsupported else {
            lock.unlock()
            return false
        }
        lock.unlock()

        do {
            let pipelines = try MetalPipelines.build(device: device)
            lock.lock()
            self._pipelines = pipelines
            lock.unlock()
            return true
        } catch {
            PrismLogging.render.error("Synchronous pipeline compilation error: \(error.localizedDescription)")
            return false
        }
    }
}

/// Tracks GPU execution times and warns if frame budget (16.6ms) is exceeded.
public struct MetalFrameBudget: Sendable {
    public static let targetFrameDurationMs: Double = 16.66

    public static func recordFrameDuration(milliseconds: Double, effect: String) {
        if milliseconds > targetFrameDurationMs {
            PrismLogging.render.warning("GPU frame budget exceeded for effect '\(effect)': \(String(format: "%.2f", milliseconds))ms > \(String(format: "%.2f", targetFrameDurationMs))ms target")
        }
    }
}
