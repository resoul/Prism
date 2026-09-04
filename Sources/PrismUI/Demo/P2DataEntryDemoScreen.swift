import Foundation
import PrismCore

/// Runnable catalog fixture for the Phase 05 P2 data-entry controls.
/// The host owns the bindings so this screen deliberately has no competing input state.
public struct P2DataEntryDemoScreen: Component {
    public init() {}

    public func body(context: ComponentContext) -> RenderElement {
        var quantity = 2.0
        var opacity = 0.5
        var rating = 3
        var selected: Set<String> = ["compact"]
        var plan = "pro"
        return VStack(alignment: .stretch, spacing: 16) {
            Text("P2 Data Entry").font(.heading)
            ButtonGroup(label: "Document actions") { Button("Save") {}; Button("Preview", variant: .secondary) {} }
            NumberField("Quantity", value: Binding(get: { quantity }, set: { quantity = $0 }), range: 0...10, step: 1)
            Slider(value: Binding(get: { opacity }, set: { opacity = $0 }), in: 0...1, step: 0.1, label: "Opacity")
            ToggleGroup(options: [SelectionOption("compact", label: "Compact"), SelectionOption("comfortable", label: "Comfortable")], selected: Binding(get: { selected }, set: { selected = $0 }), label: "Density")
            Stepper("Retries", value: Binding(get: { quantity }, set: { quantity = $0 }), range: 0...10)
            Rating(value: Binding(get: { rating }, set: { rating = $0 }), label: "Quality")
            InputGroup(leading: { Text("https://") }, input: { Input("domain", text: .constant("prism.dev")) }, trailing: { Text(".dev") })
            Select("Plan", selection: Binding(get: { plan }, set: { plan = $0 }), options: [SelectionOption("free", label: "Free"), SelectionOption("pro", label: "Pro")])
            NativeSelect("Native plan", selection: Binding(get: { plan }, set: { plan = $0 }), options: [SelectionOption("free", label: "Free"), SelectionOption("pro", label: "Pro")])
        }.padding(24).render(in: context)
    }
}
