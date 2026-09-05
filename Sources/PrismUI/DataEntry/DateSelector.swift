import Foundation
import PrismCore

/// Experimental single-date selector; hosts provide the calendar popover and focus adapter.
public struct DateSelector: Component {
    public let selection: Binding<Date>
    public let calendar: CalendarService
    public var minimumDate: Date?
    public var maximumDate: Date?
    public var label: String?
    public var isDisabled: Bool
    public private(set) var isPresented: Bool
    public private(set) var focusedDate: Date

    public init(_ label: String? = nil, selection: Binding<Date>, calendar: CalendarService = CalendarService(), minimumDate: Date? = nil, maximumDate: Date? = nil, isDisabled: Bool = false) {
        self.label = label; self.selection = selection; self.calendar = calendar; self.minimumDate = minimumDate; self.maximumDate = maximumDate; self.isDisabled = isDisabled
        self.isPresented = false; self.focusedDate = selection.wrappedValue
    }

    public func isSelectable(_ date: Date) -> Bool {
        (minimumDate == nil || date >= minimumDate!) && (maximumDate == nil || date <= maximumDate!)
    }
    public mutating func present() { guard !isDisabled else { return }; isPresented = true; focusedDate = selection.wrappedValue }
    public mutating func dismiss() { isPresented = false }
    public mutating func cancel() { isPresented = false; focusedDate = selection.wrappedValue }
    public mutating func moveDay(by days: Int) {
        guard let next = calendar.adding(.day, value: days, to: focusedDate) else { return }
        focusedDate = next
    }
    @discardableResult public mutating func select(_ date: Date) -> Bool {
        guard !isDisabled, isSelectable(date) else { return false }
        selection.setIfChanged(date); focusedDate = date; isPresented = false; return true
    }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack { Text(calendar.format(selection.wrappedValue)); Text("▾") }.render(in: context)
        element.props.accessibilityLabel = label
        element.props.custom = ["role": "datePicker", "value": calendar.format(selection.wrappedValue), "isPresented": isPresented ? "true" : "false", "isDisabled": isDisabled ? "true" : "false", "hasMinimum": minimumDate == nil ? "false" : "true", "hasMaximum": maximumDate == nil ? "false" : "true"]
        return element
    }
}
