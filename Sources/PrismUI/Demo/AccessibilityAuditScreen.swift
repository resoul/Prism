import Foundation
import PrismCore

/// Host-runnable AX fixture covering labels, values, actions, focusable controls, and overlay restoration.
public struct AccessibilityAuditScreen: Component {
    public init() {}
    public func body(context: ComponentContext) -> RenderElement {
        var enabled = true; var quantity = 2.0; var page = 1; var presented = false
        return VStack(alignment: .start, spacing: 12) {
            Text("Accessibility audit fixture").font(.heading)
            Button("Primary action") { }.accessibilityLabel("Perform primary action")
            Switch("Notifications", isOn: Binding(get: { enabled }, set: { enabled = $0 }))
            NumberField("Quantity", value: Binding(get: { quantity }, set: { quantity = $0 }), range: 0...10, step: 1)
            Progress(value: 1, total: 2, label: "File upload")
            Pagination(page: Binding(get: { page }, set: { page = $0 }), pageCount: 3, label: "Result pages")
            AlertDialog(isPresented: Binding(get: { presented }, set: { presented = $0 }), title: "Confirm action", onConfirm: {})
        }.padding(20).render(in: context)
    }
}
