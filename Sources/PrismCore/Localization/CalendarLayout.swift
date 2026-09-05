import Foundation

public enum CalendarLayoutMode: String, Sendable { case month, week, day }
public struct CalendarDayCell: Sendable, Equatable { public let date: Date; public let day: Int; public let isInDisplayedMonth: Bool; public let isSelected: Bool; public init(date: Date, day: Int, isInDisplayedMonth: Bool, isSelected: Bool) { self.date = date; self.day = day; self.isInDisplayedMonth = isInDisplayedMonth; self.isSelected = isSelected } }
public struct CalendarLayout: Sendable, Equatable {
    public let mode: CalendarLayoutMode; public let referenceDate: Date; public let selectedDate: Date?; public let weekdaySymbols: [String]; public let cells: [CalendarDayCell]; public let isRTL: Bool
    public init(mode: CalendarLayoutMode, referenceDate: Date, selectedDate: Date? = nil, service: CalendarService = CalendarService(), isRTL: Bool = false) {
        self.mode = mode; self.referenceDate = referenceDate; self.selectedDate = selectedDate; self.isRTL = isRTL
        let calendar = service.calendar; let symbols = calendar.shortStandaloneWeekdaySymbols; let first = calendar.firstWeekday - 1; self.weekdaySymbols = (0..<7).map { symbols[(first + $0) % 7] }
        switch mode {
        case .month:
            let start = calendar.dateInterval(of: .month, for: referenceDate)!.start; let weekday = calendar.component(.weekday, from: start); let leading = (weekday - calendar.firstWeekday + 7) % 7; let count = calendar.range(of: .day, in: .month, for: start)!.count; var result: [CalendarDayCell] = []; for index in 0..<(leading + count) { let date = calendar.date(byAdding: .day, value: index - leading, to: start)!; result.append(CalendarDayCell(date: date, day: calendar.component(.day, from: date), isInDisplayedMonth: index >= leading, isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false)) }; self.cells = result
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start; self.cells = (0..<7).map { let date = calendar.date(byAdding: .day, value: $0, to: start)!; return CalendarDayCell(date: date, day: calendar.component(.day, from: date), isInDisplayedMonth: true, isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false) }
        case .day: self.cells = [CalendarDayCell(date: referenceDate, day: calendar.component(.day, from: referenceDate), isInDisplayedMonth: true, isSelected: true)]
        }
    }
}
