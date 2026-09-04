#if canImport(UIKit)
import UIKit

/// Thin UIKit host view embedding a Prism Virtual Render Tree.
/// Provides safe area insets, display scale factor, trait updates, and attaches the root CALayer.
@MainActor
public final class HostUIView: UIView, PrismHost {
    public let engine: PrismHostEngine

    public var isInspectorOverlayEnabled: Bool {
        get { engine.isInspectorOverlayEnabled }
        set { engine.isInspectorOverlayEnabled = newValue }
    }

    public var onMount: (() -> Void)?
    public var onBoundsChange: ((CGRect) -> Void)?
    public var onColorSchemeChange: ((ColorScheme) -> Void)?
    public var onTeardown: (() -> Void)?

    public init(element: RenderElement) {
        self.engine = PrismHostEngine(rootElement: element)
        super.init(frame: .zero)
        setupHost()
    }

    public required init?(coder: NSCoder) {
        self.engine = PrismHostEngine(rootElement: RenderElement(id: ElementID(typeName: "Empty"), kind: .empty))
        super.init(coder: coder)
        setupHost()
    }

    private func setupHost() {
        engine.mount(in: self.layer)
        updateFromSystem()
    }

    public func setRootElement(_ element: RenderElement) {
        engine.rootElement = element
    }

    public func render() {
        updateFromSystem()
        engine.render()
    }

    public func teardown() {
        onTeardown?()
        engine.teardown()
    }

    public var colorScheme: ColorScheme {
        traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }

    public var scaleFactor: Double {
        #if os(iOS) || os(tvOS)
        let screenScale = window?.screen.scale ?? UIScreen.main.scale
        return Double(screenScale)
        #else
        return 2.0
        #endif
    }

    public var safeAreaDirectionalInsets: DirectionalEdgeInsets {
        DirectionalEdgeInsets(
            top: Double(safeAreaInsets.top),
            leading: Double(safeAreaInsets.left),
            bottom: Double(safeAreaInsets.bottom),
            trailing: Double(safeAreaInsets.right)
        )
    }

    private func updateFromSystem() {
        engine.bounds = bounds
        engine.scaleFactor = scaleFactor
        engine.colorScheme = colorScheme
        engine.safeAreaInsets = safeAreaDirectionalInsets
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let oldBounds = engine.bounds
        updateFromSystem()
        if oldBounds != bounds {
            onBoundsChange?(bounds)
        }
        engine.render()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            updateFromSystem()
            engine.render()
            onMount?()
        } else {
            teardown()
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let newScheme = colorScheme
            engine.colorScheme = newScheme
            onColorSchemeChange?(newScheme)
            engine.render()
        }
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        engine.safeAreaInsets = safeAreaDirectionalInsets
        engine.render()
    }

    public func findAccessibilityElement(byTestID testID: String) -> AccessibilityElement? {
        engine.accessibilityTree.findElement(byTestID: testID)
    }

    // MARK: - Touch & Press Handling

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        engine.dispatchPointerEvent(
            type: .pointerDown,
            location: loc,
            button: .primary,
            pointerType: .touch,
            modifiers: .none,
            clickCount: touch.tapCount
        )
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        engine.dispatchPointerEvent(
            type: .pointerMove,
            location: loc,
            button: .primary,
            pointerType: .touch,
            modifiers: .none,
            clickCount: touch.tapCount
        )
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        engine.dispatchPointerEvent(
            type: .pointerUp,
            location: loc,
            button: .primary,
            pointerType: .touch,
            modifiers: .none,
            clickCount: touch.tapCount
        )
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        engine.eventDispatcher.reset()
    }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if let key = press.key {
                let characters = key.characters
                let charsIgnoring = key.charactersIgnoringModifiers
                let handled = engine.dispatchKeyEvent(
                    type: .keyDown,
                    key: characters,
                    characters: characters,
                    charactersIgnoringModifiers: charsIgnoring,
                    keyCode: UInt16(key.keyCode.rawValue),
                    modifiers: convertKeyModifierFlags(key.modifierFlags),
                    isRepeat: false
                )
                if handled == .handled {
                    return
                }
            }
        }
        super.pressesBegan(presses, with: event)
    }

    public override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if let key = press.key {
                let characters = key.characters
                let charsIgnoring = key.charactersIgnoringModifiers
                engine.dispatchKeyEvent(
                    type: .keyUp,
                    key: characters,
                    characters: characters,
                    charactersIgnoringModifiers: charsIgnoring,
                    keyCode: UInt16(key.keyCode.rawValue),
                    modifiers: convertKeyModifierFlags(key.modifierFlags),
                    isRepeat: false
                )
            }
        }
        super.pressesEnded(presses, with: event)
    }

    private func convertKeyModifierFlags(_ flags: UIKeyModifierFlags) -> EventModifiers {
        var mods: EventModifiers = .none
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.control) { mods.insert(.control) }
        if flags.contains(.alternate) { mods.insert(.option) }
        if flags.contains(.command) { mods.insert(.command) }
        if flags.contains(.alphaShift) { mods.insert(.capsLock) }
        return mods
    }
}
#endif
