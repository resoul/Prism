import Foundation
import PrismUI

/// Immutable state snapshot for the interactive showcase application.
public struct ShowcaseState: Equatable, Sendable {
    public var count: Int
    public var inputText: String
    public var submittedText: String
    public var scrollOffset: Double
    public var themeSelection: ThemeSelection
    public var activeThemeID: ThemeID
    public var lastAction: String

    public init(
        count: Int = 0,
        inputText: String = "",
        submittedText: String = "",
        scrollOffset: Double = 0.0,
        themeSelection: ThemeSelection = .system,
        activeThemeID: ThemeID = .light,
        lastAction: String = "none"
    ) {
        self.count = count
        self.inputText = inputText
        self.submittedText = submittedText
        self.scrollOffset = scrollOffset
        self.themeSelection = themeSelection
        self.activeThemeID = activeThemeID
        self.lastAction = lastAction
    }
}

/// Flux-backed, MainActor-isolated state store driving the showcase screen.
/// Implements deterministic state transitions, cancellation of subscriptions on teardown,
/// theme selection persistence, and reactive root element publication without manual render calls.
@MainActor
public final class ShowcaseStore {
    private var _state: ShowcaseState
    private let preferences: ShowcasePreferences
    private var themeEnvironment: ThemeEnvironment
    private let statePipe = Pipe<ShowcaseState>()
    private let bag = SubscriptionBag()
    private var isTornDown = false

    public var onChange: (@MainActor (RenderElement) -> Void)?
    public var onThemeChange: (@MainActor (Theme) -> Void)?

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

    public var themeSelection: ThemeSelection {
        _state.themeSelection
    }

    public var activeThemeID: ThemeID {
        _state.activeThemeID
    }

    public var activeTheme: Theme {
        (try? themeEnvironment.resolvedTheme()) ?? ShowcaseThemePresets.light
    }

    public convenience init(initialState: ShowcaseState? = nil) {
        self.init(initialState: initialState, preferences: ShowcasePreferences())
    }

    public init(
        initialState: ShowcaseState?,
        preferences: ShowcasePreferences
    ) {
        self.preferences = preferences
        let config = ShowcaseConfig.bundled
        let initialSelection = initialState?.themeSelection ?? preferences.themeSelection
        let env = ThemeEnvironment(
            config: config,
            selection: initialSelection,
            currentSystemScheme: .light
        )
        self.themeEnvironment = env
        let resolvedID = (try? env.resolvedTheme().id) ?? .light

        if let explicitState = initialState {
            self._state = explicitState
        } else {
            self._state = ShowcaseState(
                themeSelection: initialSelection,
                activeThemeID: resolvedID
            )
        }
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
        preferences.reset()
        themeEnvironment.selection = .system
        let resolvedID = (try? themeEnvironment.resolvedTheme().id) ?? .light
        let s = ShowcaseState(
            themeSelection: .system,
            activeThemeID: resolvedID,
            lastAction: "reset"
        )
        update(s)
        onThemeChange?(activeTheme)
    }

    public func selectTheme(_ selection: ThemeSelection) {
        preferences.themeSelection = selection
        themeEnvironment.selection = selection
        var s = _state
        s.themeSelection = selection
        s.activeThemeID = activeTheme.id
        s.lastAction = "selectTheme"
        update(s)
        onThemeChange?(activeTheme)
    }

    public func setSystemColorScheme(_ scheme: ColorScheme) {
        themeEnvironment.currentSystemScheme = scheme
        if _state.themeSelection == .system {
            var s = _state
            s.activeThemeID = activeTheme.id
            s.lastAction = "setSystemColorScheme(\(scheme.rawValue))"
            update(s)
            onThemeChange?(activeTheme)
        }
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
        onThemeChange = nil
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
        let theme = activeTheme
        let colors = theme.colors

        let inputBinding = Binding<String>(
            get: { [weak self] in self?._state.inputText ?? "" },
            set: { [weak self] newValue in self?.setInputText(newValue) }
        )

        return VStack(alignment: .start, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Text("Prism Showcase")
                    .font(.heading)
                    .foregroundColor(colors.foreground)
                    .testID("showcase.title")

                Text("Theme: \(current.activeThemeID.rawValue)")
                    .font(.body)
                    .foregroundColor(colors.mutedForeground)
                    .testID("showcase.theme.status")
            }

            // Theme Switcher Fixture
            VStack(alignment: .start, spacing: 8) {
                Text("Theme Presets:")
                    .font(.body)
                    .foregroundColor(colors.foreground)
                    .testID("showcase.theme.label")

                HStack(spacing: 8) {
                    Button("System") { [weak self] in
                        self?.selectTheme(.system)
                    }
                    .testID("showcase.theme.system")
                    .accessibilityLabel("Select system appearance")

                    Button("Light") { [weak self] in
                        self?.selectTheme(.light)
                    }
                    .testID("showcase.theme.light")
                    .accessibilityLabel("Select light theme")

                    Button("Dark") { [weak self] in
                        self?.selectTheme(.dark)
                    }
                    .testID("showcase.theme.dark")
                    .accessibilityLabel("Select dark theme")

                    Button("Midnight") { [weak self] in
                        self?.selectTheme(.midnight)
                    }
                    .testID("showcase.theme.midnight")
                    .accessibilityLabel("Select midnight theme")

                    Button("Forest") { [weak self] in
                        self?.selectTheme(.forest)
                    }
                    .testID("showcase.theme.forest")
                    .accessibilityLabel("Select forest theme")

                    Button("Sand") { [weak self] in
                        self?.selectTheme(.sand)
                    }
                    .testID("showcase.theme.sand")
                    .accessibilityLabel("Select sand theme")
                }
            }

            // Counter Fixture
            HStack(spacing: 12) {
                Text("Counter: \(current.count)")
                    .foregroundColor(colors.foreground)
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
                    .foregroundColor(colors.foreground)
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
                        .foregroundColor(colors.foreground)
                        .testID("showcase.submitted_display")
                }
            }

            // Scroll Fixture
            VStack(alignment: .start, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Scroll offset: \(Int(current.scrollOffset))")
                        .foregroundColor(colors.foreground)
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
                                .foregroundColor(colors.foreground)
                                .testID("showcase.scroll_item_\(i)")
                        }
                    }
                }
                .testID("showcase.scroll_area")
                .height(100)
            }
        }
        .padding(24)
        .background(colors.background)
        .render()
    }
}

/// Backwards compatibility alias for the initial Phase 07 prototype store.
public typealias ShowcaseCounterStore = ShowcaseStore
