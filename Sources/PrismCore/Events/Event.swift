import Foundation
import CoreGraphics

// MARK: - Event Phase & Result

/// Propagation phase during event traversal.
public enum EventPhase: Sendable, Equatable {
    /// Dispatched from the root down to the target's parent.
    case capturing
    /// Dispatched directly on the target node.
    case atTarget
    /// Dispatched from the target's parent up to the root.
    case bubbling
}

/// The outcome of an event handler execution.
public enum EventResult: Sendable, Equatable {
    case handled
    case ignored
}

// MARK: - Modifiers & Pointer Primitives

/// Bitmask of keyboard modifier keys active during an input event.
public struct EventModifiers: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let shift     = EventModifiers(rawValue: 1 << 0)
    public static let control   = EventModifiers(rawValue: 1 << 1)
    public static let option    = EventModifiers(rawValue: 1 << 2)
    public static let command   = EventModifiers(rawValue: 1 << 3)
    public static let capsLock  = EventModifiers(rawValue: 1 << 4)

    public static let none: EventModifiers = []
}

/// Hardware type generating pointer input.
public enum PointerType: Sendable, Equatable {
    case touch
    case mouse
    case pen
}

/// Physical button generating pointer input.
public enum PointerButton: Sendable, Equatable {
    case none
    case primary
    case secondary
    case auxiliary
}

// MARK: - Event Payloads

/// Payload carrying pointer/mouse/touch metrics.
public struct PointerEventData: Sendable, Equatable {
    /// Coordinate in local element coordinates.
    public var location: CGPoint
    /// Coordinate in root host window coordinates.
    public var globalLocation: CGPoint
    /// The button involved in this event.
    public var button: PointerButton
    /// The hardware input source.
    public var pointerType: PointerType
    /// Active keyboard modifiers.
    public var modifiers: EventModifiers
    /// Number of consecutive clicks / taps.
    public var clickCount: Int

    public init(
        location: CGPoint,
        globalLocation: CGPoint,
        button: PointerButton = .primary,
        pointerType: PointerType = .mouse,
        modifiers: EventModifiers = .none,
        clickCount: Int = 1
    ) {
        self.location = location
        self.globalLocation = globalLocation
        self.button = button
        self.pointerType = pointerType
        self.modifiers = modifiers
        self.clickCount = clickCount
    }
}

/// Payload carrying physical or virtual keyboard input metrics.
public struct KeyEventData: Sendable, Equatable {
    /// String representation of the key pressed.
    public var key: String
    /// Character string including modifier effects.
    public var characters: String
    /// Character string unmodified by Shift/Option.
    public var charactersIgnoringModifiers: String
    /// Raw platform-neutral or virtual key code.
    public var keyCode: UInt16
    /// Active keyboard modifiers.
    public var modifiers: EventModifiers
    /// Indicates whether this key is repeating.
    public var isRepeat: Bool

    public init(
        key: String,
        characters: String = "",
        charactersIgnoringModifiers: String = "",
        keyCode: UInt16 = 0,
        modifiers: EventModifiers = .none,
        isRepeat: Bool = false
    ) {
        self.key = key
        self.characters = characters.isEmpty ? key : characters
        self.charactersIgnoringModifiers = charactersIgnoringModifiers.isEmpty ? key : charactersIgnoringModifiers
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }
}

/// Phase of a continuous scrolling interaction.
public enum ScrollPhase: Sendable, Equatable {
    case began
    case changed
    case ended
    case cancelled
    case momentum
}

/// Payload carrying scrolling metrics.
public struct ScrollEventData: Sendable, Equatable {
    public var location: CGPoint
    public var deltaX: Double
    public var deltaY: Double
    public var phase: ScrollPhase
    public var modifiers: EventModifiers

    public init(
        location: CGPoint,
        deltaX: Double,
        deltaY: Double,
        phase: ScrollPhase = .changed,
        modifiers: EventModifiers = .none
    ) {
        self.location = location
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.phase = phase
        self.modifiers = modifiers
    }
}

/// Payload carrying focus transition metrics.
public struct FocusEventData: Sendable, Equatable {
    public var relatedID: ElementID?

    public init(relatedID: ElementID? = nil) {
        self.relatedID = relatedID
    }
}

/// Generic container for typed event payloads.
public enum EventPayload: Sendable {
    case pointer(PointerEventData)
    case key(KeyEventData)
    case scroll(ScrollEventData)
    case focus(FocusEventData)
    case custom(Sendable)
}

// MARK: - Event Type

/// Semantic category of the dispatchable event.
public enum EventType: Hashable, Sendable {
    case pointerDown
    case pointerUp
    case pointerMove
    case pointerEnter
    case pointerLeave
    case tap
    case hover
    case keyDown
    case keyUp
    case scroll
    case focusIn
    case focusOut
    case custom(String)
}

// MARK: - Public-Neutral Event Object

/// Unified, platform-neutral input event passed through capture and bubbling propagation pipelines.
@MainActor
public final class Event {
    public let id: UUID
    public let timestamp: TimeInterval
    public let type: EventType
    public let targetID: ElementID
    public internal(set) var currentTargetID: ElementID?
    public internal(set) var phase: EventPhase
    public let payload: EventPayload

    public private(set) var isPropagationStopped: Bool = false
    public private(set) var isDefaultPrevented: Bool = false

    public init(
        id: UUID = UUID(),
        timestamp: TimeInterval = Date().timeIntervalSince1970,
        type: EventType,
        targetID: ElementID,
        phase: EventPhase = .capturing,
        payload: EventPayload
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.targetID = targetID
        self.currentTargetID = targetID
        self.phase = phase
        self.payload = payload
    }

    /// Stops propagation along the remaining capture, target, or bubbling path.
    public func stopPropagation() {
        self.isPropagationStopped = true
    }

    /// Instructs the engine not to execute default system actions for this event.
    public func preventDefault() {
        self.isDefaultPrevented = true
    }

    /// Helper to access pointer data if payload is `.pointer`.
    public var pointerData: PointerEventData? {
        if case .pointer(let data) = payload { return data }
        return nil
    }

    /// Helper to access key data if payload is `.key`.
    public var keyData: KeyEventData? {
        if case .key(let data) = payload { return data }
        return nil
    }

    /// Helper to access scroll data if payload is `.scroll`.
    public var scrollData: ScrollEventData? {
        if case .scroll(let data) = payload { return data }
        return nil
    }
}
