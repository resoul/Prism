import Foundation
import XCTest
@testable import PrismLogging

final class PrismLoggingTests: XCTestCase {
    func testLoggingSubsystem() {
        XCTAssertEqual(PrismLogging.subsystem, "dev.prism.ui")
    }

    struct TestEvent: PrismLogEvent {
        let category: String = "test"
        let message: String = "hello log"
    }

    func testLogEvent() {
        let event = TestEvent()
        XCTAssertEqual(event.category, "test")
        XCTAssertEqual(event.message, "hello log")
    }

    func testSanitizedLineRedactsPrivateAndSensitiveMetadata() {
        let record = LogRecord(
            level: .info,
            category: .http,
            message: "Request completed",
            metadata: [
                "status": .public(200),
                "token": .sensitive("very-secret-token"),
                "profile": .private("user-42"),
                "url": .url(URL(string: "https://example.com?token=secret")!)
            ],
            source: .init(file: "Test.swift", function: "test", line: 1)
        )

        let line = record.sanitizedLine()
        XCTAssertTrue(line.contains("status=200"))
        XCTAssertTrue(line.contains("profile=<private>"))
        XCTAssertTrue(line.contains("token=<redacted>"))
        XCTAssertTrue(line.contains("url=<private>"))
        XCTAssertFalse(line.contains("very-secret-token"))
        XCTAssertFalse(line.contains("user-42"))
        XCTAssertFalse(line.contains("example.com"))
    }

    func testTraceContextIsAttachedToLoggerRecords() async {
        let sink = RecordingSink()
        let system = LoggingSystem { sink }
        let expected = LogTraceContext()

        await LogTrace.withTrace(expected) {
            system.logger(category: .vrt).info("Mounted")
            await eventually { await sink.records().count == 1 }
        }

        let record = await sink.records().first
        XCTAssertEqual(record?.trace, expected)
    }

    func testBoundedQueueDropsExcessRecords() async {
        let sink = DelayedSink(delayNanoseconds: 150_000_000)
        let system = LoggingSystem(configuration: .init(maximumPendingRecords: 1)) { sink }
        let logger = system.logger(category: .scroll)

        logger.info("first")
        logger.info("second")
        logger.info("third")

        await eventually { (await system.metrics()).droppedRecords > 0 }
        let metrics = await system.metrics()
        XCTAssertGreaterThan(metrics.droppedRecords, 0)
    }

    func testFileSinkWritesOnlySanitizedNDJSONAndRotates() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sink = FileSink(
            directory: directory,
            minimumLevel: .trace,
            rotation: .keepFiles(count: 2, maximumBytes: 180)
        )
        let logger = LoggingSystem { sink }.logger(category: .cache)

        logger.info("first", metadata: ["token": .sensitive("never-write-me")])
        logger.info("second", metadata: ["name": .private("Ada")])
        logger.info("third", metadata: ["count": .public(3)])

        await eventually { ((try? await sink.exportedLines().count) ?? 0) >= 1 }
        let lines = try await sink.exportedLines()
        XCTAssertFalse(lines.isEmpty)
        XCTAssertFalse(lines.joined(separator: "\n").contains("never-write-me"))
        XCTAssertFalse(lines.joined(separator: "\n").contains("Ada"))
        XCTAssertTrue(lines.allSatisfy { line in
            guard let data = line.data(using: .utf8) else { return false }
            return (try? JSONSerialization.jsonObject(with: data)) != nil
        })
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertTrue(urls.contains { $0.lastPathComponent == "prism.1.ndjson" })
    }

    private func eventually(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @Sendable () async -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await condition() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for asynchronous logging work")
    }
}

private actor RecordingSink: LogSink {
    private var values: [LogRecord] = []
    func emit(_ record: LogRecord) async { values.append(record) }
    func records() -> [LogRecord] { values }
}

private actor DelayedSink: LogSink {
    private let delayNanoseconds: UInt64
    init(delayNanoseconds: UInt64) { self.delayNanoseconds = delayNanoseconds }
    func emit(_ record: LogRecord) async { try? await Task.sleep(nanoseconds: delayNanoseconds) }
}
