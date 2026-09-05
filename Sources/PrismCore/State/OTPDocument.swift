import Foundation

public struct OTPDocument: Sendable, Equatable {
    public let length: Int
    public let allowedCharacters: CharacterSet
    public private(set) var value: String
    public init(length: Int = 6, value: String = "", allowedCharacters: CharacterSet = .decimalDigits) {
        self.length = max(1, length); self.allowedCharacters = allowedCharacters
        self.value = String(value.unicodeScalars.filter { allowedCharacters.contains($0) }.prefix(self.length))
    }
    public var isComplete: Bool { value.count == length }
    public var segments: [Character?] { (0..<length).map { index in index < value.count ? Array(value)[index] : nil } }
    @discardableResult public mutating func paste(_ text: String) -> Bool { set(text) }
    @discardableResult public mutating func insert(_ text: String) -> Bool { set(value + text) }
    @discardableResult public mutating func backspace() -> Bool { guard !value.isEmpty else { return false }; value.removeLast(); return true }
    public mutating func clear() { value = "" }
    @discardableResult private mutating func set(_ text: String) -> Bool {
        let next = String(text.unicodeScalars.filter { allowedCharacters.contains($0) }.prefix(length))
        guard next != value else { return false }; value = next; return true
    }
}
