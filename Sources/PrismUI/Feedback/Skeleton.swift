import Foundation
@_exported import PrismCore

/// Shape geometry variants for placeholder skeleton loaders.
public enum SkeletonShape: Equatable, Sendable {
    case rounded(radius: Double = 6)
    case circle
    case rectangle
}

/// A shimmer and pulse placeholder component for asynchronous content loading.
///
/// Automatically inspects `ReduceMotionPreference`: under active Reduce Motion,
/// the pulsing animation is suppressed and a calm static placeholder is displayed.
public struct Skeleton: Component {
    public let shape: SkeletonShape
    public let width: Double?
    public let height: Double?

    public init(
        shape: SkeletonShape = .rounded(radius: 6),
        width: Double? = nil,
        height: Double? = nil
    ) {
        self.shape = shape
        self.width = width
        self.height = height
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight
        let isReduceMotion = context.environment.reduceMotion

        let cornerRadius: Double
        switch shape {
        case .rounded(let r): cornerRadius = r
        case .circle: cornerRadius = (width ?? height ?? 32) / 2.0
        case .rectangle: cornerRadius = 0
        }

        let baseColor = colors.mutedForeground.opacity(0.18)

        var modifiers: [ElementModifier] = [
            .sdfRoundedRect(
                cornerRadius: cornerRadius,
                borderWidth: 0,
                borderColor: .clear,
                fill: baseColor
            )
        ]

        if let width { modifiers.append(.width(width)) }
        if let height { modifiers.append(.height(height)) }

        // Animate opacity only when reduceMotion is disabled
        if !isReduceMotion {
            modifiers.append(.opacity(0.6))
            modifiers.append(.animation(.easeInOut(duration: 0.8).repeatForever()))
        } else {
            modifiers.append(.opacity(0.4))
        }

        return RenderElement(
            id: ElementID(typeName: "Skeleton"),
            kind: .custom("Skeleton"),
            props: ElementProps(
                accessibilityLabel: "Loading"
            ),
            modifiers: modifiers
        )
        .accessibilityElement(label: "Loading...", role: "progressbar")
    }
}
