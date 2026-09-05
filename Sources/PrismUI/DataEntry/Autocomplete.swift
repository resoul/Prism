import PrismCore

/// Platform-neutral rendering facade for free-text autocomplete suggestions.
public struct Autocomplete: Component {
    public let text: Binding<String>
    public let suggestions: [String]
    public var label: String?
    public var isLoading: Bool
    public var isDisabled: Bool
    public init(_ label: String? = nil, text: Binding<String>, suggestions: [String] = [], isLoading: Bool = false, isDisabled: Bool = false) {
        self.label = label; self.text = text; self.suggestions = suggestions; self.isLoading = isLoading; self.isDisabled = isDisabled
    }
    public func body(context: ComponentContext) -> RenderElement {
        var element = Input(text: text).render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "combobox", "inputMode": "freeText", "value": text.wrappedValue, "suggestionCount": String(suggestions.count), "isLoading": isLoading ? "true" : "false", "isDisabled": isDisabled ? "true" : "false"]
        return element
    }
}
