import Foundation
import PrismCore

/// A selectable value displayed by `Select`, `NativeSelect`, and `ToggleGroup`.
public struct SelectionOption<Value: Hashable & Sendable>: Hashable, Sendable {
    public let value: Value
    public let label: String
    public var isDisabled: Bool

    public init(_ value: Value, label: String, isDisabled: Bool = false) {
        self.value = value
        self.label = label
        self.isDisabled = isDisabled
    }
}

/// A compact horizontal collection of related button actions.
public struct ButtonGroup: Component {
    public let children: [RenderElement]
    public var label: String?

    public init(label: String? = nil, @ComponentBuilder content: () -> [RenderElement]) {
        self.label = label
        self.children = content()
    }

    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 1) { Group { children } }.render(in: context)
        element.props.custom["role"] = "group"
        element.props.custom["control"] = "buttonGroup"
        element.props.accessibilityLabel = label
        return element
    }
}

/// Numeric input projected onto Prism's single text-document input engine.
public struct NumberField: Component {
    public let value: Binding<Double>
    public var label: String?
    public var range: ClosedRange<Double>?
    public var step: Double
    public var isDisabled: Bool
    public var isReadOnly: Bool

    public init(_ label: String? = nil, value: Binding<Double>, range: ClosedRange<Double>? = nil, step: Double = 1, isDisabled: Bool = false, isReadOnly: Bool = false) {
        self.label = label
        self.value = value
        self.range = range
        self.step = max(step, .leastNonzeroMagnitude)
        self.isDisabled = isDisabled
        self.isReadOnly = isReadOnly
    }

    /// Applies step and range rules. Hosts call this for keyboard, repeat-button, and drag changes.
    public func setValue(_ proposed: Double) {
        guard !isDisabled, !isReadOnly, proposed.isFinite else { return }
        let stepped = (proposed / step).rounded() * step
        value.setIfChanged(range.map { min(max(stepped, $0.lowerBound), $0.upperBound) } ?? stepped)
    }

    public func increment() { setValue(value.wrappedValue + step) }
    public func decrement() { setValue(value.wrappedValue - step) }

    public func body(context: ComponentContext) -> RenderElement {
        let current = value.wrappedValue
        var props = ElementProps(accessibilityLabel: label)
        props.custom = [
            "role": "spinButton", "value": String(current), "step": String(step),
            "isDisabled": isDisabled ? "true" : "false", "isReadOnly": isReadOnly ? "true" : "false",
            "minimum": range.map { String($0.lowerBound) } ?? "", "maximum": range.map { String($0.upperBound) } ?? ""
        ]
        var element = HStack(spacing: 6) {
            Input(text: Binding(get: { String(current) }, set: { proposed in setValue(Double(proposed) ?? current) }))
                .mode(.number)
            Text("−")
            Text("+")
        }.render(in: context)
        element.props = props
        return element
    }
}

/// Mutually exclusive or multi-select collection of toggle options.
public struct ToggleGroup<Value: Hashable & Sendable>: Component {
    public enum SelectionMode: String, Sendable { case single, multiple }
    public let options: [SelectionOption<Value>]
    public let selectedValues: Binding<Set<Value>>
    public var mode: SelectionMode
    public var label: String?

    public init(options: [SelectionOption<Value>], selected: Binding<Set<Value>>, mode: SelectionMode = .single, label: String? = nil) {
        self.options = options; self.selectedValues = selected; self.mode = mode; self.label = label
    }

    public func toggle(_ option: SelectionOption<Value>) {
        guard !option.isDisabled else { return }
        var next = selectedValues.wrappedValue
        if next.contains(option.value) { next.remove(option.value) }
        else if mode == .single { next = [option.value] }
        else { next.insert(option.value) }
        selectedValues.setIfChanged(next)
    }

    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 4) {
            for option in options {
                Text(option.label).background(selectedValues.wrappedValue.contains(option.value) ? Color.hex("#2563EB") : Color.hex("#F1F5F9"))
            }
        }.render(in: context)
        element.props.custom["role"] = mode == .single ? "radioGroup" : "group"
        element.props.custom["selectionMode"] = mode.rawValue
        element.props.custom["selectedCount"] = String(selectedValues.wrappedValue.count)
        element.props.accessibilityLabel = label
        return element
    }
}

/// Slider semantics for a single numeric value or a two-thumb closed range.
public struct Slider: Component {
    public let value: Binding<Double>
    public var range: ClosedRange<Double>
    public var step: Double
    public var label: String?
    public var isDisabled: Bool

    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01, label: String? = nil, isDisabled: Bool = false) {
        self.value = value; self.range = range; self.step = max(step, .leastNonzeroMagnitude); self.label = label; self.isDisabled = isDisabled
    }

    public func setValue(_ proposed: Double) {
        guard !isDisabled, proposed.isFinite else { return }
        value.setIfChanged(min(max((proposed / step).rounded() * step, range.lowerBound), range.upperBound))
    }

    public func increment() { setValue(value.wrappedValue + step) }
    public func decrement() { setValue(value.wrappedValue - step) }

    public func body(context: ComponentContext) -> RenderElement {
        var element = Rectangle(cornerRadius: 4).fill(Color.hex("#CBD5E1")).frame(width: 180, height: 8)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "slider", "value": String(value.wrappedValue), "minimum": String(range.lowerBound), "maximum": String(range.upperBound), "step": String(step), "isDisabled": isDisabled ? "true" : "false"]
        return element
    }
}

/// A two-thumb range slider sharing the same step and clamp semantics as `Slider`.
public struct RangeSlider: Component {
    public let value: Binding<ClosedRange<Double>>
    public var bounds: ClosedRange<Double>
    public var step: Double
    public var label: String?

    public init(value: Binding<ClosedRange<Double>>, in bounds: ClosedRange<Double> = 0...1, step: Double = 0.01, label: String? = nil) {
        self.value = value; self.bounds = bounds; self.step = max(step, .leastNonzeroMagnitude); self.label = label
    }

    public func setLower(_ proposed: Double) { set(proposed, upper: value.wrappedValue.upperBound) }
    public func setUpper(_ proposed: Double) { set(value.wrappedValue.lowerBound, upper: proposed) }
    private func set(_ lower: Double, upper: Double) {
        let l = min(max((lower / step).rounded() * step, bounds.lowerBound), bounds.upperBound)
        let u = min(max((upper / step).rounded() * step, bounds.lowerBound), bounds.upperBound)
        value.setIfChanged(min(l, u)...max(l, u))
    }

    public func body(context: ComponentContext) -> RenderElement {
        var element = Rectangle(cornerRadius: 4).fill(Color.hex("#93C5FD")).frame(width: 180, height: 8)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "rangeSlider", "lowerValue": String(value.wrappedValue.lowerBound), "upperValue": String(value.wrappedValue.upperBound), "minimum": String(bounds.lowerBound), "maximum": String(bounds.upperBound), "step": String(step)]
        return element
    }
}

/// A numeric stepper with repeat-safe increment and decrement operations.
public struct Stepper: Component {
    public let value: Binding<Double>
    public var range: ClosedRange<Double>?
    public var step: Double
    public var label: String?
    public init(_ label: String? = nil, value: Binding<Double>, range: ClosedRange<Double>? = nil, step: Double = 1) { self.label = label; self.value = value; self.range = range; self.step = max(step, .leastNonzeroMagnitude) }
    public func increment() { update(value.wrappedValue + step) }
    public func decrement() { update(value.wrappedValue - step) }
    private func update(_ proposal: Double) { value.setIfChanged(range.map { min(max(proposal, $0.lowerBound), $0.upperBound) } ?? proposal) }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 6) { Text("−"); Text(String(value.wrappedValue)); Text("+") }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "stepper", "value": String(value.wrappedValue), "step": String(step)]
        return element
    }
}

/// Star-style rating control with a bounded integral value.
public struct Rating: Component {
    public let value: Binding<Int>; public var maximum: Int; public var label: String?
    public init(value: Binding<Int>, maximum: Int = 5, label: String? = nil) { self.value = value; self.maximum = max(1, maximum); self.label = label }
    public func setValue(_ proposed: Int) { value.setIfChanged(min(max(proposed, 0), maximum)) }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 2) { for index in 1...maximum { Text(index <= value.wrappedValue ? "★" : "☆") } }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "rating", "value": String(value.wrappedValue), "maximum": String(maximum)]
        return element
    }
}

/// Input composition container for leading/trailing controls without nesting another text engine.
public struct InputGroup: Component {
    public let leading: [RenderElement]; public let input: RenderElement; public let trailing: [RenderElement]
    public init(@ComponentBuilder leading: () -> [RenderElement] = { [] }, @ComponentBuilder input: () -> [RenderElement], @ComponentBuilder trailing: () -> [RenderElement] = { [] }) { self.leading = leading(); self.input = input().first ?? RenderElement(id: ElementID(typeName: "Empty"), kind: .empty); self.trailing = trailing() }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 6) { Group { leading }; input; Group { trailing } }.render(in: context)
        element.props.custom["role"] = "inputGroup"; return element
    }
}

/// Select presentation that stays platform-neutral at the public API boundary.
public enum SelectPresentation: String, Hashable, Sendable { case menu, native }

/// Platform-independent selection control. Search and multi-select are intentionally P3.
public struct Select<Value: Hashable & Sendable>: Component {
    public let options: [SelectionOption<Value>]; public let selection: Binding<Value>; public var label: String?; public var placeholder: String; public var isDisabled: Bool
    public init(_ label: String? = nil, selection: Binding<Value>, options: [SelectionOption<Value>], placeholder: String = "Select…", isDisabled: Bool = false) { self.label = label; self.selection = selection; self.options = options; self.placeholder = placeholder; self.isDisabled = isDisabled }
    public func select(_ option: SelectionOption<Value>) { guard !isDisabled, !option.isDisabled else { return }; selection.setIfChanged(option.value) }
    public func body(context: ComponentContext) -> RenderElement {
        let selected = options.first { $0.value == selection.wrappedValue }?.label ?? placeholder
        var element = HStack { Text(selected); Text("⌄") }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "comboBox", "presentation": SelectPresentation.menu.rawValue, "value": selected, "optionCount": String(options.count), "isDisabled": isDisabled ? "true" : "false"]
        return element
    }
}

/// Native-presentation request handled solely by the internal host adapter; no platform view type is public.
public struct NativeSelect<Value: Hashable & Sendable>: Component {
    public let select: Select<Value>
    public init(_ label: String? = nil, selection: Binding<Value>, options: [SelectionOption<Value>], placeholder: String = "Select…", isDisabled: Bool = false) { select = Select(label, selection: selection, options: options, placeholder: placeholder, isDisabled: isDisabled) }
    public func select(_ option: SelectionOption<Value>) { select.select(option) }
    public func body(context: ComponentContext) -> RenderElement { var element = select.body(context: context); element.props.custom["presentation"] = SelectPresentation.native.rawValue; return element }
}

/// Experimental searchable single-selection control. Hosts provide text input and key events.
public struct Combobox<Value: Hashable & Sendable>: Component {
    public let options: [SelectionOption<Value>]
    public let selection: Binding<Value>
    public var label: String?
    public var placeholder: String
    public var isDisabled: Bool
    public private(set) var query: String
    public private(set) var isExpanded: Bool
    public private(set) var highlightedIndex: Int?

    public init(_ label: String? = nil, selection: Binding<Value>, options: [SelectionOption<Value>], placeholder: String = "Search…", isDisabled: Bool = false) {
        self.label = label; self.selection = selection; self.options = options; self.placeholder = placeholder; self.isDisabled = isDisabled
        self.query = ""; self.isExpanded = false; self.highlightedIndex = nil
    }

    public var filteredOptions: [SelectionOption<Value>] {
        guard !query.isEmpty else { return options }
        return options.filter { $0.label.localizedCaseInsensitiveContains(query) }
    }

    /// Returns only the requested window, keeping rendering bounded for large choice sets.
    public func visibleOptions(offset: Int, limit: Int) -> [SelectionOption<Value>] {
        guard limit > 0 else { return [] }
        let values = filteredOptions
        let start = min(max(offset, 0), values.count)
        return Array(values[start..<min(start + limit, values.count)])
    }

    public mutating func search(_ text: String) { query = text; highlightedIndex = firstEnabledIndex; isExpanded = true }
    public mutating func open() { guard !isDisabled else { return }; isExpanded = true; highlightedIndex = highlightedIndex ?? firstEnabledIndex }
    public mutating func cancel() { query = ""; isExpanded = false; highlightedIndex = nil }
    public mutating func moveHighlight(by delta: Int) {
        let enabled = filteredOptions.indices.filter { !filteredOptions[$0].isDisabled }
        guard !enabled.isEmpty else { highlightedIndex = nil; return }
        let current = enabled.firstIndex(of: highlightedIndex ?? enabled[0]) ?? 0
        highlightedIndex = enabled[(current + delta + enabled.count) % enabled.count]
    }
    @discardableResult public mutating func commitHighlighted() -> Bool {
        guard let index = highlightedIndex, filteredOptions.indices.contains(index) else { return false }
        let option = filteredOptions[index]
        guard !option.isDisabled, !isDisabled else { return false }
        selection.setIfChanged(option.value); query = ""; isExpanded = false; highlightedIndex = nil; return true
    }
    public func select(_ option: SelectionOption<Value>) { guard !isDisabled, !option.isDisabled else { return }; selection.setIfChanged(option.value) }
    private var firstEnabledIndex: Int? { filteredOptions.firstIndex { !$0.isDisabled } }

    public func body(context: ComponentContext) -> RenderElement {
        let selected = options.first { $0.value == selection.wrappedValue }?.label ?? placeholder
        var element = HStack { Text(query.isEmpty ? selected : query); Text("⌄") }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "comboBox", "value": selected, "query": query, "optionCount": String(filteredOptions.count), "isExpanded": isExpanded ? "true" : "false", "isDisabled": isDisabled ? "true" : "false", "highlightedIndex": highlightedIndex.map(String.init) ?? ""]
        return element
    }
}
