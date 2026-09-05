import PrismCore

/// Platform-neutral upload status facade; picker/drop adapters remain host-owned.
public struct FileUpload: Component {
    public var label: String?; public var status: UploadStatus; public var isDisabled: Bool
    public init(_ label: String? = nil, status: UploadStatus = .idle, isDisabled: Bool = false) { self.label = label; self.status = status; self.isDisabled = isDisabled }
    public func body(context: ComponentContext) -> RenderElement { var element = Text(label ?? "Upload").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "button", "control": "fileUpload", "status": String(describing: status), "isDisabled": isDisabled ? "true" : "false"]; return element }
}
