import Foundation

/// Validation outcome for a form field.
public enum ValidationResult: Hashable, Sendable, Equatable {
    case valid
    case invalid(message: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    public var errorMessage: String? {
        if case .invalid(let msg) = self { return msg }
        return nil
    }
}

/// A composable validation rule validating a typed value.
public struct ValidationRule<Value>: Sendable {
    public let validate: @Sendable (Value) -> ValidationResult

    public init(validate: @escaping @Sendable (Value) -> ValidationResult) {
        self.validate = validate
    }

    /// Evaluates multiple validation rules in sequence, returning the first failure or `.valid`.
    public static func evaluate(_ rules: [ValidationRule<Value>], value: Value) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        return .valid
    }
}

// MARK: - Standard String Validation Rules

extension ValidationRule where Value == String {
    /// Requires non-empty string content (ignoring whitespace).
    public static func required(message: String = "This field is required") -> ValidationRule<String> {
        ValidationRule { value in
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid(message: message)
            }
            return .valid
        }
    }

    /// Enforces minimum character count.
    public static func minLength(_ min: Int, message: String? = nil) -> ValidationRule<String> {
        ValidationRule { value in
            if value.count < min {
                return .invalid(message: message ?? "Must be at least \(min) characters")
            }
            return .valid
        }
    }

    /// Enforces maximum character count.
    public static func maxLength(_ max: Int, message: String? = nil) -> ValidationRule<String> {
        ValidationRule { value in
            if value.count > max {
                return .invalid(message: message ?? "Must not exceed \(max) characters")
            }
            return .valid
        }
    }

    /// Validates standard email address format.
    public static func email(message: String = "Please enter a valid email address") -> ValidationRule<String> {
        ValidationRule { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .valid }
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if predicate.evaluate(with: trimmed) {
                return .valid
            }
            return .invalid(message: message)
        }
    }

    /// Custom validation closure returning an optional error string.
    public static func custom(_ validator: @escaping @Sendable (String) -> String?) -> ValidationRule<String> {
        ValidationRule { value in
            if let error = validator(value) {
                return .invalid(message: error)
            }
            return .valid
        }
    }
}
