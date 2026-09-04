import Foundation
import CoreGraphics
import PrismCore

/// Diagnostic inspector tracking real-time animation state, transaction IDs, active animation counts,
/// and transition lifecycle events.
public final class AnimationInspectorTelemetry: @unchecked Sendable {
    public static let shared = AnimationInspectorTelemetry()

    public struct LogEntry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp: Date
        public let message: String
        public let category: String
    }

    private let lock = NSLock()
    private var _recentLogs: [LogEntry] = []
    private var _lastTransactionID: UUID?
    private var _activeAnimationCount: Int = 0
    private var _reduceMotionEnabled: Bool = false
    private let maxEntries = 20

    public var recentLogs: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _recentLogs
    }

    public var lastTransactionID: UUID? {
        lock.lock()
        defer { lock.unlock() }
        return _lastTransactionID
    }

    public var activeAnimationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _activeAnimationCount
    }

    public var isReduceMotionEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _reduceMotionEnabled
    }

    private init() {
        Task { @MainActor in
            LayerAnimationBridge.onAnimationStarted = { [weak self] prop, txID in
                self?.notifyStarted(prop: prop, txID: txID)
            }
            LayerAnimationBridge.onAnimationCompleted = { [weak self] prop, txID in
                self?.notifyCompleted(prop: prop, txID: txID)
            }
        }
    }

    public func notifyStarted(prop: String, txID: UUID?) {
        lock.lock()
        defer { lock.unlock() }
        _activeAnimationCount += 1
        _lastTransactionID = txID
        let entry = LogEntry(timestamp: Date(), message: "Animated '\(prop)' (tx: \(txID?.uuidString.prefix(8) ?? "none"))", category: "Start")
        _recentLogs.insert(entry, at: 0)
        if _recentLogs.count > maxEntries {
            _recentLogs.removeLast()
        }
    }

    public func notifyCompleted(prop: String, txID: UUID?) {
        lock.lock()
        defer { lock.unlock() }
        _activeAnimationCount = max(0, _activeAnimationCount - 1)
        let entry = LogEntry(timestamp: Date(), message: "Finished '\(prop)' (tx: \(txID?.uuidString.prefix(8) ?? "none"))", category: "Done")
        _recentLogs.insert(entry, at: 0)
        if _recentLogs.count > maxEntries {
            _recentLogs.removeLast()
        }
    }

    public func record(category: String, message: String) {
        lock.lock()
        defer { lock.unlock() }
        let entry = LogEntry(timestamp: Date(), message: message, category: category)
        _recentLogs.insert(entry, at: 0)
        if _recentLogs.count > maxEntries {
            _recentLogs.removeLast()
        }
    }

    public func setReduceMotion(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _reduceMotionEnabled = enabled
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _recentLogs.removeAll()
        _lastTransactionID = nil
        _activeAnimationCount = 0
    }
}

/// UI Component presenting live animation diagnostics and active metrics.
public struct AnimationInspector: Component {
    public var isVisible: Bool

    public init(isVisible: Bool = true) {
        self.isVisible = isVisible
    }

    public func body(context: ComponentContext) -> RenderElement {
        guard isVisible else {
            return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
        }

        let telemetry = AnimationInspectorTelemetry.shared
        let activeCount = telemetry.activeAnimationCount
        let txID = telemetry.lastTransactionID?.uuidString.prefix(8) ?? "none"
        let isReduceMotion = telemetry.isReduceMotionEnabled

        let title = RenderElement(
            id: ElementID(typeName: "Text", key: "inspector_title"),
            kind: .text("Animation & Transition Inspector")
        )

        let statusText = "Active Animations: \(activeCount) | Last Tx: \(txID) | Reduce Motion: \(isReduceMotion ? "ON" : "OFF")"
        let statusElement = RenderElement(
            id: ElementID(typeName: "Text", key: "inspector_status"),
            kind: .text(statusText)
        )

        var logElements: [RenderElement] = []
        for (idx, entry) in telemetry.recentLogs.prefix(5).enumerated() {
            let row = RenderElement(
                id: ElementID(typeName: "Text", key: "log_\(idx)"),
                kind: .text("[\(entry.category)] \(entry.message)")
            )
            logElements.append(row)
        }

        let stackChildren = [title, statusElement] + logElements

        return RenderElement(
            id: ElementID(typeName: "AnimationInspector"),
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 6.0),
            modifiers: [
                .padding(.init(top: 10, leading: 12, bottom: 10, trailing: 12)),
                .background(Color.hex("#1E293B")),
                .testID("animation_inspector")
            ],
            children: stackChildren
        )
    }
}
