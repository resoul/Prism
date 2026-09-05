import Foundation

public enum ScopedResourceError: Error, Sendable, Equatable { case permissionDenied, revoked, closed }

/// In-memory, platform-neutral clipboard contract suitable for a host adapter
/// or deterministic tests. Native pasteboards are intentionally outside this API.
public actor ClipboardStore {
    private var value: String?
    private var allowed: Bool
    private var isRevoked = false
    public init(initialValue: String? = nil, allowed: Bool = true) {
        self.value = initialValue
        self.allowed = allowed
    }
    public func read() throws -> String? {
        guard !isRevoked else { throw ScopedResourceError.revoked }
        guard allowed else { throw ScopedResourceError.permissionDenied }
        return value
    }
    public func write(_ value: String) throws {
        guard !isRevoked else { throw ScopedResourceError.revoked }
        guard allowed else { throw ScopedResourceError.permissionDenied }
        self.value = value
    }
    public func revoke() { isRevoked = true; allowed = false; value = nil }
    public func grant() { isRevoked = false; allowed = true }
}

/// A bounded file-like resource with explicit scoped lifetime and revocation.
public actor ScopedFileHandle {
    private var data: Data
    private var isOpen: Bool
    private var isRevoked: Bool

    public init(data: Data = Data(), allowed: Bool = true) {
        self.data = data; self.isOpen = allowed; self.isRevoked = !allowed
    }

    public func read() throws -> Data {
        guard !isRevoked else { throw ScopedResourceError.revoked }
        guard isOpen else { throw ScopedResourceError.closed }
        return data
    }

    public func write(_ data: Data) throws {
        guard !isRevoked else { throw ScopedResourceError.revoked }
        guard isOpen else { throw ScopedResourceError.closed }
        self.data = data
    }

    public func close() { isOpen = false }
    public func revoke() { isRevoked = true; isOpen = false; data.removeAll(keepingCapacity: false) }
    public func cancel() { close() }
    public func status() -> (open: Bool, revoked: Bool) { (isOpen, isRevoked) }
}
