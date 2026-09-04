import Foundation
import struct Flux.Flux
import class Flux.Pipe

/// Strongly-typed descriptor for a preference value.
public struct PrefKey<Value: Codable & Sendable>: Sendable, Hashable {
    public let name: String
    public let defaultValue: Value

    public init(name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }

    public static func == (lhs: PrefKey<Value>, rhs: PrefKey<Value>) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/// Thread-safe typed preferences store backed by `UserDefaults` with reactive Flux observation.
public final class Preferences: @unchecked Sendable {
    public static let standard = Preferences()

    private let userDefaults: UserDefaults
    private let suiteName: String?
    private let lock = NSLock()
    private var pipes: [String: Any] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(suiteName: String? = "com.prism.storage.preferences") {
        self.suiteName = suiteName
        if let suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
    }

    public init(userDefaults: UserDefaults, suiteName: String? = nil) {
        self.suiteName = suiteName
        self.userDefaults = userDefaults
    }

    /// Retrieves a typed preference value, returning `defaultValue` if not found or corrupted.
    public func get<T: Codable & Sendable>(_ key: PrefKey<T>) -> T {
        lock.lock()
        defer { lock.unlock() }

        // Fast path for primitives
        if T.self == Bool.self, let val = userDefaults.object(forKey: key.name) as? T {
            return val
        }
        if T.self == Int.self, let val = userDefaults.object(forKey: key.name) as? T {
            return val
        }
        if T.self == Double.self, let val = userDefaults.object(forKey: key.name) as? T {
            return val
        }
        if T.self == String.self, let val = userDefaults.object(forKey: key.name) as? T {
            return val
        }

        // Codable fallback
        guard let data = userDefaults.data(forKey: key.name) else {
            return key.defaultValue
        }
        return (try? decoder.decode(T.self, from: data)) ?? key.defaultValue
    }

    /// Persists a typed preference value and notifies active Flux observers.
    public func set<T: Codable & Sendable & Equatable>(_ value: T, for key: PrefKey<T>) {
        lock.lock()
        let oldValue: T? = {
            if T.self == Bool.self || T.self == Int.self || T.self == Double.self || T.self == String.self {
                return userDefaults.object(forKey: key.name) as? T
            }
            guard let data = userDefaults.data(forKey: key.name) else { return nil }
            return try? decoder.decode(T.self, from: data)
        }()

        if T.self == Bool.self || T.self == Int.self || T.self == Double.self || T.self == String.self {
            userDefaults.set(value, forKey: key.name)
        } else if let data = try? encoder.encode(value) {
            userDefaults.set(data, forKey: key.name)
        }

        let pipe = pipes[key.name] as? Pipe<T>
        lock.unlock()

        if oldValue != value {
            pipe?.send(value)
        }
    }

    /// Removes a preference, restoring its default value on subsequent reads.
    public func remove<T: Codable & Sendable>(_ key: PrefKey<T>) {
        lock.lock()
        userDefaults.removeObject(forKey: key.name)
        let pipe = pipes[key.name] as? Pipe<T>
        lock.unlock()

        pipe?.send(key.defaultValue)
    }

    /// Resets all preferences and closes active observation pipes.
    public func resetAll() {
        lock.lock()
        defer { lock.unlock() }

        if let suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        } else {
            for key in userDefaults.dictionaryRepresentation().keys {
                userDefaults.removeObject(forKey: key)
            }
        }
        pipes.removeAll()
    }

    /// Observes a preference value as a reactive Flux stream.
    public func observe<T: Codable & Sendable & Equatable>(_ key: PrefKey<T>) -> Flux<T> {
        lock.lock()
        defer { lock.unlock() }

        if let existing = pipes[key.name] as? Pipe<T> {
            return existing.flux
        }

        let pipe = Pipe<T>(bufferingPolicy: .bufferingNewest(16))
        pipes[key.name] = pipe
        return pipe.flux
    }
}

/// Property wrapper for declaring typed preferences with reactive bindings.
@propertyWrapper
public struct Preference<Value: Codable & Sendable & Equatable>: Sendable {
    public let key: PrefKey<Value>
    public let preferences: Preferences

    public init(key: PrefKey<Value>, preferences: Preferences = .standard) {
        self.key = key
        self.preferences = preferences
    }

    public var wrappedValue: Value {
        get { preferences.get(key) }
        nonmutating set { preferences.set(newValue, for: key) }
    }

    public var projectedValue: Flux<Value> {
        preferences.observe(key)
    }
}
