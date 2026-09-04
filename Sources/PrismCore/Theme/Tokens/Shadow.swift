import Foundation
import CoreGraphics

/// Elevation and shadow definition for surfaces and overlays.
public struct Shadow: Equatable, Sendable {
    public let offset: CGSize
    public let blur: CGFloat
    public let spread: CGFloat
    public let color: Color
    public let opacity: CGFloat

    public init(
        offset: CGSize = .zero,
        blur: CGFloat = 0,
        spread: CGFloat = 0,
        color: Color = .black,
        opacity: CGFloat = 0.1
    ) {
        self.offset = offset
        self.blur = blur
        self.spread = spread
        self.color = color
        self.opacity = opacity
    }

    public static let none = Shadow(offset: .zero, blur: 0, spread: 0, opacity: 0)

    public static let sm = Shadow(
        offset: CGSize(width: 0, height: 1),
        blur: 2,
        spread: 0,
        opacity: 0.05
    )

    public static let md = Shadow(
        offset: CGSize(width: 0, height: 4),
        blur: 6,
        spread: -1,
        opacity: 0.1
    )

    public static let lg = Shadow(
        offset: CGSize(width: 0, height: 10),
        blur: 15,
        spread: -3,
        opacity: 0.1
    )

    public static let xl = Shadow(
        offset: CGSize(width: 0, height: 20),
        blur: 25,
        spread: -5,
        opacity: 0.15
    )
}
