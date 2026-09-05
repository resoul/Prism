import PrismCore

public struct Chart: Component {
    public let model: ChartModel; public var label: String?
    public init(_ label: String? = nil, model: ChartModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Chart (\(model.kind.rawValue))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "img", "chartKind": model.kind.rawValue, "seriesCount": String(model.series.count), "pointCount": String(model.series.reduce(0) { $0 + $1.points.count })]; return element }
}
