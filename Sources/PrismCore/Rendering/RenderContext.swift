import Foundation
import QuartzCore

/// Context passed to layer renderers containing scale factors, active theme, and transaction policies.
public struct RenderContext: Sendable {
    public var scaleFactor: Double
    public var theme: Theme?
    public var colorScheme: ColorScheme
    public var disableActions: Bool
    public var reduceMotion: Bool

    public init(
        scaleFactor: Double = 2.0,
        theme: Theme? = nil,
        colorScheme: ColorScheme = .light,
        disableActions: Bool = true,
        reduceMotion: Bool = false
    ) {
        self.scaleFactor = max(1.0, scaleFactor)
        self.theme = theme
        self.colorScheme = colorScheme
        self.disableActions = disableActions
        self.reduceMotion = reduceMotion
    }

    public static let `default` = RenderContext()
}

/// Transaction wrapper ensuring deterministic layer mutations without unwanted implicit Core Animation actions.
public enum RenderTransaction {
    /// Executes layer mutations synchronously, disabling implicit animations by default.
    public static func perform(disableActions: Bool = true, _ block: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(disableActions)
        block()
        CATransaction.commit()
    }
}
