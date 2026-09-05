import Foundation

public struct PaletteCommand: Sendable, Equatable {
    public let id: String; public let title: String; public let scope: String; public let shortcut: Character?; public var isEnabled: Bool
    public init(id: String, title: String, scope: String = "global", shortcut: Character? = nil, isEnabled: Bool = true) { self.id = id; self.title = title; self.scope = scope; self.shortcut = shortcut; self.isEnabled = isEnabled }
}
public struct CommandPaletteSnapshot: Sendable, Equatable { public let query: String; public let results: [PaletteCommand]; public let isPresented: Bool; public let isLoading: Bool; public init(query: String = "", results: [PaletteCommand] = [], isPresented: Bool = false, isLoading: Bool = false) { self.query = query; self.results = results; self.isPresented = isPresented; self.isLoading = isLoading } }

public actor CommandPaletteEngine {
    public typealias Provider = @Sendable (String) async throws -> [PaletteCommand]
    private let provider: Provider; private var task: Task<Void, Never>?; private var snapshot = CommandPaletteSnapshot()
    public init(provider: @escaping Provider) { self.provider = provider }
    public func open() { snapshot = CommandPaletteSnapshot(query: snapshot.query, results: snapshot.results, isPresented: true, isLoading: false) }
    public func dismiss() { task?.cancel(); snapshot = CommandPaletteSnapshot(); task = nil }
    public func search(_ query: String) { task?.cancel(); snapshot = CommandPaletteSnapshot(query: query, results: [], isPresented: true, isLoading: !query.isEmpty); guard !query.isEmpty else { return }; task = Task { [weak self] in do { let results = try await provider(query); guard !Task.isCancelled else { return }; await self?.finish(query: query, results: results) } catch { await self?.finish(query: query, results: []) } } }
    public func execute(id: String) -> String? { guard snapshot.isPresented, let command = snapshot.results.first(where: { $0.id == id && $0.isEnabled }) else { return nil }; return command.id }
    public func snapshotValue() -> CommandPaletteSnapshot { snapshot }
    private func finish(query: String, results: [PaletteCommand]) { guard snapshot.query == query, snapshot.isPresented else { return }; snapshot = CommandPaletteSnapshot(query: query, results: results.filter(\.isEnabled), isPresented: true, isLoading: false); task = nil }
}

public struct CommandRegistry: Sendable, Equatable {
    public private(set) var commands: [PaletteCommand]
    public init(commands: [PaletteCommand] = []) { self.commands = commands }
    public mutating func register(_ command: PaletteCommand) { commands.removeAll { $0.id == command.id }; commands.append(command) }
    public func resolveShortcut(_ shortcut: Character, scope: String = "global") -> PaletteCommand? { commands.first { $0.isEnabled && $0.shortcut?.lowercased() == shortcut.lowercased() && ($0.scope == scope || $0.scope == "global") } }
}
