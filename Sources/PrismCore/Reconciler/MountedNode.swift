import Foundation
import QuartzCore
import Flux

/// Persistent node in the live render tree that retains element identity,
/// owns a `LayerRenderer` and its backing `CALayer`, maintains tree relationships,
/// and manages active Flux subscriptions via `SubscriptionBag`.
@MainActor
public final class MountedNode {
    public let id: ElementID
    public var element: RenderElement
    public weak var parent: MountedNode?
    public var children: [MountedNode] = []

    public let renderer: LayerRenderer
    public var rootLayer: CALayer { renderer.rootLayer }

    public let subscriptionBag: SubscriptionBag = SubscriptionBag()
    public let updateCoalescer: UpdateCoalescer = UpdateCoalescer()
    public let effectScope: EffectScope = EffectScope()
    public private(set) var isMounted: Bool = false
    public internal(set) var frame: LayoutFrame = .zero
    public weak var overlayHost: OverlayHost?

    public typealias EventHandler = @MainActor (Event) -> Void
    public private(set) var eventHandlers: [EventType: [EventHandler]] = [:]
    public private(set) var capturingHandlers: [EventType: [EventHandler]] = [:]

    public init(element: RenderElement, renderer: LayerRenderer? = nil) {
        self.id = element.id
        self.element = element
        self.renderer = renderer ?? RendererFactory.create(for: element)
    }

    /// Mounts this node into the parent hierarchy, attaches its CALayer, and triggers .onAppear.
    public func mount(in parentNode: MountedNode? = nil, superlayer: CALayer? = nil, overlayHost: OverlayHost? = nil) {
        self.parent = parentNode
        self.overlayHost = overlayHost ?? parentNode?.overlayHost
        self.isMounted = true

        let targetSuperlayer: CALayer?
        if case .portal(let targetLayer) = element.kind, let host = self.overlayHost {
            targetSuperlayer = host.containerLayer(for: targetLayer)
            host.registerPortal(node: self, layer: targetLayer)
        } else {
            targetSuperlayer = superlayer ?? parentNode?.rootLayer
        }

        if let targetSuperlayer, rootLayer.superlayer !== targetSuperlayer {
            targetSuperlayer.addSublayer(rootLayer)
        }

        effectScope.triggerAppear()
    }

    /// Updates the node with a new element snapshot, reusing the existing renderer and CALayer.
    public func update(newElement: RenderElement, frame: LayoutFrame, context: RenderContext) {
        self.element = newElement
        self.frame = frame
        if case .portal(let targetLayer) = newElement.kind, let host = self.overlayHost {
            let targetSuperlayer = host.containerLayer(for: targetLayer)
            host.registerPortal(node: self, layer: targetLayer)
            if rootLayer.superlayer !== targetSuperlayer {
                targetSuperlayer.addSublayer(rootLayer)
            }
        }
        renderer.update(element: newElement, frame: frame, context: context)
    }

    /// Registers an event handler for this mounted node.
    public func addHandler(
        for type: EventType,
        phase: EventPhase = .bubbling,
        handler: @escaping EventHandler
    ) {
        if phase == .capturing {
            capturingHandlers[type, default: []].append(handler)
        } else {
            eventHandlers[type, default: []].append(handler)
        }
    }

    /// Computes the node's origin and bounds in root host coordinates.
    public var globalFrame: CGRect {
        if case .portal = element.kind {
            return CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
        }
        var origin = CGPoint(x: frame.origin.x, y: frame.origin.y)
        var current = parent
        while let p = current {
            if case .portal = p.element.kind {
                origin.x += p.frame.origin.x
                origin.y += p.frame.origin.y
                break
            }
            origin.x += p.frame.origin.x
            origin.y += p.frame.origin.y
            current = p.parent
        }
        return CGRect(x: origin.x, y: origin.y, width: frame.width, height: frame.height)
    }

    /// Converts a point from host window coordinates into this node's local coordinate space.
    public func convertToLocal(pointInHost: CGPoint) -> CGPoint {
        let gf = globalFrame
        return CGPoint(x: pointInHost.x - gf.origin.x, y: pointInHost.y - gf.origin.y)
    }

    /// Accesses or initializes local component state for this mounted node.
    public func state<T: Sendable & Equatable>(
        name: String = "default",
        initial: () -> T
    ) -> CurrentValueDistinct<T> {
        ComponentStateStore.shared.state(for: id, name: name, initial: initial)
    }

    /// Binds this mounted node to a `CurrentValueDistinct` with automatic cancellation on unmount.
    @discardableResult
    public func bind<T: Sendable & Equatable>(
        to state: CurrentValueDistinct<T>,
        update: @MainActor @escaping (MountedNode, T) -> Void
    ) -> Subscription {
        let sub = state.flux.sinkOnMain { [weak self] value in
            guard let self, self.isMounted else { return }
            self.updateCoalescer.schedule { [weak self] in
                guard let self, self.isMounted else { return }
                update(self, value)
            }
        }
        subscriptionBag.add(sub)
        return sub
    }

    /// Binds this mounted node to a `CurrentValue` with automatic cancellation on unmount.
    @discardableResult
    public func bind<T: Sendable>(
        to state: CurrentValue<T>,
        update: @MainActor @escaping (MountedNode, T) -> Void
    ) -> Subscription {
        let sub = state.flux.sinkOnMain { [weak self] value in
            guard let self, self.isMounted else { return }
            self.updateCoalescer.schedule { [weak self] in
                guard let self, self.isMounted else { return }
                update(self, value)
            }
        }
        subscriptionBag.add(sub)
        return sub
    }

    /// Binds this mounted node to a generic `Flux` stream with automatic cancellation on unmount.
    @discardableResult
    public func bind<T: Sendable>(
        to stream: Flux<T>,
        update: @MainActor @escaping (MountedNode, T) -> Void
    ) -> Subscription {
        let sub = stream.sinkOnMain { [weak self] value in
            guard let self, self.isMounted else { return }
            self.updateCoalescer.schedule { [weak self] in
                guard let self, self.isMounted else { return }
                update(self, value)
            }
        }
        subscriptionBag.add(sub)
        return sub
    }

    /// Recursively tears down this node: cancels all subscriptions, cancels async effects,
    /// runs .onDisappear, purges component state, destroys renderer, detaches CALayer, and unmounts children.
    public func unmount() {
        guard isMounted else { return }
        isMounted = false

        if case .portal = element.kind {
            overlayHost?.unregisterPortal(id: id)
        }

        // 1. Run disappear callbacks and cancel all active effects and subscriptions
        effectScope.triggerDisappear()
        effectScope.cancelAll(reason: .unmounted)
        subscriptionBag.cancelAll()
        updateCoalescer.cancel()

        // 2. Purge local component state
        ComponentStateStore.shared.purge(for: id)

        // 3. Unmount children recursively
        for child in children {
            child.unmount()
        }
        children.removeAll()

        // 4. Destroy renderer and detach layer
        renderer.destroy()
        rootLayer.removeFromSuperlayer()
        parent = nil
    }


    /// Produces a human-readable visual dump of the mounted node hierarchy.
    public func dumpTree(indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var line = "\(prefix)MountedNode[\(id)] (kind: \(element.kind))"
        line += " [layer: \(type(of: rootLayer))]"
        if subscriptionBag.count > 0 {
            line += " [subscriptions: \(subscriptionBag.count)]"
        }

        if children.isEmpty {
            return line
        }

        let childLines = children.map { $0.dumpTree(indent: indent + 1) }.joined(separator: "\n")
        return "\(line)\n\(childLines)"
    }
}

