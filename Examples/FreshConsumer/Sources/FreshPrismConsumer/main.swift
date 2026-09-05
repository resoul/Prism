import PrismUI
import Flux

struct Welcome: Component {
    func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 12) {
            Text("Welcome to Prism").font(.heading)
            Button("Continue") { }
        }
        .padding(24)
        .render(in: context)
    }
}

let tree = Welcome().render()
print(tree.dumpTree())
