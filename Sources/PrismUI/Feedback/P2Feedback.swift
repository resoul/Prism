import Foundation
import PrismCore

public enum ToastVariant: String, Sendable, Equatable { case info, success, warning, destructive }

/// Immutable toast payload. Reusing `deduplicationKey` coalesces repeated notifications.
public struct ToastItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let message: String?
    public let variant: ToastVariant
    public let deduplicationKey: String?

    public init(id: UUID = UUID(), title: String, message: String? = nil, variant: ToastVariant = .info, deduplicationKey: String? = nil) {
        self.id = id; self.title = title; self.message = message; self.variant = variant; self.deduplicationKey = deduplicationKey
    }
}

/// Main-actor queue with visible-capacity, deduplication, and accessible announcement state.
@MainActor
public final class ToastCenter {
    public let maximumVisible: Int
    public private(set) var visible: [ToastItem] = []
    public private(set) var pending: [ToastItem] = []
    public private(set) var lastAnnouncement: String?

    public init(maximumVisible: Int = 3) { self.maximumVisible = max(1, maximumVisible) }

    public func enqueue(_ item: ToastItem) {
        if let key = item.deduplicationKey,
           visible.contains(where: { $0.deduplicationKey == key }) || pending.contains(where: { $0.deduplicationKey == key }) { return }
        if visible.count < maximumVisible { visible.append(item); announce(item) } else { pending.append(item) }
    }

    public func dismiss(id: UUID) {
        visible.removeAll { $0.id == id }
        pending.removeAll { $0.id == id }
        promote()
    }

    public func dismissAll() { visible.removeAll(); pending.removeAll(); lastAnnouncement = nil }
    private func promote() { while visible.count < maximumVisible, !pending.isEmpty { let item = pending.removeFirst(); visible.append(item); announce(item) } }
    private func announce(_ item: ToastItem) { lastAnnouncement = [item.title, item.message].compactMap { $0 }.joined(separator: ": ") }
}

/// A transient toast surface rendered in the dedicated toast overlay tier.
public struct Toast: Component {
    public let item: ToastItem
    public init(_ item: ToastItem) { self.item = item }
    public func body(context: ComponentContext) -> RenderElement {
        var element = VStack(alignment: .start, spacing: 4) { Text(item.title); if let message = item.message { Text(message) } }
            .padding(12).background(Color.hex("#0F172A")).render(in: context).portal(layer: .toast)
        element.props.accessibilityLabel = [item.title, item.message].compactMap { $0 }.joined(separator: ": ")
        element.props.custom = ["role": "alert", "liveRegion": "polite", "variant": item.variant.rawValue, "toastID": item.id.uuidString]
        return element
    }
}

/// Progress indicator supporting known and unknown completion states.
public struct Progress: Component {
    public var value: Double?
    public var total: Double
    public var label: String?
    public init(value: Double? = nil, total: Double = 1, label: String? = nil) { self.value = value; self.total = max(total, .leastNonzeroMagnitude); self.label = label }
    public var fractionCompleted: Double? { value.map { min(max($0 / total, 0), 1) } }
    public func body(context: ComponentContext) -> RenderElement {
        let fraction = fractionCompleted
        var element = Rectangle(cornerRadius: 4).fill(Color.hex("#2563EB")).frame(width: 160 * (fraction ?? 1), height: 8)
        element.props.accessibilityLabel = label ?? (fraction == nil ? "Loading" : "Progress")
        element.props.custom = ["role": "progressbar", "isIndeterminate": fraction == nil ? "true" : "false", "value": fraction.map { String($0) } ?? "", "minimum": "0", "maximum": "1"]
        return element
    }
}
