import PrismCore

/// Experimental split-panel facade; host adapters own pointer/keyboard event routing.
public struct Resizable: Component {
    public var split: ResizableSplit
    public var label: String?
    public init(_ label: String? = nil, split: ResizableSplit = ResizableSplit()) { self.label = label; self.split = split }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack { Text("Panel"); Spacer(); Text("Panel") }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "separator", "ratio": String(split.ratio), "minimumRatio": String(split.minimumRatio), "maximumRatio": String(split.maximumRatio), "direction": split.direction.rawValue, "isCapturing": split.isCapturing ? "true" : "false"]
        return element
    }
}
