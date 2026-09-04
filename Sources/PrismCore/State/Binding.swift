import Foundation

/// Two-way value binding connecting controls, inputs, and components to reactive state.
/// Mutates values strictly on `@MainActor` and provides projection, mapping, and feedback loop prevention.
@MainActor
@dynamicMemberLookup
public struct Binding<Value> {
    private let getter: @MainActor () -> Value
    private let setter: @MainActor (Value) -> Void

    public init(
        get: @escaping @MainActor () -> Value,
        set: @escaping @MainActor (Value) -> Void
    ) {
        self.getter = get
        self.setter = set
    }

    /// The current bound value.
    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    /// Creates a read-only constant binding.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }

    /// Creates a two-way binding directly from a local variable holder.
    public static func variable(_ initial: Value) -> (binding: Binding<Value>, get: () -> Value) {
        var storage = initial
        let binding = Binding(
            get: { storage },
            set: { storage = $0 }
        )
        return (binding, { storage })
    }

    /// Transforms this binding into a new binding of type `T` using bidirectional mapping functions.
    public func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (T) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { get(self.wrappedValue) },
            set: { self.wrappedValue = set($0) }
        )
    }

    /// Prevents feedback loops: only invokes the setter if the new value differs from the current value.
    public func setIfChanged(_ newValue: Value) where Value: Equatable {
        if wrappedValue != newValue {
            wrappedValue = newValue
        }
    }

    /// Dynamic member lookup projecting properties of the bound value into child bindings.
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> {
        Binding<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Optional Projections

extension Binding {
    /// Projects an optional binding to a non-optional binding using a fallback default value.
    public subscript<T>(default defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - Collection Projections

extension Binding where Value: MutableCollection, Value.Index: Sendable {
    /// Projects a collection binding to an individual child element binding at the specified index.
    public subscript(index: Value.Index) -> Binding<Value.Element> {
        Binding<Value.Element>(
            get: { self.wrappedValue[index] },
            set: { self.wrappedValue[index] = $0 }
        )
    }
}
