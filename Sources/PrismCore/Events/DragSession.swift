import Foundation
import CoreGraphics

/// Lifecycle of a platform-neutral drag interaction.
public enum DragPhase: Sendable, Equatable { case idle, dragging, dropped, cancelled }

public struct DragTarget: Sendable, Equatable {
    public let id: ElementID
    public let frame: CGRect
    public let accepts: Bool
    public init(id: ElementID, frame: CGRect, accepts: Bool = true) { self.id = id; self.frame = frame; self.accepts = accepts }
}

/// Stateful drag coordinator. Hosts feed pointer or keyboard coordinates into
/// this value; no UIKit/AppKit pointer-capture object is required.
public struct DragSession: Sendable, Equatable {
    public private(set) var phase: DragPhase = .idle
    public private(set) var itemID: ElementID?
    public private(set) var pointerCaptureID: ElementID?
    public private(set) var targetID: ElementID?
    public private(set) var location: CGPoint = .zero
    public private(set) var scrollDelta: CGPoint = .zero

    public init() {}

    @discardableResult
    public mutating func begin(itemID: ElementID, at location: CGPoint) -> Bool {
        guard phase == .idle else { return false }
        phase = .dragging; self.itemID = itemID; pointerCaptureID = itemID; self.location = location; targetID = nil; scrollDelta = .zero
        return true
    }

    public mutating func update(location: CGPoint, targets: [DragTarget], viewport: CGRect? = nil) {
        guard phase == .dragging else { return }
        self.location = location
        targetID = targets.first { $0.accepts && $0.frame.contains(location) }?.id
        if let viewport, !viewport.contains(location) { scrollDelta = CGPoint(x: 0, y: location.y < viewport.minY ? location.y - viewport.minY : location.y > viewport.maxY ? location.y - viewport.maxY : 0) } else { scrollDelta = .zero }
    }

    @discardableResult
    public mutating func drop() -> ElementID? {
        guard phase == .dragging else { return nil }
        phase = targetID == nil ? .cancelled : .dropped; pointerCaptureID = nil
        let result = phase == .dropped ? targetID : nil
        return result
    }

    public mutating func cancel() { guard phase == .dragging else { return }; phase = .cancelled; pointerCaptureID = nil; targetID = nil; scrollDelta = .zero }
    public mutating func unmount(itemID: ElementID) { if self.itemID == itemID { cancel() } }
    public mutating func keyboardMove(direction: FocusDirection) {
        guard phase == .dragging else { return }
        let step = 10.0
        switch direction { case .left: location.x -= step; case .right: location.x += step; case .up: location.y -= step; case .down: location.y += step; default: break }
    }
}
