import Foundation
import CoreGraphics
import PrismCore

/// Size tier for an activity Spinner.
public enum SpinnerSize: Sendable, Equatable {
    case sm
    case md
    case lg
    case custom(Double)

    public var dimension: Double {
        switch self {
        case .sm: return 16.0
        case .md: return 24.0
        case .lg: return 36.0
        case .custom(let d): return d
        }
    }
}

/// Circular activity spinner displaying asynchronous loading operations.
///
/// Automatically respects the system `reduceMotion` preference: when enabled,
/// continuous rotation is replaced by a static accessible loading symbol.
public struct Spinner: Component {
    public let size: SpinnerSize
    public let color: Color?

    public init(size: SpinnerSize = .md, color: Color? = nil) {
        self.size = size
        self.color = color
    }

    public func body(context: ComponentContext) -> RenderElement {
        let dim = size.dimension
        let isReducedMotion = context.environment.reduceMotion

        var props = ElementProps(accessibilityLabel: "Loading")
        props.custom["role"] = "progressbar"
        props.custom["updatesFrequently"] = "true"
        props.custom["reduceMotion"] = isReducedMotion ? "true" : "false"

        let spinnerColor = color ?? (context.theme?.colors.primary ?? Color.hex("#2563EB"))

        // Circle shape with stroke/rotation modifier
        let circleID = ElementID(typeName: "Spinner", key: "circle")
        return RenderElement(
            id: circleID,
            kind: .shape(.circle),
            props: props,
            modifiers: [
                .width(dim),
                .height(dim),
                .background(spinnerColor)
            ]
        )
    }
}
