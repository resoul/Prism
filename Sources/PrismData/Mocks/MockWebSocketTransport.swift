import Foundation
import struct Flux.Flux
import class Flux.Pipe

/// Test double simulating WebSocket connections, incoming messages, and reconnection state changes.
public final class MockWebSocketTransport: @unchecked Sendable {
    private let statePipe = Pipe<WebSocketState>(bufferingPolicy: .bufferingNewest(8))
    private let messagePipe = Pipe<WebSocketMessage>(bufferingPolicy: .bufferingNewest(64))

    private let lock = NSLock()
    private var _sentMessages: [WebSocketMessage] = []
    private var _isConnected = false

    public var state: Flux<WebSocketState> {
        statePipe.flux
    }

    public var messages: Flux<WebSocketMessage> {
        messagePipe.flux
    }

    public var sentMessages: [WebSocketMessage] {
        lock.withLock { _sentMessages }
    }

    public init() {}

    public func simulateConnect() {
        lock.withLock { _isConnected = true }
        statePipe.send(.connected)
    }

    public func simulateDisconnect() {
        lock.withLock { _isConnected = false }
        statePipe.send(.disconnected)
    }

    public func simulateFailure(message: String) {
        lock.withLock { _isConnected = false }
        statePipe.send(.failed(message))
    }

    public func simulateReceive(_ message: WebSocketMessage) {
        messagePipe.send(message)
    }

    public func send(_ message: WebSocketMessage) {
        lock.withLock { _sentMessages.append(message) }
    }

    public func reset() {
        lock.withLock {
            _sentMessages.removeAll()
            _isConnected = false
        }
    }
}
