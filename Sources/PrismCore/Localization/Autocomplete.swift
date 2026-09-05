import Foundation

public enum AutocompleteError: Error, Sendable, Equatable { case cancelled }

public struct AutocompleteSnapshot<Suggestion: Sendable>: Sendable {
    public let text: String
    public let suggestions: [Suggestion]
    public let isLoading: Bool
    public let generation: UInt64
    public init(text: String = "", suggestions: [Suggestion] = [], isLoading: Bool = false, generation: UInt64 = 0) {
        self.text = text; self.suggestions = suggestions; self.isLoading = isLoading; self.generation = generation
    }
}

/// Cancellable, debounced suggestion coordinator with stale-response protection.
public actor AutocompleteEngine<Suggestion: Sendable> {
    public typealias Provider = @Sendable (String) async throws -> [Suggestion]
    private let provider: Provider
    private let debounceNanoseconds: UInt64
    private var state = AutocompleteSnapshot<Suggestion>()
    private var requestTask: Task<Void, Never>?

    public init(debounceNanoseconds: UInt64 = 150_000_000, provider: @escaping Provider) {
        self.debounceNanoseconds = debounceNanoseconds; self.provider = provider
    }

    public func update(text: String) {
        requestTask?.cancel(); state = AutocompleteSnapshot(text: text, suggestions: [], isLoading: !text.isEmpty, generation: state.generation &+ 1)
        guard !text.isEmpty else { return }
        let generation = state.generation
        requestTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
                let suggestions = try await provider(text)
                guard !Task.isCancelled else { return }
                await self?.complete(suggestions: suggestions, text: text, generation: generation)
            } catch { await self?.finishIfCurrent(text: text, generation: generation) }
        }
    }

    public func cancel() {
        requestTask?.cancel(); requestTask = nil
        state = AutocompleteSnapshot(text: state.text, suggestions: [], isLoading: false, generation: state.generation &+ 1)
    }

    public func snapshot() -> AutocompleteSnapshot<Suggestion> { state }
    private func complete(suggestions: [Suggestion], text: String, generation: UInt64) {
        guard state.generation == generation, state.text == text else { return }
        state = AutocompleteSnapshot(text: text, suggestions: suggestions, isLoading: false, generation: generation)
        requestTask = nil
    }
    private func finishIfCurrent(text: String, generation: UInt64) {
        guard state.generation == generation, state.text == text else { return }
        state = AutocompleteSnapshot(text: text, suggestions: [], isLoading: false, generation: generation); requestTask = nil
    }
}
