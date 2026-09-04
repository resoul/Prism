import XCTest
import Foundation
@testable import PrismData
import struct Flux.Flux

final class WebSocketClientTests: XCTestCase {

    func testMockWebSocketTransportStateTransitions() async {
        let mockTransport = MockWebSocketTransport()
        let expectation = expectation(description: "State transitioned to connected")

        var receivedStates: [WebSocketState] = []
        let task = Task {
            for await state in mockTransport.state.stream {
                receivedStates.append(state)
                if state == .connected {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Give the stream subscriber task a brief moment to start iterating
        try? await Task.sleep(nanoseconds: 50_000_000)

        mockTransport.simulateConnect()
        await fulfillment(of: [expectation], timeout: 3.0)
        task.cancel()

        XCTAssertEqual(receivedStates, [.connected])
    }

    func testMockWebSocketTransportReceivesMessages() async {
        let mockTransport = MockWebSocketTransport()
        let expectation = expectation(description: "Received 2 messages")

        var receivedMessages: [WebSocketMessage] = []
        let task = Task {
            for await msg in mockTransport.messages.stream {
                receivedMessages.append(msg)
                if receivedMessages.count == 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Give the stream subscriber task a brief moment to start iterating
        try? await Task.sleep(nanoseconds: 50_000_000)

        mockTransport.simulateReceive(.string("Hello Prism"))
        mockTransport.simulateReceive(.data(Data([0x01, 0x02, 0x03])))

        await fulfillment(of: [expectation], timeout: 3.0)
        task.cancel()

        XCTAssertEqual(receivedMessages, [
            .string("Hello Prism"),
            .data(Data([0x01, 0x02, 0x03]))
        ])
    }

    func testMockWebSocketTransportSending() {
        let mockTransport = MockWebSocketTransport()
        mockTransport.send(.string("ping"))
        mockTransport.send(.data(Data([0xFF])))

        XCTAssertEqual(mockTransport.sentMessages.count, 2)
        XCTAssertEqual(mockTransport.sentMessages[0], .string("ping"))
        XCTAssertEqual(mockTransport.sentMessages[1], .data(Data([0xFF])))

        mockTransport.reset()
        XCTAssertEqual(mockTransport.sentMessages.count, 0)
    }

    func testReconnectPolicyDelays() {
        let policy = ReconnectPolicy(
            maxAttempts: 5,
            initialDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitter: false
        )

        XCTAssertEqual(policy.delay(forAttempt: 0), 0)
        XCTAssertEqual(policy.delay(forAttempt: 1), 1.0)
        XCTAssertEqual(policy.delay(forAttempt: 2), 2.0)
        XCTAssertEqual(policy.delay(forAttempt: 3), 4.0)
        XCTAssertEqual(policy.delay(forAttempt: 4), 8.0)
        XCTAssertEqual(policy.delay(forAttempt: 5), 10.0) // Clamped by maxDelay
        XCTAssertEqual(policy.delay(forAttempt: 6), 10.0) // Clamped by maxDelay
    }

    func testWebSocketMessageInitializers() {
        let strMsg = WebSocketMessage("text payload")
        XCTAssertEqual(strMsg, .string("text payload"))

        let data = Data([0xAA, 0xBB])
        let dataMsg = WebSocketMessage(data)
        XCTAssertEqual(dataMsg, .data(data))
    }
}
