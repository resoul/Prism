import Foundation

public enum CalendarServiceError: Error, Sendable, Equatable {
    case invalidDateComponents
    case nonexistentLocalTime
    case cancelled
}

public enum CalendarResolutionPolicy: Sendable { case strict, nextValid }
public enum CalendarRepeatedTimePolicy: Sendable { case first, last }

public protocol PrismClock: Sendable {
    var now: Date { get }
}

public struct SystemPrismClock: PrismClock, Sendable {
    public init() {}
    public var now: Date { Date() }
}

public struct FixedPrismClock: PrismClock, Sendable {
    public let now: Date
    public init(now: Date) { self.now = now }
}

/// Deterministic, platform-neutral calendar operations. Native date pickers are out of scope.
public struct CalendarService: Sendable {
    public let calendar: Calendar
    public let locale: Locale
    public let timeZone: TimeZone
    private let clock: any PrismClock

    public init(
        calendarIdentifier: Calendar.Identifier = .gregorian,
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        clock: any PrismClock = SystemPrismClock()
    ) {
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.locale = locale
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.locale = locale
        self.timeZone = timeZone
        self.clock = clock
    }

    public var now: Date { clock.now }

    public func date(from components: DateComponents) throws -> Date {
        guard let date = calendar.date(from: components) else { throw CalendarServiceError.invalidDateComponents }
        let resolved = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let pairs: [(Int?, Int?)] = [
            (components.era, resolved.era), (components.year, resolved.year),
            (components.month, resolved.month), (components.day, resolved.day),
            (components.hour, resolved.hour), (components.minute, resolved.minute),
            (components.second, resolved.second)
        ]
        guard pairs.allSatisfy({ requested, actual in requested == nil || requested == actual }) else {
            throw CalendarServiceError.nonexistentLocalTime
        }
        return date
    }

    public func resolve(
        _ components: DateComponents,
        policy: CalendarResolutionPolicy = .strict,
        repeatedTimePolicy: CalendarRepeatedTimePolicy = .first
    ) throws -> Date {
        let repeated: Calendar.RepeatedTimePolicy = repeatedTimePolicy == .first ? .first : .last
        let matching: Calendar.MatchingPolicy = policy == .strict ? .strict : .nextTime
        let anchor = Date(timeIntervalSince1970: -86_400)
        guard let date = calendar.nextDate(after: anchor, matching: components, matchingPolicy: matching, repeatedTimePolicy: repeated, direction: .forward) else {
            throw policy == .strict ? CalendarServiceError.nonexistentLocalTime : CalendarServiceError.invalidDateComponents
        }
        return date
    }

    public func components(_ units: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(units, from: date)
    }

    public func adding(_ component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }

    public func startOfDay(for date: Date) -> Date { calendar.startOfDay(for: date) }

    public func format(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }
}
