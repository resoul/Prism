import Foundation
import CoreGraphics
import PrismUI

/// Top-level adaptive container rendering either sequential or split layout depending on viewport width.
public struct ShowcaseAdaptiveRootView: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let searchBinding: Binding<String>
    public let inputBinding: Binding<String>
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        searchBinding: Binding<String>,
        inputBinding: Binding<String>,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.searchBinding = searchBinding
        self.inputBinding = inputBinding
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let nav = state.navigation
        let colors = theme.colors
        let isCompact = nav.breakpoint.isCompact

        return VStack(alignment: .stretch, spacing: 0) {
            // Global Toolbar
            ShowcaseGlobalToolbar(
                state: state,
                theme: theme,
                store: store
            )
            .testID("showcase.toolbar")

            // Main Content Area
            if isCompact {
                // Sequential single-screen navigation for iPhone / narrow windows
                ShowcaseSequentialView(
                    state: state,
                    theme: theme,
                    searchBinding: searchBinding,
                    inputBinding: inputBinding,
                    store: store
                )
            } else {
                // Adaptive split layout for macOS / iPad
                ShowcaseSplitView(
                    state: state,
                    theme: theme,
                    searchBinding: searchBinding,
                    inputBinding: inputBinding,
                    store: store
                )
            }
        }
        .background(colors.background)
        .render(in: context)
    }
}

/// Global top bar providing breadcrumb route status, theme switcher, and reset controls.
public struct ShowcaseGlobalToolbar: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors
        let nav = state.navigation
        let themeID = state.activeThemeID

        return HStack(alignment: .center, spacing: 12) {
            // Breadcrumb / App Title
            HStack(spacing: 8) {
                Text("Prism Showcase")
                    .font(.heading)
                    .foregroundColor(colors.foreground)
                    .testID("showcase.title")

                Text("·")
                    .foregroundColor(colors.mutedForeground)

                Text(breadcrumbTitle(for: nav.currentRoute))
                    .font(.body)
                    .foregroundColor(colors.mutedForeground)
                    .testID("showcase.route.status")
            }

            Spacer()

            // Theme preset quick-selector
            HStack(spacing: 4) {
                Button("System") { [weak store] in
                    store?.selectTheme(.system)
                }
                .testID("showcase.theme.system")
                .accessibilityLabel("System appearance")

                Button("Light") { [weak store] in
                    store?.selectTheme(.light)
                }
                .testID("showcase.theme.light")
                .accessibilityLabel("Light theme")

                Button("Dark") { [weak store] in
                    store?.selectTheme(.dark)
                }
                .testID("showcase.theme.dark")
                .accessibilityLabel("Dark theme")

                Button("Midnight") { [weak store] in
                    store?.selectTheme(.midnight)
                }
                .testID("showcase.theme.midnight")
                .accessibilityLabel("Midnight theme")

                Button("Forest") { [weak store] in
                    store?.selectTheme(.forest)
                }
                .testID("showcase.theme.forest")
                .accessibilityLabel("Forest theme")

                Button("Sand") { [weak store] in
                    store?.selectTheme(.sand)
                }
                .testID("showcase.theme.sand")
                .accessibilityLabel("Sand theme")
            }

            Text("[\(themeID.rawValue)]")
                .font(.mono)
                .foregroundColor(colors.mutedForeground)
                .testID("showcase.theme.status")
        }
        .padding(12)
        .background(colors.muted)
        .render(in: context)
    }

    private func breadcrumbTitle(for route: ShowcaseRoute) -> String {
        switch route {
        case .welcome:
            return "Welcome"
        case .categories:
            return "Categories"
        case .category(let cat):
            return "Categories > \(cat.title)"
        case .component(let id):
            let name = ShowcaseRegistry.item(for: id)?.name ?? id.capitalized
            return "Detail > \(name)"
        case .notFound(let id):
            return "Not Found > \(id)"
        }
    }
}

/// Sequential navigation container displaying one screen at a time with back button.
public struct ShowcaseSequentialView: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let searchBinding: Binding<String>
    public let inputBinding: Binding<String>
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        searchBinding: Binding<String>,
        inputBinding: Binding<String>,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.searchBinding = searchBinding
        self.inputBinding = inputBinding
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let nav = state.navigation
        switch nav.currentRoute {
        case .welcome:
            return ShowcaseWelcomeScreen(state: state, theme: theme, store: store).render(in: context)
        case .categories:
            return ShowcaseCategoriesScreen(state: state, theme: theme, searchBinding: searchBinding, store: store).render(in: context)
        case .category(let cat):
            return ShowcaseComponentListScreen(state: state, theme: theme, category: cat, store: store).render(in: context)
        case .component(let id):
            if let item = ShowcaseRegistry.item(for: id) {
                return ShowcaseDetailScreen(state: state, theme: theme, item: item, inputBinding: inputBinding, store: store).render(in: context)
            } else {
                return ShowcaseNotFoundScreen(state: state, theme: theme, requestedID: id, store: store).render(in: context)
            }
        case .notFound(let id):
            return ShowcaseNotFoundScreen(state: state, theme: theme, requestedID: id, store: store).render(in: context)
        }
    }
}

/// Responsive split container with sidebar and detail pane for wide screens.
public struct ShowcaseSplitView: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let searchBinding: Binding<String>
    public let inputBinding: Binding<String>
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        searchBinding: Binding<String>,
        inputBinding: Binding<String>,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.searchBinding = searchBinding
        self.inputBinding = inputBinding
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors
        let nav = state.navigation

        return HStack(alignment: .start, spacing: 0) {
            // Sidebar Pane
            VStack(alignment: .stretch, spacing: 12) {
                // Sidebar Header / Welcome Link
                HStack(spacing: 8) {
                    Button("← Welcome") { [weak store] in
                        store?.navigate(to: .welcome)
                    }
                    .testID("showcase.sidebar.welcome")

                    Button("All Categories") { [weak store] in
                        store?.navigate(to: .categories)
                    }
                    .testID("showcase.sidebar.categories")
                }

                // Search Box
                HStack(spacing: 6) {
                    Input("Search components...", text: searchBinding)
                        .testID("showcase.search.input")
                        .accessibilityLabel("Search components")

                    if !nav.searchQuery.isEmpty {
                        Button("✕") { [weak store] in
                            store?.clearSearch()
                        }
                        .testID("showcase.search.clear")
                        .accessibilityLabel("Clear search")
                    }
                }

                // Navigation list (Categories or Filtered search)
                ScrollArea(.vertical) {
                    VStack(alignment: .stretch, spacing: 6) {
                        if !nav.searchQuery.isEmpty {
                            let results = ShowcaseRegistry.search(query: nav.searchQuery)
                            if results.isEmpty {
                                Text("No matches for '\(nav.searchQuery)'")
                                    .font(.body)
                                    .foregroundColor(colors.mutedForeground)
                                    .testID("showcase.search.empty")
                            } else {
                                for item in results {
                                    Button("\(item.name) (\(item.category.title))") { [weak store] in
                                        store?.selectComponent(item.id)
                                    }
                                    .testID("showcase.search.result.\(item.id)")
                                }
                            }
                        } else {
                            // Category buttons
                            for cat in ShowcaseCategory.allCases {
                                let count = ShowcaseRegistry.categoryCount(for: cat)
                                Button("\(cat.title) (\(count))") { [weak store] in
                                    store?.selectCategory(cat)
                                }
                                .testID("showcase.sidebar.category.\(cat.rawValue)")
                            }

                            if let selectedCat = nav.selectedCategory {
                                Divider()
                                Text("\(selectedCat.title) Components")
                                    .font(.heading)
                                    .foregroundColor(colors.foreground)

                                for item in ShowcaseRegistry.items(for: selectedCat) {
                                    Button(item.name) { [weak store] in
                                        store?.selectComponent(item.id)
                                    }
                                    .testID("showcase.sidebar.component.\(item.id)")
                                }
                            }
                        }
                    }
                }
                .testID("showcase.sidebar.scroll")
            }
            .padding(16)
            .width(280)
            .background(colors.muted)

            // Vertical Divider
            Divider()

            // Detail Content Pane
            VStack(alignment: .stretch, spacing: 0) {
                switch nav.currentRoute {
                case .welcome:
                    ShowcaseWelcomeScreen(state: state, theme: theme, store: store)
                case .categories:
                    ShowcaseCategoriesScreen(state: state, theme: theme, searchBinding: searchBinding, store: store)
                case .category(let cat):
                    ShowcaseComponentListScreen(state: state, theme: theme, category: cat, store: store)
                case .component(let id):
                    if let item = ShowcaseRegistry.item(for: id) {
                        ShowcaseDetailScreen(state: state, theme: theme, item: item, inputBinding: inputBinding, store: store)
                    } else {
                        ShowcaseNotFoundScreen(state: state, theme: theme, requestedID: id, store: store)
                    }
                case .notFound(let id):
                    ShowcaseNotFoundScreen(state: state, theme: theme, requestedID: id, store: store)
                }
            }
        }
        .render(in: context)
    }
}

/// The Welcome Screen presenting the Prism showcase introduction, quick theme options, and category entry point.
public struct ShowcaseWelcomeScreen: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors

        return ScrollArea(.vertical) {
            VStack(alignment: .start, spacing: 20) {
                // Header & Brand
                VStack(alignment: .start, spacing: 8) {
                    Text("Prism Showcase")
                        .font(.display)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.title")

                    Text("Declarative UI Framework for Apple Platforms")
                        .font(.heading)
                        .foregroundColor(colors.primary)
                        .testID("showcase.welcome.subtitle")

                    Text("Explore components, deterministic state integration, and theme presets across iOS and macOS with native CALayer hosting.")
                        .font(.body)
                        .foregroundColor(colors.mutedForeground)
                        .testID("showcase.welcome.description")
                }

                // Primary Call to Action
                HStack(spacing: 12) {
                    Button("Browse Components") { [weak store] in
                        store?.navigate(to: .categories)
                    }
                    .testID("showcase.welcome.browse")
                    .accessibilityLabel("Browse component categories")

                    Button("Open Counter Playground") { [weak store] in
                        store?.navigate(to: .component(id: "counter"))
                    }
                    .testID("showcase.welcome.counter")
                    .accessibilityLabel("Open interactive counter playground")
                }

                Divider()

                // Theme Presets Section
                VStack(alignment: .start, spacing: 10) {
                    Text("Theme Presets")
                        .font(.heading)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.welcome.theme.title")

                    Text("Switch themes dynamically. Mounted UI adapts immediately with zero loss of state.")
                        .font(.body)
                        .foregroundColor(colors.mutedForeground)

                    HStack(spacing: 8) {
                        Button("System") { [weak store] in store?.selectTheme(.system) }
                            .testID("showcase.welcome.theme.system")

                        Button("Light") { [weak store] in store?.selectTheme(.light) }
                            .testID("showcase.welcome.theme.light")

                        Button("Dark") { [weak store] in store?.selectTheme(.dark) }
                            .testID("showcase.welcome.theme.dark")

                        Button("Midnight") { [weak store] in store?.selectTheme(.midnight) }
                            .testID("showcase.welcome.theme.midnight")

                        Button("Forest") { [weak store] in store?.selectTheme(.forest) }
                            .testID("showcase.welcome.theme.forest")

                        Button("Sand") { [weak store] in store?.selectTheme(.sand) }
                            .testID("showcase.welcome.theme.sand")
                    }
                }

                Divider()

                // Category Summary Grid
                VStack(alignment: .start, spacing: 12) {
                    Text("Categories (\(ShowcaseCategory.allCases.count) total, \(ShowcaseRegistry.allItems.count) components)")
                        .font(.heading)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.welcome.categories_header")

                    for category in ShowcaseCategory.allCases {
                        let count = ShowcaseRegistry.categoryCount(for: category)
                        HStack(spacing: 12) {
                            Text(category.title)
                                .font(.body)
                                .foregroundColor(colors.foreground)
                                .testID("showcase.welcome.category.\(category.rawValue)")

                            Text("(\(count) components)")
                                .font(.body)
                                .foregroundColor(colors.mutedForeground)

                            Spacer()

                            Button("Explore") { [weak store] in
                                store?.navigate(to: .category(category))
                            }
                            .testID("showcase.welcome.explore.\(category.rawValue)")
                        }
                        .padding(8)
                        .background(colors.muted)
                    }
                }
            }
            .padding(24)
        }
        .render(in: context)
    }
}

/// The Categories Screen showing the 7 categories and global search.
public struct ShowcaseCategoriesScreen: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let searchBinding: Binding<String>
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        searchBinding: Binding<String>,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.searchBinding = searchBinding
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors
        let nav = state.navigation

        return ScrollArea(.vertical) {
            VStack(alignment: .stretch, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Button("← Back") { [weak store] in
                        store?.pop()
                    }
                    .testID("showcase.navigation.back")
                    .accessibilityLabel("Back to previous screen")

                    Text("Component Categories")
                        .font(.heading)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.categories.title")

                    Spacer()
                }

                // Search Bar
                HStack(spacing: 8) {
                    Input("Search components or categories...", text: searchBinding)
                        .testID("showcase.search.input")
                        .accessibilityLabel("Search components or categories")

                    if !nav.searchQuery.isEmpty {
                        Button("Clear") { [weak store] in
                            store?.clearSearch()
                        }
                        .testID("showcase.search.clear")
                        .accessibilityLabel("Clear search filter")
                    }
                }

                // Search Results or Category Cards
                if !nav.searchQuery.isEmpty {
                    let results = ShowcaseRegistry.search(query: nav.searchQuery)
                    if results.isEmpty {
                        VStack(alignment: .center, spacing: 12) {
                            Text("No components found matching '\(nav.searchQuery)'")
                                .font(.body)
                                .foregroundColor(colors.mutedForeground)
                                .testID("showcase.search.empty")

                            Button("Clear Query") { [weak store] in
                                store?.clearSearch()
                            }
                            .testID("showcase.search.empty_clear")
                        }
                        .padding(32)
                    } else {
                        VStack(alignment: .stretch, spacing: 8) {
                            Text("Results (\(results.count)):")
                                .font(.body)
                                .foregroundColor(colors.mutedForeground)

                            for item in results {
                                HStack(spacing: 12) {
                                    VStack(alignment: .start, spacing: 2) {
                                        Text(item.name)
                                            .font(.body)
                                            .foregroundColor(colors.foreground)
                                        Text(item.category.title)
                                            .font(.mono)
                                            .foregroundColor(colors.mutedForeground)
                                    }

                                    Spacer()

                                    Button("View") { [weak store] in
                                        store?.navigate(to: .component(id: item.id))
                                    }
                                    .testID("showcase.search.view.\(item.id)")
                                }
                                .padding(10)
                                .background(colors.muted)
                            }
                        }
                    }
                } else {
                    // Category Cards
                    VStack(alignment: .stretch, spacing: 12) {
                        for category in ShowcaseCategory.allCases {
                            let count = ShowcaseRegistry.categoryCount(for: category)
                            VStack(alignment: .start, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(category.title)
                                        .font(.heading)
                                        .foregroundColor(colors.foreground)
                                        .testID("showcase.category.title.\(category.rawValue)")

                                    Spacer()

                                    Text("\(count) components")
                                        .font(.mono)
                                        .foregroundColor(colors.mutedForeground)
                                        .testID("showcase.category.count.\(category.rawValue)")

                                    Button("Open") { [weak store] in
                                        store?.navigate(to: .category(category))
                                    }
                                    .testID("showcase.category.\(category.rawValue)")
                                    .accessibilityLabel("Open \(category.title) category")
                                }

                                Text(category.description)
                                    .font(.body)
                                    .foregroundColor(colors.mutedForeground)
                            }
                            .padding(14)
                            .background(colors.muted)
                        }
                    }
                }
            }
            .padding(20)
        }
        .render(in: context)
    }
}

/// The Component List Screen showing all items in a single category.
public struct ShowcaseComponentListScreen: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let category: ShowcaseCategory
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        category: ShowcaseCategory,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.category = category
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors
        let items = ShowcaseRegistry.items(for: category)

        return ScrollArea(.vertical) {
            VStack(alignment: .stretch, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Button("← Back") { [weak store] in
                        store?.pop()
                    }
                    .testID("showcase.navigation.back")
                    .accessibilityLabel("Back to categories")

                    Text(category.title)
                        .font(.heading)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.category.title")

                    Spacer()

                    Text("\(items.count) components")
                        .font(.mono)
                        .foregroundColor(colors.mutedForeground)
                }

                Text(category.description)
                    .font(.body)
                    .foregroundColor(colors.mutedForeground)

                Divider()

                // Component Rows
                VStack(alignment: .stretch, spacing: 8) {
                    for item in items {
                        HStack(spacing: 12) {
                            VStack(alignment: .start, spacing: 4) {
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(colors.foreground)
                                    .testID("showcase.component.name.\(item.id)")

                                Text(item.summary)
                                    .font(.body)
                                    .foregroundColor(colors.mutedForeground)
                            }

                            Spacer()

                            Button("Detail") { [weak store] in
                                store?.navigate(to: .component(id: item.id))
                            }
                            .testID("showcase.component.\(item.id)")
                            .accessibilityLabel("Open \(item.name) detail")
                        }
                        .padding(12)
                        .background(colors.muted)
                    }
                }
            }
            .padding(20)
        }
        .render(in: context)
    }
}

/// The Component Detail Screen rendering the live interactive component or prototype fixture.
public struct ShowcaseDetailScreen: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let item: ShowcaseComponentItem
    public let inputBinding: Binding<String>
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        item: ShowcaseComponentItem,
        inputBinding: Binding<String>,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.item = item
        self.inputBinding = inputBinding
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors
        let current = state

        return ScrollArea(.vertical) {
            VStack(alignment: .start, spacing: 20) {
                // Header with Back and Title
                HStack(spacing: 12) {
                    Button("← Back") { [weak store] in
                        store?.pop()
                    }
                    .testID("showcase.navigation.back")
                    .accessibilityLabel("Back to list")

                    Text(item.name)
                        .font(.heading)
                        .foregroundColor(colors.foreground)
                        .testID("showcase.detail.title")

                    Text("[\(item.category.title)]")
                        .font(.mono)
                        .foregroundColor(colors.mutedForeground)
                        .testID("showcase.detail.category")

                    Spacer()

                    Button("Reset") { [weak store] in
                        store?.reset()
                    }
                    .testID("showcase.detail.reset")
                }

                Text(item.summary)
                    .font(.body)
                    .foregroundColor(colors.mutedForeground)

                Divider()

                // Special Case: "counter" fixture (prototype interactive tests)
                if item.id == "counter" {
                    // Counter Fixture
                    HStack(spacing: 12) {
                        Text("Counter: \(current.count)")
                            .foregroundColor(colors.foreground)
                            .testID("showcase.counter")

                        Button("Increment") { [weak store] in
                            store?.increment()
                        }
                        .testID("showcase.increment")
                        .accessibilityLabel("Increment counter")

                        Button("Decrement") { [weak store] in
                            store?.decrement()
                        }
                        .testID("showcase.decrement")
                        .accessibilityLabel("Decrement counter")

                        Button("Reset") { [weak store] in
                            store?.reset()
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

                            Button("Submit") { [weak store] in
                                store?.submitInput()
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

                            Button("Scroll Down") { [weak store] in
                                store?.scrollBy(20)
                            }
                            .testID("showcase.scroll_down")
                            .accessibilityLabel("Scroll down")

                            Button("Scroll Up") { [weak store] in
                                store?.scrollBy(-20)
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
                } else {
                    // Standard Component Playground Container
                    VStack(alignment: .stretch, spacing: 16) {
                        Text("Live Component Preview:")
                            .font(.body)
                            .foregroundColor(colors.mutedForeground)

                        // Render real component preview
                        VStack(alignment: .center, spacing: 12) {
                            switch item.id {
                            case "button":
                                HStack(spacing: 12) {
                                    Button("Primary Action") { [weak store] in store?.increment() }
                                        .testID("showcase.preview.button_primary")
                                    Button("Secondary Action") { }
                                }
                            case "badge":
                                HStack(spacing: 8) {
                                    Badge("Active").testID("showcase.preview.badge")
                                    Badge("Pending")
                                }
                            case "card":
                                Card {
                                    CardHeader { Text("Card Header") }
                                    CardContent { Text("Interactive showcase card body.") }
                                }
                                .testID("showcase.preview.card")
                            case "alert":
                                Alert(title: "Showcase Notice", description: "Demonstrating Alert component.")
                                    .testID("showcase.preview.alert")
                            default:
                                VStack(alignment: .start, spacing: 8) {
                                    Text("\(item.name) Preview")
                                        .font(.heading)
                                        .foregroundColor(colors.foreground)
                                    Text("Category: \(item.category.title)")
                                        .font(.mono)
                                        .foregroundColor(colors.mutedForeground)
                                    Text("States: \(item.states.joined(separator: ", "))")
                                        .font(.body)
                                        .foregroundColor(colors.mutedForeground)
                                }
                                .padding(16)
                                .background(colors.muted)
                            }
                        }
                        .padding(20)
                        .background(colors.muted)
                        .testID("showcase.preview.container")
                    }
                }
            }
            .padding(24)
        }
        .render(in: context)
    }
}

/// The Not Found Screen displaying a recoverable error state when an invalid route is requested.
public struct ShowcaseNotFoundScreen: Component {
    public let state: ShowcaseState
    public let theme: Theme
    public let requestedID: String
    public let store: ShowcaseStore?

    public init(
        state: ShowcaseState,
        theme: Theme,
        requestedID: String,
        store: ShowcaseStore?
    ) {
        self.state = state
        self.theme = theme
        self.requestedID = requestedID
        self.store = store
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = theme.colors

        return VStack(alignment: .center, spacing: 16) {
            Text("Component Not Found")
                .font(.heading)
                .foregroundColor(colors.destructive)
                .testID("showcase.not_found.title")

            Text("The requested component '\(requestedID)' does not exist in the showcase registry.")
                .font(.body)
                .foregroundColor(colors.mutedForeground)
                .testID("showcase.not_found.message")

            Button("Return to Categories") { [weak store] in
                store?.navigate(to: .categories)
            }
            .testID("showcase.not_found.return_button")
            .accessibilityLabel("Return to categories screen")
        }
        .padding(32)
        .testID("showcase.not_found")
        .render(in: context)
    }
}
