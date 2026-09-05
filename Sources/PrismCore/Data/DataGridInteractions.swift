import Foundation

public enum GridSortDirection: String, Sendable { case ascending, descending }
public struct GridSortDescriptor: Sendable, Equatable { public let key: String; public let direction: GridSortDirection; public init(key: String, direction: GridSortDirection = .ascending) { self.key = key; self.direction = direction } }
public struct GridFilterDescriptor: Sendable, Equatable { public let key: String; public let value: String; public init(key: String, value: String) { self.key = key; self.value = value } }
public struct DataGridInteractionModel<ID: Hashable & Sendable>: Sendable, Equatable {
    public private(set) var rowIDs: [ID]; public private(set) var selectedIDs: Set<ID>; public private(set) var sort: [GridSortDescriptor]; public private(set) var filters: [GridFilterDescriptor]
    public init(rowIDs: [ID]) { self.rowIDs = rowIDs; self.selectedIDs = []; self.sort = []; self.filters = [] }
    public mutating func toggleSelection(_ id: ID) { guard rowIDs.contains(id) else { return }; if !selectedIDs.insert(id).inserted { selectedIDs.remove(id) } }
    public mutating func replaceRows(_ ids: [ID]) { rowIDs = ids; selectedIDs = selectedIDs.intersection(ids) }
    public mutating func setSort(_ descriptors: [GridSortDescriptor]) { sort = descriptors }
    public mutating func setFilters(_ descriptors: [GridFilterDescriptor]) { filters = descriptors }
}
public actor DataGridInteractionProvider<Row: Sendable> {
    public typealias Provider = @Sendable ([GridSortDescriptor], [GridFilterDescriptor]) async throws -> [Row]
    private let provider: Provider; private var task: Task<Void, Never>?; private var generation: UInt64 = 0; private(set) var rows: [Row] = []
    public init(provider: @escaping Provider) { self.provider = provider }
    public func load(sort: [GridSortDescriptor] = [], filters: [GridFilterDescriptor] = []) { generation &+= 1; let current = generation; task?.cancel(); task = Task { [weak self] in do { let result = try await provider(sort, filters); guard !Task.isCancelled else { return }; await self?.finish(result, generation: current) } catch {} } }
    public func cancel() { task?.cancel(); task = nil; generation &+= 1 }
    public func snapshot() -> [Row] { rows }
    private func finish(_ result: [Row], generation: UInt64) { guard self.generation == generation else { return }; rows = result; task = nil }
}
