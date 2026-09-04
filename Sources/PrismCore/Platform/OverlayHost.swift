import Foundation
import CoreGraphics
import QuartzCore

// MARK: - Overlay Layers & Ordering

/// Named overlay tiers with strict z-ordering and hit-test precedence.
public enum OverlayLayer: String, Sendable, CaseIterable, Hashable, Comparable {
    /// Base application content (z-order: 0).
    case content
    /// Floating elements: popovers, tooltips, dropdown menus (z-order: 1000).
    case floating
    /// Modal dialogs, action sheets, bottom sheets with optional backdrop (z-order: 2000).
    case modal
    /// Transient notification banners, toasts, snackbars (z-order: 3000).
    case toast
    /// Debug overlays, wireframes, inspectors (z-order: 4000).
    case debug

    public var zIndex: Int {
        switch self {
        case .content:  return 0
        case .floating: return 1000
        case .modal:    return 2000
        case .toast:    return 3000
        case .debug:    return 4000
        }
    }

    public static func < (lhs: OverlayLayer, rhs: OverlayLayer) -> Bool {
        lhs.zIndex < rhs.zIndex
    }
}

// MARK: - Dismiss Reasons

/// The cause triggering an overlay dismissal.
public enum DismissReason: Sendable, Equatable {
    /// The user tapped or clicked outside the overlay on the backdrop.
    case backdropTap
    /// The user pressed the Escape key.
    case escapeKey
    /// Programmatic dismissal or user clicked an explicit close action.
    case explicitClose
    /// The anchor element to which this overlay was anchored was unmounted.
    case anchorUnmounted
    /// A display timeout expired (used for transient toasts).
    case timeout
}

// MARK: - Overlay Positioning

public enum OverlayEdge: Sendable, Equatable {
    case top
    case bottom
    case leading
    case trailing
}

public enum OverlayAlignment: Sendable, Equatable {
    case start
    case center
    case end
}

/// Geometric positioning strategy for an overlay.
public enum OverlayPositioning: Sendable, Equatable {
    case center
    case anchored(anchorID: String, edge: OverlayEdge, alignment: OverlayAlignment, offset: Double)
    case fixed(x: Double, y: Double)
}

// MARK: - Overlay Entry

/// Represents an active overlay presented within an OverlayHost.
@MainActor
public final class OverlayEntry {
    public let id: ElementID
    public let layer: OverlayLayer
    public let node: MountedNode
    public var positioning: OverlayPositioning
    public var blocksBackgroundPointer: Bool
    public var isFocusTrapped: Bool
    public var previousFocusID: ElementID?
    public var onDismiss: (@MainActor (DismissReason) -> Void)?

    public init(
        id: ElementID,
        layer: OverlayLayer,
        node: MountedNode,
        positioning: OverlayPositioning = .center,
        blocksBackgroundPointer: Bool = false,
        isFocusTrapped: Bool = false,
        previousFocusID: ElementID? = nil,
        onDismiss: (@MainActor (DismissReason) -> Void)? = nil
    ) {
        self.id = id
        self.layer = layer
        self.node = node
        self.positioning = positioning
        self.blocksBackgroundPointer = blocksBackgroundPointer
        self.isFocusTrapped = isFocusTrapped
        self.previousFocusID = previousFocusID
        self.onDismiss = onDismiss
    }
}

// MARK: - Overlay Host

/// Host-level manager organizing overlay layers, modal backdrops, focus trapping,
/// and anchored positioning across the entire window viewport.
@MainActor
public final class OverlayHost {

    public let contentContainer: CALayer = CALayer()
    public let floatingContainer: CALayer = CALayer()
    public let modalContainer: CALayer = CALayer()
    public let toastContainer: CALayer = CALayer()
    public let debugContainer: CALayer = CALayer()
    public let backdropLayer: CALayer = CALayer()

    public private(set) var activeEntries: [ElementID: OverlayEntry] = [:]
    /// Presentation order is explicit: dictionary iteration must never choose the top overlay.
    public private(set) var presentationOrder: [ElementID] = []
    public private(set) var activePortals: [ElementID: (layer: OverlayLayer, node: MountedNode)] = [:]
    public weak var engine: PrismHostEngine?

    public init() {
        setupContainers()
    }

    public func registerPortal(node: MountedNode, layer: OverlayLayer) {
        activePortals[node.id] = (layer, node)
    }

    public func unregisterPortal(id: ElementID) {
        activePortals.removeValue(forKey: id)
    }

    private func setupContainers() {
        contentContainer.name = "PrismOverlay.content"
        floatingContainer.name = "PrismOverlay.floating"
        modalContainer.name = "PrismOverlay.modal"
        toastContainer.name = "PrismOverlay.toast"
        debugContainer.name = "PrismOverlay.debug"

        // Overlays do not clip children to allow tooltips/popovers to extend
        floatingContainer.masksToBounds = false
        modalContainer.masksToBounds = false
        toastContainer.masksToBounds = false
        debugContainer.masksToBounds = false

        // Configure semi-transparent modal backdrop
        backdropLayer.name = "PrismOverlay.backdrop"
        backdropLayer.backgroundColor = CGColor(gray: 0.0, alpha: 0.4)
        backdropLayer.isHidden = true
        modalContainer.addSublayer(backdropLayer)
    }

    /// Attaches all overlay tier containers into the root host layer in ascending z-order.
    public func mountContainers(into hostLayer: CALayer) {
        ensureMounted(floatingContainer, zPosition: 1000)
        ensureMounted(modalContainer, zPosition: 2000)
        ensureMounted(toastContainer, zPosition: 3000)
        ensureMounted(debugContainer, zPosition: 4000)
        updateBounds(hostLayer.bounds)
    }

    /// Updates bounds for all overlay container layers.
    public func updateBounds(_ bounds: CGRect) {
        contentContainer.frame = bounds
        floatingContainer.frame = bounds
        modalContainer.frame = bounds
        toastContainer.frame = bounds
        debugContainer.frame = bounds
        backdropLayer.frame = bounds
    }

    /// Returns the CALayer container for a given overlay tier.
    public func containerLayer(for layer: OverlayLayer) -> CALayer {
        switch layer {
        case .content:
            return engine?.rootRenderer.rootLayer ?? contentContainer
        case .floating:
            ensureMounted(floatingContainer, zPosition: 1000)
            return floatingContainer
        case .modal:
            ensureMounted(modalContainer, zPosition: 2000)
            return modalContainer
        case .toast:
            ensureMounted(toastContainer, zPosition: 3000)
            return toastContainer
        case .debug:
            ensureMounted(debugContainer, zPosition: 4000)
            return debugContainer
        }
    }

    private func ensureMounted(_ container: CALayer, zPosition: CGFloat) {
        guard let hostLayer = engine?.hostLayer else { return }
        if container.superlayer !== hostLayer {
            container.zPosition = zPosition
            container.frame = hostLayer.bounds
            hostLayer.addSublayer(container)
        }
    }

    // MARK: - Presentation & Dismissal Lifecycle

    /// Presents a new overlay entry into its target tier.
    public func present(_ entry: OverlayEntry) {
        // Prism deliberately permits only one blocking modal. Replacing it first guarantees
        // that focus, backdrop, and accessibility ownership never become ambiguous.
        if entry.layer == .modal {
            for existingID in presentationOrder where activeEntries[existingID]?.layer == .modal {
                dismiss(id: existingID, reason: .explicitClose)
            }
        }
        presentationOrder.removeAll { $0 == entry.id }
        activeEntries[entry.id] = entry
        presentationOrder.append(entry.id)
        let targetContainer = containerLayer(for: entry.layer)

        if entry.node.rootLayer.superlayer !== targetContainer {
            targetContainer.addSublayer(entry.node.rootLayer)
        }

        if entry.layer == .modal {
            backdropLayer.isHidden = false
            entry.previousFocusID = engine?.focusTree.currentFocus

            // Focus first focusable node in modal
            if let firstFocusable = engine?.focusTree.collectFocusableNodes(in: entry.node).first {
                engine?.focusTree.setFocus(to: firstFocusable.id)
            }
        }

        updateOverlayPositions()
    }

    /// Dismisses an overlay entry with a specified reason, restoring focus and cleaning up layers.
    public func dismiss(id: ElementID, reason: DismissReason = .explicitClose) {
        guard let entry = activeEntries.removeValue(forKey: id) else { return }
        presentationOrder.removeAll { $0 == id }

        entry.onDismiss?(reason)
        entry.node.unmount()
        entry.node.rootLayer.removeFromSuperlayer()

        // If closing a modal, manage backdrop and restore focus
        if entry.layer == .modal {
            let remainingModals = activeEntries.values.filter { $0.layer == .modal }
            if remainingModals.isEmpty {
                backdropLayer.isHidden = true
            }

            if let prevFocus = entry.previousFocusID {
                engine?.focusTree.setFocus(to: prevFocus)
            }
        }
    }

    /// Dismisses the top-most active modal when the Escape key is pressed.
    @discardableResult
    public func handleEscapeKey() -> Bool {
        if let topModal = presentationOrder.reversed().compactMap({ activeEntries[$0] }).first(where: { $0.layer == .modal }) {
            dismiss(id: topModal.id, reason: .escapeKey)
            return true
        }
        return false
    }

    /// Handles pointer taps on the modal backdrop.
    @discardableResult
    public func handleBackdropTap() -> Bool {
        guard let topModal = presentationOrder.reversed().compactMap({ activeEntries[$0] }).first(where: { $0.layer == .modal }), topModal.blocksBackgroundPointer else {
            return false
        }
        dismiss(id: topModal.id, reason: .backdropTap)
        return true
    }

    /// Updates geometric positions of all active overlays based on anchor registry and viewport bounds.
    public func updateOverlayPositions() {
        guard let engine = engine else { return }
        let viewport = engine.bounds

        for entry in activeEntries.values {
            let node = entry.node
            let nodeSize = CGSize(width: node.frame.width, height: node.frame.height)

            switch entry.positioning {
            case .center:
                let x = max(0, (viewport.width - nodeSize.width) / 2.0)
                let y = max(0, (viewport.height - nodeSize.height) / 2.0)
                node.frame = LayoutFrame(x: x, y: y, width: nodeSize.width, height: nodeSize.height)
                node.rootLayer.frame = CGRect(x: x, y: y, width: nodeSize.width, height: nodeSize.height)

            case .fixed(let x, let y):
                node.frame = LayoutFrame(x: x, y: y, width: nodeSize.width, height: nodeSize.height)
                node.rootLayer.frame = CGRect(x: x, y: y, width: nodeSize.width, height: nodeSize.height)

            case .anchored(let anchorID, let edge, let alignment, let offset):
                if let anchorNode = engine.findNodeByAnchor(anchorID) {
                    let anchorFrame = anchorNode.globalFrame
                    let pos = computeAnchoredPosition(
                        anchorFrame: anchorFrame,
                        overlaySize: nodeSize,
                        edge: edge,
                        alignment: alignment,
                        offset: offset,
                        viewport: viewport
                    )
                    node.frame = LayoutFrame(x: pos.x, y: pos.y, width: nodeSize.width, height: nodeSize.height)
                    node.rootLayer.frame = CGRect(x: pos.x, y: pos.y, width: nodeSize.width, height: nodeSize.height)
                } else {
                    // Anchor unmounted: dismiss overlay
                    dismiss(id: entry.id, reason: .anchorUnmounted)
                }
            }
        }
    }

    private func computeAnchoredPosition(
        anchorFrame: CGRect,
        overlaySize: CGSize,
        edge: OverlayEdge,
        alignment: OverlayAlignment,
        offset: Double,
        viewport: CGRect
    ) -> CGPoint {
        var x: Double = 0
        var y: Double = 0

        switch edge {
        case .bottom:
            y = anchorFrame.maxY + offset
            switch alignment {
            case .start:  x = anchorFrame.minX
            case .center: x = anchorFrame.midX - (overlaySize.width / 2.0)
            case .end:    x = anchorFrame.maxX - overlaySize.width
            }

        case .top:
            y = anchorFrame.minY - overlaySize.height - offset
            switch alignment {
            case .start:  x = anchorFrame.minX
            case .center: x = anchorFrame.midX - (overlaySize.width / 2.0)
            case .end:    x = anchorFrame.maxX - overlaySize.width
            }

        case .trailing:
            x = anchorFrame.maxX + offset
            switch alignment {
            case .start:  y = anchorFrame.minY
            case .center: y = anchorFrame.midY - (overlaySize.height / 2.0)
            case .end:    y = anchorFrame.maxY - overlaySize.height
            }

        case .leading:
            x = anchorFrame.minX - overlaySize.width - offset
            switch alignment {
            case .start:  y = anchorFrame.minY
            case .center: y = anchorFrame.midY - (overlaySize.height / 2.0)
            case .end:    y = anchorFrame.maxY - overlaySize.height
            }
        }

        // Clamp within viewport boundaries to prevent offscreen clipping
        x = max(0, min(x, viewport.width - overlaySize.width))
        y = max(0, min(y, viewport.height - overlaySize.height))

        return CGPoint(x: x, y: y)
    }

    /// Tears down all active overlays and resets container hierarchies cleanly.
    public func teardown() {
        for entry in activeEntries.values {
            entry.node.unmount()
            entry.node.rootLayer.removeFromSuperlayer()
        }
        activeEntries.removeAll()
        presentationOrder.removeAll()
        activePortals.removeAll()
        backdropLayer.removeFromSuperlayer()
        contentContainer.removeFromSuperlayer()
        floatingContainer.removeFromSuperlayer()
        modalContainer.removeFromSuperlayer()
        toastContainer.removeFromSuperlayer()
        debugContainer.removeFromSuperlayer()
    }
}
