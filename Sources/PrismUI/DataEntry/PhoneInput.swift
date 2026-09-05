import PrismCore

/// Experimental country-aware phone editor exposing canonical E.164 values through Binding.
public struct PhoneInput: Component {
    public let value: Binding<String>
    public let country: PhoneCountry?
    public var label: String?
    public var isDisabled: Bool
    public init(_ label: String? = nil, value: Binding<String>, country: PhoneCountry? = nil, isDisabled: Bool = false) { self.label = label; self.value = value; self.country = country; self.isDisabled = isDisabled }
    public func normalize(_ text: String) { guard !isDisabled else { return }; if let number = try? PhoneNumber(text, country: country) { value.setIfChanged(number.canonical) } else { value.setIfChanged(text.filter(\.isNumber)) } }
    public func body(context: ComponentContext) -> RenderElement {
        var element = Input(text: value).render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "telephoneInput", "value": value.wrappedValue, "country": country?.code ?? "", "isDisabled": isDisabled ? "true" : "false"]
        return element
    }
}
