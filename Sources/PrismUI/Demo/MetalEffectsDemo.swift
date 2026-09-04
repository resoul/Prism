import Foundation
@_exported import PrismCore

/// Isolated demonstration scene showcasing Prism Metal-rendered effects:
/// - SDF Rounded Rectangle with sub-pixel anti-aliased borders and fill.
/// - Glassmorphism frosted card with blur, saturation boost, and tint overlay.
/// - Multi-color 2D Mesh Gradient banner.
/// - Fallback toggle switch simulating unsupported devices.
public struct MetalEffectsDemo: Component {
    public var isSimulatingFallback: Bool

    public init(isSimulatingFallback: Bool = false) {
        self.isSimulatingFallback = isSimulatingFallback
    }

    public func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 24) {
            // 1. Mesh Gradient Header
            MeshGradient(
                columns: 3,
                rows: 2,
                colors: [
                    Color(red: 0.95, green: 0.35, blue: 0.45),
                    Color(red: 0.55, green: 0.35, blue: 0.95),
                    Color(red: 0.25, green: 0.65, blue: 0.95),
                    Color(red: 0.95, green: 0.75, blue: 0.25),
                    Color(red: 0.25, green: 0.85, blue: 0.65),
                    Color(red: 0.35, green: 0.45, blue: 0.95)
                ],
                height: 140
            )

            // 2. SDF Rounded Rectangle Card
            VStack(spacing: 8) {
                Text("SDF Anti-Aliased Card")
                Text("Sub-pixel anti-aliased corners and border width")
            }
            .padding(16)
            .sdfRoundedRect(
                cornerRadius: 24,
                borderWidth: 2.0,
                borderColor: Color(red: 0.35, green: 0.65, blue: 0.95),
                fill: Color(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.9)
            )

            // 3. Frosted Glassmorphism Card
            VStack(spacing: 8) {
                Text("Frosted Glass Card")
                Text("Blur radius 24, saturation 1.3, specular tint")
            }
            .padding(20)
            .glassmorphism(
                blurRadius: 24,
                tint: Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25),
                saturation: 1.3
            )

            // 4. Status Indicator
            VStack(spacing: 4) {
                Text("Metal Backend Status:")
                Text(MetalDeviceContext.shared.isSupported ? "Metal 3 Ready" : "CALayer Fallback Active")
            }
        }
        .padding(20)
    }
}
