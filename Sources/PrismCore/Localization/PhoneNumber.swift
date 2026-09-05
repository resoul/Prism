import Foundation

public struct PhoneCountry: Hashable, Sendable {
    public let code: String; public let dialCode: String; public let nationalLength: ClosedRange<Int>
    public init(code: String, dialCode: String, nationalLength: ClosedRange<Int>) { self.code = code; self.dialCode = dialCode; self.nationalLength = nationalLength }
}

public enum PhoneNumberError: Error, Sendable, Equatable { case invalidCharacters, invalidLength, missingCountry }

/// Small maintained metadata snapshot; update from libphonenumber metadata with attribution when expanded.
public enum PhoneMetadata {
    public static let countries: [PhoneCountry] = [
        PhoneCountry(code: "US", dialCode: "1", nationalLength: 10...10), PhoneCountry(code: "CA", dialCode: "1", nationalLength: 10...10),
        PhoneCountry(code: "GB", dialCode: "44", nationalLength: 10...10), PhoneCountry(code: "DE", dialCode: "49", nationalLength: 10...11),
        PhoneCountry(code: "RO", dialCode: "40", nationalLength: 9...9)
    ]
    public static func country(code: String) -> PhoneCountry? { countries.first { $0.code == code.uppercased() } }
}

public struct PhoneNumber: Hashable, Sendable {
    public let country: PhoneCountry
    public let nationalDigits: String
    public var canonical: String { "+\(country.dialCode)\(nationalDigits)" }

    public init(_ input: String, country: PhoneCountry? = nil) throws {
        let normalized = input.filter(\.isNumber)
        guard input.filter({ !$0.isNumber && !" +()-".contains($0) }).isEmpty else { throw PhoneNumberError.invalidCharacters }
        if input.hasPrefix("+") {
            guard let match = PhoneMetadata.countries.filter({ normalized.hasPrefix($0.dialCode) }).max(by: { $0.dialCode.count < $1.dialCode.count }) else { throw PhoneNumberError.missingCountry }
            self.country = match; self.nationalDigits = String(normalized.dropFirst(match.dialCode.count))
        } else {
            guard let country else { throw PhoneNumberError.missingCountry }
            self.country = country; self.nationalDigits = normalized.hasPrefix(country.dialCode) ? String(normalized.dropFirst(country.dialCode.count)) : normalized
        }
        guard self.country.nationalLength.contains(self.nationalDigits.count) else { throw PhoneNumberError.invalidLength }
    }
    public var isValid: Bool { country.nationalLength.contains(nationalDigits.count) }
    public func formatted() -> String {
        switch country.code { case "US", "CA": return "(\(nationalDigits.prefix(3))) \(nationalDigits.dropFirst(3).prefix(3))-\(nationalDigits.dropFirst(6))"; default: return "+\(country.dialCode) \(nationalDigits)" }
    }
}
