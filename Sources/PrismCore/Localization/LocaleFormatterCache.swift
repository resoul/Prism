import Foundation

/// Internal cache keys for date and number formatters.
public struct DateFormatterKey: Hashable, Sendable {
    public let localeIdentifier: String
    public let dateStyle: DateFormatter.Style
    public let timeStyle: DateFormatter.Style
    public let timeZoneIdentifier: String
    public let customFormat: String?

    public init(
        localeIdentifier: String,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style,
        timeZoneIdentifier: String = "UTC",
        customFormat: String? = nil
    ) {
        self.localeIdentifier = localeIdentifier
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
        self.timeZoneIdentifier = timeZoneIdentifier
        self.customFormat = customFormat
    }
}

public struct NumberFormatterKey: Hashable, Sendable {
    public let localeIdentifier: String
    public let style: NumberFormatter.Style
    public let currencyCode: String?
    public let minFractionDigits: Int?
    public let maxFractionDigits: Int?

    public init(
        localeIdentifier: String,
        style: NumberFormatter.Style,
        currencyCode: String? = nil,
        minFractionDigits: Int? = nil,
        maxFractionDigits: Int? = nil
    ) {
        self.localeIdentifier = localeIdentifier
        self.style = style
        self.currencyCode = currencyCode
        self.minFractionDigits = minFractionDigits
        self.maxFractionDigits = maxFractionDigits
    }
}

/// High-performance, thread-safe formatter cache eliminating allocations during render passes.
public final class LocaleFormatterCache: @unchecked Sendable {
    public static let shared = LocaleFormatterCache()

    private let lock = NSLock()
    private var dateCache: [DateFormatterKey: DateFormatter] = [:]
    private var numberCache: [NumberFormatterKey: NumberFormatter] = [:]

    public init() {}

    /// Retrieves or creates a cached DateFormatter.
    public func dateFormatter(
        locale: Locale = .current,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none,
        timeZone: TimeZone = .current,
        customFormat: String? = nil
    ) -> DateFormatter {
        let key = DateFormatterKey(
            localeIdentifier: locale.identifier,
            dateStyle: dateStyle,
            timeStyle: timeStyle,
            timeZoneIdentifier: timeZone.identifier,
            customFormat: customFormat
        )

        lock.lock()
        defer { lock.unlock() }

        if let cached = dateCache[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        if let customFormat {
            formatter.dateFormat = customFormat
        } else {
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
        }

        dateCache[key] = formatter
        return formatter
    }

    /// Formats a date using cached formatters.
    public func string(
        from date: Date,
        locale: Locale = .current,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none,
        timeZone: TimeZone = .current
    ) -> String {
        dateFormatter(
            locale: locale,
            dateStyle: dateStyle,
            timeStyle: timeStyle,
            timeZone: timeZone
        ).string(from: date)
    }

    /// Retrieves or creates a cached NumberFormatter.
    public func numberFormatter(
        locale: Locale = .current,
        style: NumberFormatter.Style = .decimal,
        currencyCode: String? = nil,
        minFractionDigits: Int? = nil,
        maxFractionDigits: Int? = nil
    ) -> NumberFormatter {
        let key = NumberFormatterKey(
            localeIdentifier: locale.identifier,
            style: style,
            currencyCode: currencyCode,
            minFractionDigits: minFractionDigits,
            maxFractionDigits: maxFractionDigits
        )

        lock.lock()
        defer { lock.unlock() }

        if let cached = numberCache[key] {
            return cached
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = style
        if let currencyCode {
            formatter.currencyCode = currencyCode
        }
        if let minFractionDigits {
            formatter.minimumFractionDigits = minFractionDigits
        }
        if let maxFractionDigits {
            formatter.maximumFractionDigits = maxFractionDigits
        }

        numberCache[key] = formatter
        return formatter
    }

    /// Formats a currency value using cached formatters.
    public func formatCurrency(
        _ value: NSNumber,
        currencyCode: String,
        locale: Locale = .current
    ) -> String {
        let formatter = numberFormatter(
            locale: locale,
            style: .currency,
            currencyCode: currencyCode
        )
        return formatter.string(from: value) ?? "\(currencyCode) \(value)"
    }

    /// Formats a numeric value using cached formatters.
    public func formatNumber(
        _ value: NSNumber,
        style: NumberFormatter.Style = .decimal,
        locale: Locale = .current
    ) -> String {
        let formatter = numberFormatter(locale: locale, style: style)
        return formatter.string(from: value) ?? "\(value)"
    }

    /// Total count of cached formatters.
    public var cachedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return dateCache.count + numberCache.count
    }

    /// Clears all cached formatters.
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        dateCache.removeAll()
        numberCache.removeAll()
    }
}
