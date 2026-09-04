import Foundation

/// Debug inspector providing diagnostics for component state keys, active subscriptions,
/// running effects, and effect cancellation reasons.
@MainActor
public enum StateInspector {
    /// Generates a human-readable diagnostic report for a mounted node's state and effects.
    public static func dump(for node: MountedNode) -> String {
        var lines: [String] = []
        lines.append("=== State & Effect Diagnostics [\(node.id)] ===")
        lines.append("Subscriptions: \(node.subscriptionBag.count)")
        lines.append("Active Effects: \(node.effectScope.activeTasks.count)")

        for (id, reason) in node.effectScope.lastCancellationReasons {
            lines.append("  - Effect '\(id)' cancellation: \(reason.rawValue)")
        }

        let matchingKeys = ComponentStateStore.shared.registeredKeys.filter { $0.elementID == node.id }
        lines.append("Component States: \(matchingKeys.count)")
        for key in matchingKeys {
            lines.append("  - State key: '\(key.name)'")
        }

        return lines.joined(separator: "\n")
    }
}
