import Foundation
import PrismCore

/// Unified vertical smoke test scene exhibiting Prism's core capabilities:
/// Theme container background, vertical stack, typography, vector shapes, spacer, and icons.
public enum SmokeScene {
    /// Builds the standard cross-platform smoke test scene.
    public static func makeRoot() -> RenderElement {
        VStack(alignment: .center, spacing: 16) {
            Text("Prism")
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0))

            Text("Cross-Platform Host Bridge Active")
                .opacity(0.8)

            Rectangle(cornerRadius: 12)
                .fill(Color(red: 0.2, green: 0.45, blue: 0.85, alpha: 1.0))
                .frame(width: 160, height: 60)

            Circle()
                .fill(Color(red: 0.15, green: 0.75, blue: 0.35, alpha: 1.0))
                .frame(width: 60, height: 60)

            Icon("sparkles")
                .frame(width: 32, height: 32)

            Spacer(minLength: 20)

            Text("Ready for iOS and macOS")
                .opacity(0.6)
        }
        .padding(24)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0))
    }
}

