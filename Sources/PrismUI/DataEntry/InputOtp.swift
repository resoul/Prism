import PrismCore

/// Experimental OTP control: one logical value rendered as privacy-safe visual segments.
public struct InputOtp: Component {
    public let value: Binding<String>
    public let length: Int
    public var label: String?
    public var isDisabled: Bool
    public init(_ label: String? = nil, value: Binding<String>, length: Int = 6, isDisabled: Bool = false) { self.label = label; self.value = value; self.length = max(1, length); self.isDisabled = isDisabled }
    public func paste(_ text: String) { guard !isDisabled else { return }; var doc = OTPDocument(length: length, value: value.wrappedValue); _ = doc.paste(text); value.setIfChanged(doc.value) }
    public func backspace() { guard !isDisabled else { return }; var doc = OTPDocument(length: length, value: value.wrappedValue); _ = doc.backspace(); value.setIfChanged(doc.value) }
    public func body(context: ComponentContext) -> RenderElement {
        let count = min(value.wrappedValue.count, length)
        var element = HStack(spacing: 6) { for index in 0..<length { Text(index < count ? "•" : "○") } }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "textField", "inputMode": "oneTimeCode", "value": "", "length": String(length), "filledCount": String(count), "isComplete": count == length ? "true" : "false", "isDisabled": isDisabled ? "true" : "false"]
        return element
    }
}
