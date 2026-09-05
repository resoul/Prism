import Foundation

public enum FileUploadError: Error, Sendable, Equatable { case permissionDenied, invalidSize, invalidType, invalidFilename, cancelled, failed }
public struct UploadFile: Sendable, Equatable {
    public let name: String; public let mimeType: String; public let data: Data
    public init(name: String, mimeType: String, data: Data) { self.name = name; self.mimeType = mimeType; self.data = data }
}
public enum UploadStatus: Sendable, Equatable { case idle, uploading, succeeded, failed(FileUploadError), cancelled }

/// Actor-owned upload coordinator with validation and bounded in-flight jobs.
public actor FileUploadCoordinator {
    public typealias Provider = @Sendable (UploadFile) async throws -> Void
    private let provider: Provider; private let maxBytes: Int; private let allowedMIMETypes: Set<String>; private let maxConcurrent: Int
    private var statuses: [String: UploadStatus] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]
    public init(maxBytes: Int = 10 * 1024 * 1024, allowedMIMETypes: Set<String> = [], maxConcurrent: Int = 2, provider: @escaping Provider) { self.maxBytes = max(0, maxBytes); self.allowedMIMETypes = allowedMIMETypes; self.maxConcurrent = max(1, maxConcurrent); self.provider = provider }
    public func status(for id: String) -> UploadStatus { statuses[id] ?? .idle }
    public func start(id: String, file: UploadFile) {
        tasks[id]?.cancel(); statuses[id] = .uploading
        tasks[id] = Task { [weak self] in
            do { try await self?.validate(file); try Task.checkCancellation(); try await provider(file); guard !Task.isCancelled else { return }; await self?.finish(id: id, status: .succeeded) }
            catch is CancellationError { await self?.finish(id: id, status: .cancelled) }
            catch let error as FileUploadError { await self?.finish(id: id, status: .failed(error)) }
            catch { await self?.finish(id: id, status: .failed(.failed)) }
        }
    }
    public func cancel(id: String) { tasks[id]?.cancel(); statuses[id] = .cancelled }
    public func retry(id: String, file: UploadFile) { start(id: id, file: file) }
    private func validate(_ file: UploadFile) throws {
        guard file.data.count <= maxBytes else { throw FileUploadError.invalidSize }
        guard allowedMIMETypes.isEmpty || allowedMIMETypes.contains(file.mimeType.lowercased()) else { throw FileUploadError.invalidType }
        let sanitized = file.name.replacingOccurrences(of: "..", with: "").replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "\\", with: "")
        let hasControl = file.name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        guard !sanitized.isEmpty, sanitized == file.name, !hasControl else { throw FileUploadError.invalidFilename }
    }
    private func finish(id: String, status: UploadStatus) { statuses[id] = status; tasks[id] = nil }
}
