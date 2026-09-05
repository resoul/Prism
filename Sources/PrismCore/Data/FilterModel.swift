import Foundation

public enum FilterValue: Codable, Sendable, Equatable { case string(String), number(Double), bool(Bool), null
    public init(from decoder: Decoder) throws { let c = try decoder.singleValueContainer(); if c.decodeNil() { self = .null } else if let v = try? c.decode(String.self) { self = .string(v) } else if let v = try? c.decode(Double.self) { self = .number(v) } else { self = .bool(try c.decode(Bool.self)) } }
    public func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); switch self { case .string(let v): try c.encode(v); case .number(let v): try c.encode(v); case .bool(let v): try c.encode(v); case .null: try c.encodeNil() } }
}
public enum FilterOperator: Codable, Sendable, Equatable { case equals, contains, greaterThan, lessThan, isNull, unknown(String)
    public init(from decoder: Decoder) throws { let raw = try decoder.singleValueContainer().decode(String.self); self = [.equals, .contains, .greaterThan, .lessThan, .isNull].first { $0.rawValue == raw } ?? .unknown(raw) }
    public func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(rawValue) }
    private var rawValue: String { switch self { case .equals: return "equals"; case .contains: return "contains"; case .greaterThan: return "greaterThan"; case .lessThan: return "lessThan"; case .isNull: return "isNull"; case .unknown(let v): return v } }
}
public struct FilterRule: Codable, Sendable, Equatable { public let field: String; public let op: FilterOperator; public let value: FilterValue?; public init(field: String, op: FilterOperator, value: FilterValue? = nil) { self.field = field; self.op = op; self.value = value } }
public indirect enum FilterExpression: Codable, Sendable, Equatable { case rule(FilterRule), all([FilterExpression]), any([FilterExpression]), not(FilterExpression) }

public enum FilterValidationError: Error, Sendable, Equatable { case emptyField, missingValue, unsupportedOperator(String) }
public struct FilterModel: Codable, Sendable, Equatable {
    public let schemaVersion: Int; public let expression: FilterExpression
    public init(expression: FilterExpression, schemaVersion: Int = 1) { self.expression = expression; self.schemaVersion = schemaVersion }
    public func validate() throws { try validate(expression) }
    private func validate(_ expression: FilterExpression) throws { switch expression { case .rule(let rule): guard !rule.field.isEmpty else { throw FilterValidationError.emptyField }; if case .unknown(let name) = rule.op { throw FilterValidationError.unsupportedOperator(name) }; if rule.value == nil && rule.op != .isNull { throw FilterValidationError.missingValue }; case .all(let values), .any(let values): for value in values { try validate(value) }; case .not(let value): try validate(value) } }
    public func serialized() throws -> Data { try JSONEncoder().encode(self) }
    public static func migrate(_ data: Data) throws -> FilterModel { let decoded = try JSONDecoder().decode(FilterModel.self, from: data); return FilterModel(expression: decoded.expression, schemaVersion: 1) }
}
