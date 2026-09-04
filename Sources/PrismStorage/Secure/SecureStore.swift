import Foundation
import Security

/// Keychain accessibility configuration options.
public enum AccessibilityOption: Sendable {
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case whenUnlocked
    case whenUnlockedThisDeviceOnly

    var cfValue: CFString {
        switch self {
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
    }
}

/// Errors thrown by SecureStore operations.
public enum SecureStoreError: LocalizedError, Sendable, Equatable {
    case keyNotFound(String)
    case unhandledStatus(OSStatus)
    case conversionFailed
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .keyNotFound(let k):
            return "Key '\(k)' not found in secure storage"
        case .unhandledStatus(let status):
            return "Keychain operation failed with status: \(status)"
        case .conversionFailed:
            return "Data to string conversion failed"
        case .unavailable:
            return "Secure storage backend is currently unavailable"
        }
    }
}

/// Secure credential store backed by the platform Keychain.
///
/// Invariant: Secrets never reach preferences, disk caches, diagnostics, or logs.
/// All deletion operations are strictly scoped to the service namespace.
public final class SecureStore: @unchecked Sendable {
    public static let standard = SecureStore()

    public let service: String
    public let accessGroup: String?

    public init(
        service: String = "com.prism.securestore",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    /// Stores binary data securely in the Keychain.
    public func set(
        _ data: Data,
        for key: String,
        accessibility: AccessibilityOption = .afterFirstUnlock
    ) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.cfValue
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Delete any existing item before adding
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            if status == errSecNotAvailable || status == errSecMissingEntitlement {
                throw SecureStoreError.unavailable
            }
            throw SecureStoreError.unhandledStatus(status)
        }
    }

    /// Stores a string securely in the Keychain.
    public func setString(
        _ value: String,
        for key: String,
        accessibility: AccessibilityOption = .afterFirstUnlock
    ) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStoreError.conversionFailed
        }
        try set(data, for: key, accessibility: accessibility)
    }

    /// Retrieves binary data for a key from the Keychain.
    public func get(_ key: String) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        case errSecNotAvailable, errSecMissingEntitlement:
            throw SecureStoreError.unavailable
        default:
            throw SecureStoreError.unhandledStatus(status)
        }
    }

    /// Retrieves a string for a key from the Keychain.
    public func getString(_ key: String) throws -> String? {
        guard let data = try get(key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStoreError.conversionFailed
        }
        return string
    }

    /// Checks if a key exists in the Keychain.
    public func contains(_ key: String) throws -> Bool {
        try get(key) != nil
    }

    /// Removes an item from the Keychain.
    public func remove(_ key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStoreError.unhandledStatus(status)
        }
    }

    /// Clears all items strictly within this service's namespace.
    public func removeAll() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStoreError.unhandledStatus(status)
        }
    }
}
