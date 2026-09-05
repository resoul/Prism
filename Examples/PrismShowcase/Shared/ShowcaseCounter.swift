import PrismUI

@MainActor
final class ShowcaseCounterStore {
    private(set) var count = 0
    var onChange: ((RenderElement) -> Void)?

    func rootElement() -> RenderElement {
        VStack(spacing: 16) {
            Text("Prism Showcase").font(.heading).testID("showcase.title")
            Text("Counter: \(count)").testID("showcase.counter")
            Button("Increment") { [weak self] in
                self?.increment()
            }
            .testID("showcase.increment")
            .accessibilityLabel("Increment counter")
        }
        .padding(24)
        .render()
    }

    func reset() {
        count = 0
        publish()
    }

    private func increment() {
        count += 1
        publish()
    }

    private func publish() {
        onChange?(rootElement())
    }
}
