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
    public private(set) var isMounted: Bool = false

    public init(element: RenderElement) {
        self.id = element.id
        self.element = element
        self.renderer = RendererFactory.create(for: element)
    }

    /// Mounts this node into the parent hierarchy and attaches its CALayer.
    public func mount(in parentNode: MountedNode? = nil, superlayer: CALayer? = nil) {
        self.parent = parentNode
        self.isMounted = true

        let targetSuperlayer = superlayer ?? parentNode?.rootLayer
        if let targetSuperlayer, rootLayer.superlayer !== targetSuperlayer {
            targetSuperlayer.addSublayer(rootLayer)
        }
    }

    /// Updates the node with a new element snapshot, reusing the existing renderer and CALayer.
    public func update(newElement: RenderElement, frame: LayoutFrame, context: RenderContext) {
        self.element = newElement
        renderer.update(element: newElement, frame: frame, context: context)
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

    /// Recursively tears down this node: cancels all subscriptions, destroys renderer,
    /// detaches CALayer from superlayer, and unmounts all children.
    public func unmount() {
        guard isMounted else { return }
        isMounted = false

        // 1. Cancel all active Flux subscriptions and pending coalesced tasks
        subscriptionBag.cancelAll()
        updateCoalescer.cancel()

        // 2. Unmount children recursively
        for child in children {
            child.unmount()
        }
        children.removeAll()

        // 3. Destroy renderer and detach layer
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

