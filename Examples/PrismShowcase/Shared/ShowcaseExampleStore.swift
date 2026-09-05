import Foundation
import CoreGraphics
import PrismUI

/// Isolated state snapshot for an individual component detail playground.
public struct ShowcaseExampleState: Equatable, Sendable {
    public var componentID: String
    public var selectedState: String
    public var selectedVariant: String
    public var localCount: Int
    public var localText: String
    public var localBool: Bool
    public var localDouble: Double
    public var expandedItems: Set<String>
    public var lastAction: String
    public var eventsLog: [String]

    public init(
        componentID: String,
        selectedState: String = "default",
        selectedVariant: String = "default",
        localCount: Int = 0,
        localText: String = "",
        localBool: Bool = false,
        localDouble: Double = 0.5,
        expandedItems: Set<String> = ["item-1"],
        lastAction: String = "init",
        eventsLog: [String] = []
    ) {
        self.componentID = componentID
        self.selectedState = selectedState
        self.selectedVariant = selectedVariant
        self.localCount = localCount
        self.localText = localText
        self.localBool = localBool
        self.localDouble = localDouble
        self.expandedItems = expandedItems
        self.lastAction = lastAction
        self.eventsLog = eventsLog
    }
}

/// Dedicated, isolated store managing interactions and local scenario state for a single component.
@MainActor
public final class ShowcaseExampleStore: ObservableObject {
    public private(set) var state: ShowcaseExampleState
    public var onChange: (@MainActor () -> Void)?

    private let initialState: ShowcaseExampleState

    public init(
        componentID: String,
        initialState: String = "default",
        initialVariant: String = "default"
    ) {
        let initial = ShowcaseExampleState(
            componentID: componentID,
            selectedState: initialState,
            selectedVariant: initialVariant
        )
        self.initialState = initial
        self.state = initial
    }

    public func setState(_ stateName: String) {
        guard state.selectedState != stateName else { return }
        state.selectedState = stateName
        logAction("setState(\(stateName))")
    }

    public func setVariant(_ variantName: String) {
        guard state.selectedVariant != variantName else { return }
        state.selectedVariant = variantName
        logAction("setVariant(\(variantName))")
    }

    public func toggleExpanded(_ itemID: String) {
        if state.expandedItems.contains(itemID) {
            state.expandedItems.remove(itemID)
            logAction("collapse(\(itemID))")
        } else {
            state.expandedItems.insert(itemID)
            logAction("expand(\(itemID))")
        }
    }

    public func isExpanded(_ itemID: String) -> Bool {
        state.expandedItems.contains(itemID)
    }

    public func increment() {
        state.localCount += 1
        logAction("increment(\(state.localCount))")
    }

    public func decrement() {
        state.localCount -= 1
        logAction("decrement(\(state.localCount))")
    }

    public func setText(_ text: String) {
        guard state.localText != text else { return }
        state.localText = text
        logAction("setText(\"\(text)\")")
    }

    public func setBool(_ value: Bool) {
        guard state.localBool != value else { return }
        state.localBool = value
        logAction("setBool(\(value))")
    }

    public func setDouble(_ value: Double) {
        guard state.localDouble != value else { return }
        state.localDouble = value
        logAction("setDouble(\(String(format: "%.2f", value)))")
    }

    public func triggerAction(_ name: String) {
        logAction(name)
    }

    /// Resets this specific example store back to its initial scenario state without affecting other scenarios.
    public func reset() {
        state = initialState
        logAction("reset")
    }

    public func expandedBinding() -> Binding<Set<String>> {
        Binding<Set<String>>(
            get: { [weak self] in self?.state.expandedItems ?? [] },
            set: { [weak self] newSet in
                guard let self = self, self.state.expandedItems != newSet else { return }
                self.state.expandedItems = newSet
                self.logAction("setExpanded(\(newSet.sorted().joined(separator: ",")))")
            }
        )
    }

    public func textBinding() -> Binding<String> {
        Binding<String>(
            get: { [weak self] in self?.state.localText ?? "" },
            set: { [weak self] in self?.setText($0) }
        )
    }

    public func boolBinding() -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in self?.state.localBool ?? false },
            set: { [weak self] in self?.setBool($0) }
        )
    }

    public func doubleBinding() -> Binding<Double> {
        Binding<Double>(
            get: { [weak self] in self?.state.localDouble ?? 0.0 },
            set: { [weak self] in self?.setDouble($0) }
        )
    }

    public func teardown() {
        onChange = nil
    }

    private func logAction(_ action: String) {
        state.lastAction = action
        state.eventsLog.append(action)
        if state.eventsLog.count > 10 {
            state.eventsLog.removeFirst(state.eventsLog.count - 10)
        }
        onChange?()
    }
}
