import XCTest
@testable import PrismCore

final class CommandPaletteTests: XCTestCase {
    func testSearchExecuteAndDismiss() async throws {
        let engine = CommandPaletteEngine { query in [PaletteCommand(id: "save", title: "Save \(query)")] }
        await engine.open(); await engine.search("sa"); try await Task.sleep(nanoseconds: 20_000_000)
        let snapshot = await engine.snapshotValue(); XCTAssertEqual(snapshot.results.first?.id, "save")
        let executed = await engine.execute(id: "save"); XCTAssertEqual(executed, "save")
        await engine.dismiss(); let dismissed = await engine.snapshotValue(); XCTAssertFalse(dismissed.isPresented)
    }
    func testStaleResultsAndShortcutScopes() async throws {
        let engine = CommandPaletteEngine { query in if query == "old" { try await Task.sleep(nanoseconds: 50_000_000) }; return [PaletteCommand(id: query, title: query)] }
        await engine.open(); await engine.search("old"); await engine.search("new"); try await Task.sleep(nanoseconds: 80_000_000)
        let latest = await engine.snapshotValue(); XCTAssertEqual(latest.results.first?.id, "new")
        var registry = CommandRegistry(commands: [PaletteCommand(id: "global", title: "Global", shortcut: "k"), PaletteCommand(id: "local", title: "Local", scope: "editor", shortcut: "k")])
        XCTAssertEqual(registry.resolveShortcut("K", scope: "editor")?.id, "global"); registry.register(PaletteCommand(id: "global", title: "Global", shortcut: "k", isEnabled: false)); XCTAssertEqual(registry.resolveShortcut("k", scope: "editor")?.id, "local")
    }
}
