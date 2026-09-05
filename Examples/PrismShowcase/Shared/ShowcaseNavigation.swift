import Foundation
import CoreGraphics
import PrismUI

/// The 7 canonical categories defined by the Showcase Contract.
public enum ShowcaseCategory: String, CaseIterable, Sendable, Identifiable {
    case foundations = "foundations"
    case dataDisplay = "data-display"
    case forms = "forms"
    case feedbackAndOverlays = "feedback-overlays"
    case navigation = "navigation"
    case layoutAndCollections = "layout-collections"
    case advancedData = "advanced-data"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .foundations: return "Foundations"
        case .dataDisplay: return "Data Display"
        case .forms: return "Forms"
        case .feedbackAndOverlays: return "Feedback & Overlays"
        case .navigation: return "Navigation"
        case .layoutAndCollections: return "Layout & Collections"
        case .advancedData: return "Advanced Data"
        }
    }

    public var description: String {
        switch self {
        case .foundations: return "Core primitives, typography, shapes, and tokens."
        case .dataDisplay: return "Badges, labels, avatars, cards, code blocks, and tables."
        case .forms: return "Buttons, inputs, toggles, selectors, and field validation."
        case .feedbackAndOverlays: return "Alerts, toasts, dialogs, drawers, popovers, and menus."
        case .navigation: return "Tabs, breadcrumbs, pagers, menus, and command palettes."
        case .layoutAndCollections: return "Grids, containers, scroll areas, and virtualization."
        case .advancedData: return "Data grids, calendars, trees, charts, and boards."
        }
    }

    public var iconSymbol: String {
        switch self {
        case .foundations: return "cube"
        case .dataDisplay: return "list.bullet.rectangle"
        case .forms: return "square.and.pencil"
        case .feedbackAndOverlays: return "bubble.left.and.bubble.right"
        case .navigation: return "arrow.triangle.branch"
        case .layoutAndCollections: return "rectangle.split.3x3"
        case .advancedData: return "chart.bar.xaxis"
        }
    }
}

/// Typed, stable routes for showcase navigation.
public enum ShowcaseRoute: Equatable, Hashable, Sendable {
    case welcome
    case categories
    case category(ShowcaseCategory)
    case component(id: String)
    case notFound(id: String)

    public var pathString: String {
        switch self {
        case .welcome: return "welcome"
        case .categories: return "categories"
        case .category(let cat): return "category/\(cat.rawValue)"
        case .component(let id): return "component/\(id)"
        case .notFound(let id): return "not-found/\(id)"
        }
    }

    public static func parse(path: String) -> ShowcaseRoute {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "welcome" {
            return .welcome
        }
        if trimmed == "categories" {
            return .categories
        }
        if trimmed == "counter" {
            return .component(id: "counter")
        }
        if trimmed.hasPrefix("category/") {
            let catID = String(trimmed.dropFirst("category/".count))
            if let category = ShowcaseCategory(rawValue: catID) {
                return .category(category)
            }
            return .notFound(id: catID)
        }
        if trimmed.hasPrefix("component/") {
            let compID = String(trimmed.dropFirst("component/".count))
            if ShowcaseRegistry.item(for: compID) != nil {
                return .component(id: compID)
            }
            return .notFound(id: compID)
        }
        if let category = ShowcaseCategory(rawValue: trimmed) {
            return .category(category)
        }
        if ShowcaseRegistry.item(for: trimmed) != nil {
            return .component(id: trimmed)
        }
        return .notFound(id: trimmed)
    }
}

/// Metadata describing one catalog component item.
public struct ShowcaseComponentItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let category: ShowcaseCategory
    public let summary: String
    public let states: [String]
    public let isInteractive: Bool

    public init(
        id: String,
        name: String,
        category: ShowcaseCategory,
        summary: String,
        states: [String] = ["default", "interactive"],
        isInteractive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.summary = summary
        self.states = states
        self.isInteractive = isInteractive
    }
}

/// Comprehensive registry of all audited components organized by the 7 categories.
public enum ShowcaseRegistry {
    public static let allCategories: [ShowcaseCategory] = ShowcaseCategory.allCases

    public static let allItems: [ShowcaseComponentItem] = [
        // Foundations
        ShowcaseComponentItem(id: "text", name: "Text", category: .foundations, summary: "Core typography primitive supporting roles and weights.", states: ["body", "heading", "display", "mono"]),
        ShowcaseComponentItem(id: "stack", name: "Stack", category: .foundations, summary: "Directional layout primitive with spacing and alignment.", states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "spacer", name: "Spacer", category: .foundations, summary: "Flexible space consumer expanding along parent axis.", states: ["flexible", "fixed"]),
        ShowcaseComponentItem(id: "rectangle", name: "Rectangle", category: .foundations, summary: "Geometric shape primitive with radius and fills.", states: ["filled", "stroked", "rounded"]),
        ShowcaseComponentItem(id: "circle", name: "Circle", category: .foundations, summary: "Circular geometric shape primitive.", states: ["filled", "stroked"]),
        ShowcaseComponentItem(id: "icon", name: "Icon", category: .foundations, summary: "Vector and symbol rendering primitive.", states: ["regular", "large", "colored"]),
        ShowcaseComponentItem(id: "image", name: "Image", category: .foundations, summary: "Asynchronous image rendering with content modes.", states: ["loaded", "loading", "placeholder"]),
        ShowcaseComponentItem(id: "tokens", name: "Theme Tokens", category: .foundations, summary: "Semantic color, typography, radius, and spacing tokens.", states: ["light", "dark", "midnight", "forest", "sand"]),

        // Data Display
        ShowcaseComponentItem(id: "badge", name: "Badge", category: .dataDisplay, summary: "Status and metadata indicator badge.", states: ["default", "success", "warning", "destructive"]),
        ShowcaseComponentItem(id: "label", name: "Label", category: .dataDisplay, summary: "Icon and text pair for labels and menu items.", states: ["leading", "trailing"]),
        ShowcaseComponentItem(id: "avatar", name: "Avatar", category: .dataDisplay, summary: "Image or initials display with fallback.", states: ["image", "initials", "fallback"]),
        ShowcaseComponentItem(id: "card", name: "Card", category: .dataDisplay, summary: "Container for grouped content with header, body, and footer.", states: ["elevated", "outlined", "interactive"]),
        ShowcaseComponentItem(id: "icontile", name: "IconTile", category: .dataDisplay, summary: "Tiled icon representation with optional label.", states: ["standard", "prominent"]),
        ShowcaseComponentItem(id: "codeblock", name: "CodeBlock", category: .dataDisplay, summary: "Syntax-highlighted monospace code snippet viewer.", states: ["swift", "json", "lineNumbers"]),
        ShowcaseComponentItem(id: "kbd", name: "Kbd", category: .dataDisplay, summary: "Keyboard shortcut and keycap badge display.", states: ["single", "combination"]),
        ShowcaseComponentItem(id: "skeleton", name: "Skeleton", category: .dataDisplay, summary: "Animated shimmer loading placeholder.", states: ["text", "circular", "card"]),
        ShowcaseComponentItem(id: "empty", name: "Empty", category: .dataDisplay, summary: "Empty state view with title, description, and action.", states: ["default", "withAction"]),
        ShowcaseComponentItem(id: "table", name: "Table", category: .dataDisplay, summary: "Tabular data presentation with column headers.", states: ["standard", "striped", "bordered"]),
        ShowcaseComponentItem(id: "timeline", name: "Timeline", category: .dataDisplay, summary: "Chronological event timeline presentation.", states: ["completed", "inProgress", "pending"]),

        // Forms
        ShowcaseComponentItem(id: "counter", name: "Counter", category: .forms, summary: "Interactive counter, input, and scroll test playground.", states: ["zero", "positive", "submitted"]),
        ShowcaseComponentItem(id: "button", name: "Button", category: .forms, summary: "Interactive tap target with variants, sizes, and states.", states: ["primary", "secondary", "outline", "ghost", "destructive", "disabled"]),
        ShowcaseComponentItem(id: "input", name: "Input", category: .forms, summary: "Single-line text entry with label and validation.", states: ["default", "focused", "error", "disabled"]),
        ShowcaseComponentItem(id: "textarea", name: "Textarea", category: .forms, summary: "Multi-line text entry area.", states: ["default", "withScroll", "disabled"]),
        ShowcaseComponentItem(id: "checkbox", name: "Checkbox", category: .forms, summary: "Binary or indeterminate toggle checkbox.", states: ["checked", "unchecked", "indeterminate", "disabled"]),
        ShowcaseComponentItem(id: "radiogroup", name: "RadioGroup", category: .forms, summary: "Mutually exclusive single-choice option set.", states: ["selected", "unselected", "disabled"]),
        ShowcaseComponentItem(id: "switch", name: "Switch", category: .forms, summary: "Binary state toggle switch.", states: ["on", "off", "disabled"]),
        ShowcaseComponentItem(id: "toggle", name: "Toggle", category: .forms, summary: "Stateful toggle button.", states: ["pressed", "unpressed"]),
        ShowcaseComponentItem(id: "field", name: "Field", category: .forms, summary: "Labeled form field wrapper with validation message.", states: ["valid", "error", "required"]),
        ShowcaseComponentItem(id: "form", name: "Form", category: .forms, summary: "Structured form container with submission lifecycle.", states: ["clean", "dirty", "submitting"]),
        ShowcaseComponentItem(id: "buttongroup", name: "ButtonGroup", category: .forms, summary: "Connected group of buttons with unified border.", states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "numberfield", name: "NumberField", category: .forms, summary: "Numeric text field with step and boundary clamping.", states: ["valid", "clamped", "disabled"]),
        ShowcaseComponentItem(id: "togglegroup", name: "ToggleGroup", category: .forms, summary: "Multi-select or single-select group of toggles.", states: ["single", "multiple"]),
        ShowcaseComponentItem(id: "slider", name: "Slider", category: .forms, summary: "Continuous or stepped value slider.", states: ["minimum", "middle", "maximum", "disabled"]),
        ShowcaseComponentItem(id: "rangeslider", name: "RangeSlider", category: .forms, summary: "Dual-thumb range selection slider.", states: ["standard", "bounded"]),
        ShowcaseComponentItem(id: "stepper", name: "Stepper", category: .forms, summary: "Incremental step controller.", states: ["active", "disabled"]),
        ShowcaseComponentItem(id: "rating", name: "Rating", category: .forms, summary: "Star or score rating selector.", states: ["zero", "partial", "full"]),
        ShowcaseComponentItem(id: "select", name: "Select", category: .forms, summary: "Dropdown selection menu with custom options.", states: ["closed", "open", "selected"]),
        ShowcaseComponentItem(id: "nativeselect", name: "NativeSelect", category: .forms, summary: "Host-native popup or picker button.", states: ["default", "disabled"]),
        ShowcaseComponentItem(id: "combobox", name: "Combobox", category: .forms, summary: "Searchable combo box with filtered suggestions.", states: ["idle", "suggesting", "selected"]),
        ShowcaseComponentItem(id: "dateselector", name: "DateSelector", category: .forms, summary: "Date picker and calendar dropdown trigger.", states: ["collapsed", "expanded"]),
        ShowcaseComponentItem(id: "phoneinput", name: "PhoneInput", category: .forms, summary: "Formatted international telephone input.", states: ["formatted", "invalid"]),
        ShowcaseComponentItem(id: "inputotp", name: "InputOtp", category: .forms, summary: "Segmented one-time password code input.", states: ["empty", "partial", "complete"]),
        ShowcaseComponentItem(id: "fileupload", name: "FileUpload", category: .forms, summary: "File picker and drop target indicator.", states: ["idle", "dragging", "uploaded"]),

        // Feedback & Overlays
        ShowcaseComponentItem(id: "alert", name: "Alert", category: .feedbackAndOverlays, summary: "In-line callout banner with status iconography.", states: ["info", "success", "warning", "destructive"]),
        ShowcaseComponentItem(id: "spinner", name: "Spinner", category: .feedbackAndOverlays, summary: "Indeterminate loading activity indicator.", states: ["spinning", "small", "large"]),
        ShowcaseComponentItem(id: "progress", name: "Progress", category: .feedbackAndOverlays, summary: "Determinate or indeterminate progress bar.", states: ["zero", "fifty", "hundred"]),
        ShowcaseComponentItem(id: "toast", name: "Toast", category: .feedbackAndOverlays, summary: "Transient notification toast with dismiss action.", states: ["queued", "visible", "dismissed"]),
        ShowcaseComponentItem(id: "dialog", name: "Dialog", category: .feedbackAndOverlays, summary: "Modal dialog overlay with backdrop and focus trap.", states: ["hidden", "visible"]),
        ShowcaseComponentItem(id: "tooltip", name: "Tooltip", category: .feedbackAndOverlays, summary: "Hover and focus informational tooltip.", states: ["idle", "hovered"]),
        ShowcaseComponentItem(id: "hovercard", name: "HoverCard", category: .feedbackAndOverlays, summary: "Rich popover triggered by hover intent.", states: ["idle", "preview"]),
        ShowcaseComponentItem(id: "sheet", name: "Sheet", category: .feedbackAndOverlays, summary: "Bottom or side drawer sheet modal.", states: ["collapsed", "expanded"]),
        ShowcaseComponentItem(id: "drawer", name: "Drawer", category: .feedbackAndOverlays, summary: "Slide-out navigation and content drawer.", states: ["leading", "trailing"]),
        ShowcaseComponentItem(id: "popover", name: "Popover", category: .feedbackAndOverlays, summary: "Anchored floating popover with arrow.", states: ["anchorTop", "anchorBottom"]),
        ShowcaseComponentItem(id: "dropdownmenu", name: "DropdownMenu", category: .feedbackAndOverlays, summary: "Contextual drop-down action menu.", states: ["closed", "opened"]),
        ShowcaseComponentItem(id: "contextmenu", name: "ContextMenu", category: .feedbackAndOverlays, summary: "Right-click or long-press contextual menu.", states: ["idle", "presented"]),

        // Navigation
        ShowcaseComponentItem(id: "tabs", name: "Tabs", category: .navigation, summary: "Segmented tab bar switching content views.", states: ["horizontal", "vertical", "selected"]),
        ShowcaseComponentItem(id: "breadcrumb", name: "Breadcrumb", category: .navigation, summary: "Hierarchical page location breadcrumb trail.", states: ["single", "nested", "active"]),
        ShowcaseComponentItem(id: "pagination", name: "Pagination", category: .navigation, summary: "Multi-page index and next/previous controls.", states: ["firstPage", "midPage", "lastPage"]),
        ShowcaseComponentItem(id: "navigationmenu", name: "NavigationMenu", category: .navigation, summary: "Header navigation bar with nested sub-menus.", states: ["horizontal", "activeItem"]),
        ShowcaseComponentItem(id: "menubar", name: "Menubar", category: .navigation, summary: "Desktop application menu bar.", states: ["standard", "itemHighlighted"]),
        ShowcaseComponentItem(id: "commandpalette", name: "CommandPalette", category: .navigation, summary: "Search-driven command palette with fuzzy filtering.", states: ["closed", "searchActive"]),

        // Layout & Collections
        ShowcaseComponentItem(id: "frame", name: "Frame", category: .layoutAndCollections, summary: "Constrained dimensional frame layout.", states: ["fixed", "minMax"]),
        ShowcaseComponentItem(id: "divider", name: "Divider", category: .layoutAndCollections, summary: "Visual separation line with optional label.", states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "aspectratio", name: "AspectRatio", category: .layoutAndCollections, summary: "Aspect ratio enforcer for media and cards.", states: ["sixteenByNine", "square", "fourByThree"]),
        ShowcaseComponentItem(id: "grid", name: "Grid", category: .layoutAndCollections, summary: "Column and row matrix grid container.", states: ["twoCol", "threeCol", "autoFit"]),
        ShowcaseComponentItem(id: "scrollarea", name: "ScrollArea", category: .layoutAndCollections, summary: "Scrollable viewport with custom scroll indicators.", states: ["vertical", "horizontal", "both"]),
        ShowcaseComponentItem(id: "responsivecontainer", name: "ResponsiveContainer", category: .layoutAndCollections, summary: "Adaptive layout switching based on container width.", states: ["compact", "medium", "expanded", "wide"]),
        ShowcaseComponentItem(id: "scaffold", name: "Scaffold", category: .layoutAndCollections, summary: "Screen scaffold with app bar, body, and bottom bar.", states: ["standard", "withDrawer"]),
        ShowcaseComponentItem(id: "accordion", name: "Accordion", category: .layoutAndCollections, summary: "Vertically stacked expandable disclosure panels.", states: ["collapsed", "expanded", "multiple"]),
        ShowcaseComponentItem(id: "collapsible", name: "Collapsible", category: .layoutAndCollections, summary: "Single disclosure panel with animated height.", states: ["closed", "opened"]),
        ShowcaseComponentItem(id: "resizable", name: "Resizable", category: .layoutAndCollections, summary: "Draggable split pane container.", states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "sortable", name: "Sortable", category: .layoutAndCollections, summary: "Drag-and-drop sortable collection.", states: ["idle", "dragging"]),
        ShowcaseComponentItem(id: "lazylist", name: "LazyList", category: .layoutAndCollections, summary: "Virtualized scrollable list recycling off-screen items.", states: ["virtualized", "largeDataset"]),
        ShowcaseComponentItem(id: "lazygrid", name: "LazyGrid", category: .layoutAndCollections, summary: "Virtualized multi-column grid recycling cells.", states: ["virtualized", "largeDataset"]),

        // Advanced Data
        ShowcaseComponentItem(id: "tree", name: "Tree", category: .advancedData, summary: "Hierarchical tree view with expandable nodes.", states: ["collapsed", "expanded", "selected"]),
        ShowcaseComponentItem(id: "datagrid", name: "DataGrid", category: .advancedData, summary: "High-performance virtualized 2D data table.", states: ["sorted", "filtered", "scrolled"]),
        ShowcaseComponentItem(id: "filtereditor", name: "FilterEditor", category: .advancedData, summary: "Multi-rule structured filter builder.", states: ["empty", "withRules"]),
        ShowcaseComponentItem(id: "calendarview", name: "CalendarView", category: .advancedData, summary: "Month/week/day date calendar view.", states: ["month", "week", "day"]),
        ShowcaseComponentItem(id: "eventcalendar", name: "EventCalendar", category: .advancedData, summary: "Interactive calendar with scheduled events.", states: ["eventsLoaded", "eventSelected"]),
        ShowcaseComponentItem(id: "chart", name: "Chart", category: .advancedData, summary: "Data series charting and visualization.", states: ["bar", "line", "pie"]),
        ShowcaseComponentItem(id: "kanban", name: "Kanban", category: .advancedData, summary: "Columnar Kanban board with draggable cards.", states: ["todo", "inProgress", "done"]),
        ShowcaseComponentItem(id: "gantt", name: "Gantt", category: .advancedData, summary: "Project schedule Gantt chart with task dependencies.", states: ["timeline", "taskZoomed"])
    ]

    public static func items(for category: ShowcaseCategory) -> [ShowcaseComponentItem] {
        allItems.filter { $0.category == category }
    }

    public static func item(for id: String) -> ShowcaseComponentItem? {
        let lowered = id.lowercased()
        return allItems.first { $0.id.lowercased() == lowered }
    }

    public static func search(query: String) -> [ShowcaseComponentItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return allItems }
        return allItems.filter {
            $0.name.lowercased().contains(trimmed) ||
            $0.id.lowercased().contains(trimmed) ||
            $0.category.title.lowercased().contains(trimmed) ||
            $0.summary.lowercased().contains(trimmed)
        }
    }

    public static func categoryCount(for category: ShowcaseCategory) -> Int {
        items(for: category).count
    }
}

/// Navigation state snapshot tracking active route stack, selected items, search, and container dimensions.
public struct ShowcaseNavigationState: Equatable, Sendable {
    public var routeStack: [ShowcaseRoute]
    public var selectedCategory: ShowcaseCategory?
    public var selectedComponentID: String?
    public var searchQuery: String
    public var scrollOffsets: [String: Double]
    public var containerWidth: CGFloat
    public var breakpoint: Breakpoint

    public var currentRoute: ShowcaseRoute {
        routeStack.last ?? .welcome
    }

    public var isRoot: Bool {
        routeStack.count <= 1
    }

    public init(
        initialRoute: ShowcaseRoute = .welcome,
        containerWidth: CGFloat = 800.0
    ) {
        self.routeStack = [initialRoute]
        self.selectedCategory = nil
        self.selectedComponentID = nil
        self.searchQuery = ""
        self.scrollOffsets = [:]
        self.containerWidth = containerWidth
        self.breakpoint = Breakpoint.from(width: containerWidth)

        switch initialRoute {
        case .category(let cat):
            self.selectedCategory = cat
        case .component(let id):
            self.selectedComponentID = id
            if let item = ShowcaseRegistry.item(for: id) {
                self.selectedCategory = item.category
            }
        default:
            break
        }
    }

    /// Pushes a new route onto the stack, deduplicating identical consecutive requests.
    public mutating func push(route: ShowcaseRoute) {
        guard route != currentRoute else { return }
        routeStack.append(route)
        switch route {
        case .category(let cat):
            selectedCategory = cat
        case .component(let id):
            selectedComponentID = id
            if let item = ShowcaseRegistry.item(for: id) {
                selectedCategory = item.category
            }
        case .welcome, .categories:
            break
        case .notFound:
            break
        }
    }

    /// Pops the top route from the stack if not at root, restoring previous context.
    @discardableResult
    public mutating func pop() -> ShowcaseRoute? {
        guard routeStack.count > 1 else { return nil }
        let popped = routeStack.removeLast()
        if let current = routeStack.last {
            switch current {
            case .category(let cat):
                selectedCategory = cat
            case .component(let id):
                selectedComponentID = id
                if let item = ShowcaseRegistry.item(for: id) {
                    selectedCategory = item.category
                }
            case .categories:
                selectedComponentID = nil
            case .welcome:
                selectedCategory = nil
                selectedComponentID = nil
            case .notFound:
                break
            }
        }
        return popped
    }

    public mutating func setSearchQuery(_ query: String) {
        self.searchQuery = query
    }

    public mutating func clearSearch() {
        self.searchQuery = ""
    }

    public mutating func setScrollOffset(_ offset: Double, for key: String) {
        scrollOffsets[key] = max(0.0, offset)
    }

    public func scrollOffset(for key: String) -> Double {
        scrollOffsets[key] ?? 0.0
    }

    public mutating func setContainerWidth(_ width: CGFloat) {
        self.containerWidth = width
        self.breakpoint = Breakpoint.from(width: width)
    }
}
