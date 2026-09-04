import Foundation
import struct Flux.Flux
import class Flux.Pipe

/// Resilient WebSocket client built on `URLSessionWebSocketTask` with automatic reconnects and Flux streams.
public final class WebSocketClient: @unchecked Sendable {
    public let url: URL
    public let reconnectPolicy: ReconnectPolicy
    private let session: URLSession

    private let statePipe = Pipe<WebSocketState>(bufferingPolicy: .bufferingNewest(8))
    private let messagePipe = Pipe<WebSocketMessage>(bufferingPolicy: .bufferingNewest(64))

    private let lock = NSLock()
    private var task: URLSessionWebSocketTask?
    private var currentState: WebSocketState = .disconnected
    private var shouldReconnect = false
    private var reconnectAttempt = 0
    private var receiveLoopTask: Task<Void, Never>?

    public var state: Flux<WebSocketState> {
        statePipe.flux
    }

    public var messages: Flux<WebSocketMessage> {
        messagePipe.flux
    }

    public init(
        url: URL,
        session: URLSession = .shared,
        reconnectPolicy: ReconnectPolicy = .default
    ) {
        self.url = url
        self.session = session
        self.reconnectPolicy = reconnectPolicy
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Lifecycle

    /// Establishes the WebSocket connection.
    public func connect() {
        lock.lock()
        shouldReconnect = true
        guard currentState == .disconnected || currentState == .failed("") else {
            lock.unlock()
            return
        }
        updateState(.connecting)
        lock.unlock()

        startConnection()
    }

    /// Gracefully closes the WebSocket connection and suppresses automatic reconnections.
    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode = .normalClosure) {
        lock.lock()
        shouldReconnect = false
        receiveLoopTask?.cancel()
        receiveLoopTask = nil

        let currentTask = task
        task = nil
        updateState(.disconnected)
        lock.unlock()

        currentTask?.cancel(with: closeCode, reason: nil)
    }

    /// Sends a WebSocket message.
    public func send(_ message: WebSocketMessage) async throws {
        let currentTask = lock.withLock { task }
        guard let currentTask, currentState == .connected else {
            throw HTTPError.transportError(URLError(.notConnectedToInternet))
        }

        let nativeMessage: URLSessionWebSocketTask.Message
        switch message {
        case .string(let str):
            nativeMessage = .string(str)
        case .data(let data):
            nativeMessage = .data(data)
        }

        try await currentTask.send(nativeMessage)
    }

    // MARK: - Internal Engine

    private func startConnection() {
        let wsTask = session.webSocketTask(with: url)

        lock.lock()
        task = wsTask
        lock.unlock()

        wsTask.resume()

        // Send a ping to confirm connection
        wsTask.sendPing { [weak self, weak wsTask] error in
            guard let self, let wsTask else { return }
            self.lock.lock()
            guard self.task === wsTask else {
                self.lock.unlock()
                return
            }

            if let error {
                self.lock.unlock()
                self.handleFailure(error)
            } else {
                self.reconnectAttempt = 0
                self.updateState(.connected)
                self.lock.unlock()
                self.startReceiveLoop(for: wsTask)
            }
        }
    }

    private func startReceiveLoop(for wsTask: URLSessionWebSocketTask) {
        receiveLoopTask?.cancel()
        receiveLoopTask = Task { [weak self, weak wsTask] in
            while !Task.isCancelled {
                guard let self, let wsTask else { break }

                do {
                    let message = try await wsTask.receive()
                    switch message {
                    case .string(let str):
                        self.messagePipe.send(.string(str))
                    case .data(let data):
                        self.messagePipe.send(.data(data))
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        self.handleFailure(error)
                    }
                    break
                }
            }
        }
    }

    private func handleFailure(_ error: any Error) {
        lock.lock()
        guard shouldReconnect else {
            updateState(.failed(error.localizedDescription))
            lock.unlock()
            return
        }

        reconnectAttempt += 1
        if reconnectAttempt <= reconnectPolicy.maxAttempts {
            updateState(.reconnecting(attempt: reconnectAttempt))
            let delay = reconnectPolicy.delay(forAttempt: reconnectAttempt)
            lock.unlock()

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self, self.shouldReconnect else { return }
                self.startConnection()
            }
        } else {
            updateState(.failed("Max reconnect attempts reached (\(reconnectAttempt))"))
            lock.unlock()
        }
    }

    private func updateState(_ newState: WebSocketState) {
        currentState = newState
        statePipe.send(newState)
    }
}
