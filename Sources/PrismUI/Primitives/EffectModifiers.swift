import Foundation
@_exported import PrismCore

public extension Component {
    /// Applies an anti-aliased Signed Distance Field rounded rectangle effect.
    ///
    /// Fallback: On devices without Metal support, falls back gracefully to standard CALayer
    /// cornerRadius, borderWidth, borderColor, and backgroundColor.
    func sdfRoundedRect(
        cornerRadius: Double,
        borderWidth: Double = 0,
        borderColor: Color = .clear,
        fill: Color? = nil
    ) -> RenderElement {
        render().sdfRoundedRect(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            borderColor: borderColor,
            fill: fill
        )
    }

    /// Applies a frosted glassmorphism effect with blur, saturation boost, and tint overlay.
    ///
    /// Fallback: On devices without Metal support, falls back to a tinted semi-transparent
    /// overlay maintaining layout and visual hierarchy without crashing.
    func glassmorphism(
        blurRadius: Double = 20,
        tint: Color = Color(red: 1, green: 1, blue: 1, alpha: 0.2),
        saturation: Double = 1.2
    ) -> RenderElement {
        render().glassmorphism(
            blurRadius: blurRadius,
            tint: tint,
            saturation: saturation
        )
    }

    /// Applies a multi-color mesh gradient effect.
    ///
    /// Fallback: On devices without Metal support, falls back to a multi-stop linear gradient
    /// matching the boundary colors.
    func meshGradient(_ grid: MeshGradientGrid) -> RenderElement {
        render().meshGradient(grid)
    }
}
