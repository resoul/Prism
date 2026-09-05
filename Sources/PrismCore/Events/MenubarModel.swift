import Foundation

public enum MenuKey: Sendable { case up, down, left, right, enter, escape, character(Character) }
public struct MenuCommand: Sendable, Equatable {
    public let id: String; public let title: String; public var isEnabled: Bool; public let shortcut: Character?
    public init(id: String, title: String, isEnabled: Bool = true, shortcut: Character? = nil) { self.id = id; self.title = title; self.isEnabled = isEnabled; self.shortcut = shortcut }
}
public struct MenubarModel: Sendable, Equatable {
    public let menus: [[MenuCommand]]
    public private(set) var menuIndex: Int?; public private(set) var itemIndex: Int; public private(set) var previousFocusID: String?
    public init(menus: [[MenuCommand]], previousFocusID: String? = nil) { self.menus = menus; self.previousFocusID = previousFocusID; self.menuIndex = nil; self.itemIndex = 0 }
    public mutating func open(menu index: Int) { guard menus.indices.contains(index) else { return }; menuIndex = index; itemIndex = firstEnabled(in: index) ?? 0 }
    public mutating func close() { menuIndex = nil; itemIndex = 0 }
    public mutating func handle(_ key: MenuKey) -> String? {
        switch key {
        case .escape: close(); return nil
        case .right: open(menu: min((menuIndex ?? -1) + 1, max(0, menus.count - 1)))
        case .left: open(menu: max((menuIndex ?? 0) - 1, 0))
        case .up: move(-1)
        case .down: move(1)
        case .enter: return activate()
        case .character(let char): return shortcut(char)
        }
        return nil
    }
    public mutating func activate() -> String? { guard let menuIndex, menus[menuIndex].indices.contains(itemIndex), menus[menuIndex][itemIndex].isEnabled else { return nil }; return menus[menuIndex][itemIndex].id }
    private mutating func move(_ delta: Int) { guard let menuIndex else { return }; let enabled = menus[menuIndex].indices.filter { menus[menuIndex][$0].isEnabled }; guard !enabled.isEmpty else { return }; let current = enabled.firstIndex(of: itemIndex) ?? 0; itemIndex = enabled[(current + delta + enabled.count) % enabled.count] }
    private func firstEnabled(in index: Int) -> Int? { menus[index].firstIndex { $0.isEnabled } }
    private func shortcut(_ char: Character) -> String? { for menu in menus { if let command = menu.first(where: { $0.isEnabled && $0.shortcut?.lowercased() == char.lowercased() }) { return command.id } }; return nil }
}
