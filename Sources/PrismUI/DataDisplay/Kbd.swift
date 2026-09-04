import Foundation
@_exported import PrismCore

/// A keycap component for rendering keyboard shortcuts and hardware keys.
///
/// Designed with ShadCN styling featuring subtle borders, soft backgrounds,
/// and semantic accessibility traits for screen readers.
public struct Kbd: Component {
    public let key: String
    public let accessibleLabel: String?

    public init(_ key: String, accessibleLabel: String? = nil) {
        self.key = key
        self.accessibleLabel = accessibleLabel
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight

        // Derive accessibility label from well-known symbol or provided label
        let label = accessibleLabel ?? Self.standardLabel(for: key)

        return HStack(alignment: .center) {
            Text(key)
                .font(.mono)
                .foregroundColor(colors.foreground)
        }
        .padding(DirectionalEdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
        .background(colors.secondary)
        .sdfRoundedRect(
            cornerRadius: 4,
            borderWidth: 1,
            borderColor: colors.border,
            fill: colors.secondary
        )
        .accessibilityElement(label: label, role: "keyboardKey")
        .render(in: context)
    }

    private static func standardLabel(for key: String) -> String {
        switch key {
        case "⌘", "cmd", "command": return "Command"
        case "⇧", "shift": return "Shift"
        case "⌥", "opt", "option", "alt": return "Option"
        case "⌃", "ctrl", "control": return "Control"
        case "↵", "enter", "return": return "Return"
        case "⎋", "esc", "escape": return "Escape"
        case "⇥", "tab": return "Tab"
        case "⌫", "delete", "backspace": return "Delete"
        case "␣", "space": return "Space"
        case "↑", "up": return "Up Arrow"
        case "↓", "down": return "Down Arrow"
        case "←", "left": return "Left Arrow"
        case "→", "right": return "Right Arrow"
        default: return key
        }
    }
}
