import Foundation
import PrismUI

/// Immutable state snapshot for the interactive showcase application.
public struct ShowcaseState: Equatable, Sendable {
    public var navigation: ShowcaseNavigationState
    public var count: Int
    public var inputText: String
    public var submittedText: String
    public var scrollOffset: Double
    public var themeSelection: ThemeSelection
    public var activeThemeID: ThemeID
    public var lastAction: String

    public init(
        navigation: ShowcaseNavigationState = ShowcaseNavigationState(),
        count: Int = 0,
        inputText: String = "",
        submittedText: String = "",
        scrollOffset: Double = 0.0,
        themeSelection: ThemeSelection = .system,
        activeThemeID: ThemeID = .light,
        lastAction: String = "none"
    ) {
        self.navigation = navigation
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

    public var currentRoute: ShowcaseRoute {
        _state.navigation.currentRoute
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
            let args = ProcessInfo.processInfo.arguments
            var initialRoute: ShowcaseRoute = .welcome
            if let routeIdx = args.firstIndex(of: "-showcaseRoute"), routeIdx + 1 < args.count {
                initialRoute = ShowcaseRoute.parse(path: args[routeIdx + 1])
            }
            self._state = ShowcaseState(
                navigation: ShowcaseNavigationState(initialRoute: initialRoute),
                themeSelection: initialSelection,
                activeThemeID: resolvedID
            )
        }
    }

    // MARK: - Navigation Actions

    public func navigate(to route: ShowcaseRoute) {
        guard route != _state.navigation.currentRoute else { return }
        var s = _state
        s.navigation.push(route: route)
        s.lastAction = "navigate(\(route.pathString))"
        update(s)
    }

    public func pop() {
        var s = _state
        if let popped = s.navigation.pop() {
            s.lastAction = "pop(\(popped.pathString))"
            update(s)
        }
    }

    public func selectCategory(_ category: ShowcaseCategory) {
        var s = _state
        s.navigation.selectedCategory = category
        s.navigation.push(route: .category(category))
        s.lastAction = "selectCategory(\(category.rawValue))"
        update(s)
    }

    public func selectComponent(_ id: String) {
        var s = _state
        s.navigation.selectedComponentID = id
        if ShowcaseRegistry.item(for: id) != nil {
            s.navigation.push(route: .component(id: id))
        } else {
            s.navigation.push(route: .notFound(id: id))
        }
        s.lastAction = "selectComponent(\(id))"
        update(s)
    }

    public func setSearchQuery(_ query: String) {
        var s = _state
        s.navigation.setSearchQuery(query)
        s.lastAction = "setSearchQuery(\(query))"
        update(s)
    }

    public func clearSearch() {
        var s = _state
        s.navigation.clearSearch()
        s.lastAction = "clearSearch"
        update(s)
    }

    public func setContainerWidth(_ width: CGFloat) {
        guard width > 0, width != _state.navigation.containerWidth else { return }
        var s = _state
        s.navigation.setContainerWidth(width)
        s.lastAction = "setContainerWidth(\(Int(width)))"
        update(s)
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

    // MARK: - Bindings

    public func searchBinding() -> Binding<String> {
        Binding<String>(
            get: { [weak self] in self?._state.navigation.searchQuery ?? "" },
            set: { [weak self] newValue in self?.setSearchQuery(newValue) }
        )
    }

    public func inputBinding() -> Binding<String> {
        Binding<String>(
            get: { [weak self] in self?._state.inputText ?? "" },
            set: { [weak self] newValue in self?.setInputText(newValue) }
        )
    }

    // MARK: - UI Construction

    public func rootElement() -> RenderElement {
        ShowcaseAdaptiveRootView(
            state: _state,
            theme: activeTheme,
            searchBinding: searchBinding(),
            inputBinding: inputBinding(),
            store: self
        ).render()
    }
}

/// Backwards compatibility alias for the initial Phase 07 prototype store.
public typealias ShowcaseCounterStore = ShowcaseStore
