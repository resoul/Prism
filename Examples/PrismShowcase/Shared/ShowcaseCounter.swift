import Foundation
import PrismUI

/// Immutable state snapshot for the interactive showcase application.
public struct ShowcaseState: Equatable, Sendable {
    public var count: Int
    public var inputText: String
    public var submittedText: String
    public var scrollOffset: Double
    public var lastAction: String

    public init(
        count: Int = 0,
        inputText: String = "",
        submittedText: String = "",
        scrollOffset: Double = 0.0,
        lastAction: String = "none"
    ) {
        self.count = count
        self.inputText = inputText
        self.submittedText = submittedText
        self.scrollOffset = scrollOffset
        self.lastAction = lastAction
    }
}

/// Flux-backed, MainActor-isolated state store driving the showcase screen.
/// Implements deterministic state transitions, cancellation of subscriptions on teardown,
/// and reactive root element publication without manual render calls.
@MainActor
public final class ShowcaseStore {
    private var _state: ShowcaseState
    private let statePipe = Pipe<ShowcaseState>()
    private let bag = SubscriptionBag()
    private var isTornDown = false

    public var onChange: (@MainActor (RenderElement) -> Void)?

    public var state: ShowcaseState {
        _state
    }

    public var count: Int {
        _state.count
    }

    public var inputText: String {
        _state.inputText
    }

    public var submittedText: String {
        _state.submittedText
    }

    public var scrollOffset: Double {
        _state.scrollOffset
    }

    public init(initialState: ShowcaseState = ShowcaseState()) {
        self._state = initialState
    }

    // MARK: - Actions

    public func increment() {
        var s = _state
        s.count += 1
        s.lastAction = "increment"
        update(s)
    }

    public func decrement() {
        var s = _state
        s.count -= 1
        s.lastAction = "decrement"
        update(s)
    }

    public func reset() {
        update(ShowcaseState())
    }

    public func setInputText(_ text: String) {
        var s = _state
        s.inputText = text
        s.lastAction = "setInputText"
        update(s)
    }

    public func submitInput() {
        var s = _state
        s.submittedText = s.inputText
        s.lastAction = "submitInput"
        update(s)
    }

    public func scrollBy(_ delta: Double) {
        var s = _state
        s.scrollOffset = max(0.0, s.scrollOffset + delta)
        s.lastAction = "scrollBy"
        update(s)
    }

    public func setScrollOffset(_ offset: Double) {
        var s = _state
        s.scrollOffset = max(0.0, offset)
        s.lastAction = "setScrollOffset"
        update(s)
    }

    public func teardown() {
        isTornDown = true
        statePipe.finish()
        bag.cancelAll()
        onChange = nil
    }

    private func update(_ newState: ShowcaseState) {
        guard !isTornDown else { return }
        _state = newState
        statePipe.send(newState)
        publish()
    }

    private func publish() {
        guard !isTornDown else { return }
        onChange?(rootElement())
    }

    // MARK: - UI Construction

    public func rootElement() -> RenderElement {
        let current = _state

        let inputBinding = Binding<String>(
            get: { [weak self] in self?._state.inputText ?? "" },
            set: { [weak self] newValue in self?.setInputText(newValue) }
        )

        return VStack(alignment: .start, spacing: 16) {
            // Header
            Text("Prism Showcase")
                .font(.heading)
                .testID("showcase.title")

            // Counter Fixture
            HStack(spacing: 12) {
                Text("Counter: \(current.count)")
                    .testID("showcase.counter")

                Button("Increment") { [weak self] in
                    self?.increment()
                }
                .testID("showcase.increment")
                .accessibilityLabel("Increment counter")

                Button("Decrement") { [weak self] in
                    self?.decrement()
                }
                .testID("showcase.decrement")
                .accessibilityLabel("Decrement counter")

                Button("Reset") { [weak self] in
                    self?.reset()
                }
                .testID("showcase.reset")
                .accessibilityLabel("Reset counter")
            }

            // Input Fixture
            VStack(alignment: .start, spacing: 8) {
                Text("Input: \(current.inputText)")
                    .testID("showcase.input_display")

                HStack(spacing: 8) {
                    Input("Type something...", text: inputBinding)
                        .testID("showcase.input")
                        .accessibilityLabel("Showcase text input")

                    Button("Submit") { [weak self] in
                        self?.submitInput()
                    }
                    .testID("showcase.input_submit")
                    .accessibilityLabel("Submit input text")
                }

                if !current.submittedText.isEmpty {
                    Text("Submitted: \(current.submittedText)")
                        .testID("showcase.submitted_display")
                }
            }

            // Scroll Fixture
            VStack(alignment: .start, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Scroll offset: \(Int(current.scrollOffset))")
                        .testID("showcase.scroll_status")

                    Button("Scroll Down") { [weak self] in
                        self?.scrollBy(20)
                    }
                    .testID("showcase.scroll_down")
                    .accessibilityLabel("Scroll down")

                    Button("Scroll Up") { [weak self] in
                        self?.scrollBy(-20)
                    }
                    .testID("showcase.scroll_up")
                    .accessibilityLabel("Scroll up")
                }

                ScrollArea(.vertical) {
                    VStack(alignment: .start, spacing: 4) {
                        for i in 1...20 {
                            Text("Item \(i)")
                                .testID("showcase.scroll_item_\(i)")
                        }
                    }
                }
                .testID("showcase.scroll_area")
                .height(100)
            }
        }
        .padding(24)
        .render()
    }
}

/// Backwards compatibility alias for the initial Phase 07 prototype store.
public typealias ShowcaseCounterStore = ShowcaseStore
