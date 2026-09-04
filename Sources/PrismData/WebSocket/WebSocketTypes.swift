import Foundation

/// Incoming or outgoing WebSocket message format.
public enum WebSocketMessage: Sendable, Equatable {
    case string(String)
    case data(Data)

    public init(_ string: String) {
        self = .string(string)
    }

    public init(_ data: Data) {
        self = .data(data)
    }
}

/// Lifecycle connection state for WebSocket client.
public enum WebSocketState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)

    public static func == (lhs: WebSocketState, rhs: WebSocketState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.reconnecting(let a), .reconnecting(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

/// Exponential backoff policy for WebSocket reconnections.
public struct ReconnectPolicy: Sendable, Equatable {
    public var maxAttempts: Int
    public var initialDelay: TimeInterval
    public var maxDelay: TimeInterval
    public var backoffMultiplier: Double
    public var jitter: Bool

    public init(
        maxAttempts: Int = 5,
        initialDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 10.0,
        backoffMultiplier: Double = 1.5,
        jitter: Bool = true
    ) {
        self.maxAttempts = max(0, maxAttempts)
        self.initialDelay = max(0.01, initialDelay)
        self.maxDelay = max(initialDelay, maxDelay)
        self.backoffMultiplier = max(1.0, backoffMultiplier)
        self.jitter = jitter
    }

    public static let `default` = ReconnectPolicy()
    public static let none = ReconnectPolicy(maxAttempts: 0)

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let exp = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        let capped = min(maxDelay, exp)
        if jitter {
            let j = Double.random(in: 0.9...1.1)
            return capped * j
        }
        return capped
    }
}
