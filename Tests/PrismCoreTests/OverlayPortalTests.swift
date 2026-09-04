import XCTest
import CoreGraphics
import QuartzCore
@testable import PrismCore
@testable import PrismUI

@MainActor
final class OverlayPortalTests: XCTestCase {

    // MARK: - 1. Portal Escapes Clipped Container

    func testPortalEscapesClippedContainerWhilePreservingBubbling() {
        var buttonClicked = false
        var parentReceivedClick = false

        let root = VStack(spacing: 10) {
            // Clipped container (e.g. ScrollArea/Card) with bounds (0, 0, 100, 100)
            RenderElement(
                id: ElementID(typeName: "ClippedBox"),
                kind: .custom("ClippedBox"),
                children: [
                    // Non-portal button outside clipped frame
                    RenderElement(
                        id: ElementID(typeName: "NormalButton"),
                        kind: .custom("NormalButton")
                    ).frame(width: 50, height: 50),

                    // Portal projected into floating tier
                    Portal(layer: .floating) {
                        RenderElement(
                            id: ElementID(typeName: "PortalButton"),
                            kind: .custom("PortalButton")
                        ).frame(width: 50, height: 50)
                    }.render()
                ]
            )
            .clipped(true)
            .frame(width: 100, height: 100)
        }

        let engine = PrismHostEngine(rootElement: root.render())
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.mount(in: hostLayer)

        guard let clippedNode = engine.findNode(by: ElementID(typeName: "ClippedBox")),
              let portalNode = clippedNode.children.first(where: {
                  if case .portal = $0.element.kind { return true }
                  return false
              }),
              let portalButtonNode = portalNode.children.first else {
            XCTFail("Failed to find mounted portal nodes")
            return
        }

        // 1. Verify visual layer projection into overlay tier:
        // Portal button's layer is inside overlayHost.floatingContainer, NOT clippedNode.rootLayer!
        XCTAssertEqual(portalNode.rootLayer.superlayer, engine.overlayHost.floatingContainer)
        XCTAssertNotEqual(portalNode.rootLayer.superlayer, clippedNode.rootLayer)

        // 2. Position portal button outside clipped container (e.g. at 200, 200)
        portalNode.frame = LayoutFrame(x: 0, y: 0, width: 400, height: 400)
        portalButtonNode.frame = LayoutFrame(x: 200, y: 200, width: 50, height: 50)
        portalButtonNode.rootLayer.frame = CGRect(x: 200, y: 200, width: 50, height: 50)

        // Register event handlers
        portalButtonNode.addHandler(for: .tap) { _ in
            buttonClicked = true
        }
        clippedNode.addHandler(for: .tap) { _ in
            parentReceivedClick = true
        }

        // 3. Hit-test at (220, 220) which is outside the clipped box (100x100)
        let hit = HitTester.hitTest(point: CGPoint(x: 220, y: 220), root: engine.rootMountedNode, overlayHost: engine.overlayHost)
        XCTAssertEqual(hit?.id, portalButtonNode.id)

        // 4. Dispatch pointer tap and verify event bubbling to logical parent
        let tapEvent = Event(
            type: .tap,
            targetID: portalButtonNode.id,
            payload: .pointer(PointerEventData(
                location: CGPoint(x: 20, y: 20),
                globalLocation: CGPoint(x: 220, y: 220),
                button: .primary,
                pointerType: .mouse,
                modifiers: .none,
                clickCount: 1
            ))
        )
        engine.eventDispatcher.dispatch(event: tapEvent, target: portalButtonNode)

        XCTAssertTrue(buttonClicked, "Portal button must receive tap event")
        XCTAssertTrue(parentReceivedClick, "Event must bubble to logical parent despite layer projection")
    }

    // MARK: - 2. Layer Ordering and Hit-Test Precedence

    func testOverlayLayerPrecedence() {
        let root = RenderElement(id: ElementID(typeName: "Root"), kind: .empty).frame(width: 400, height: 400)
        let engine = PrismHostEngine(rootElement: root)
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.mount(in: hostLayer)

        // Present floating element at (50, 50, 100, 100)
        let floatingElem = RenderElement(id: ElementID(typeName: "FloatingElem"), kind: .custom("Floating"))
            .frame(width: 100, height: 100)
        let floatingNode = MountedNode(element: floatingElem)
        floatingNode.frame = LayoutFrame(x: 50, y: 50, width: 100, height: 100)
        floatingNode.mount(superlayer: engine.overlayHost.floatingContainer, overlayHost: engine.overlayHost)
        let floatingEntry = OverlayEntry(
            id: floatingElem.id,
            layer: .floating,
            node: floatingNode,
            positioning: .fixed(x: 50, y: 50)
        )
        engine.overlayHost.present(floatingEntry)

        // Present modal element overlapping at (50, 50, 100, 100)
        let modalElem = RenderElement(id: ElementID(typeName: "ModalElem"), kind: .custom("Modal"))
            .frame(width: 100, height: 100)
        let modalNode = MountedNode(element: modalElem)
        modalNode.frame = LayoutFrame(x: 50, y: 50, width: 100, height: 100)
        modalNode.mount(superlayer: engine.overlayHost.modalContainer, overlayHost: engine.overlayHost)
        let modalEntry = OverlayEntry(
            id: modalElem.id,
            layer: .modal,
            node: modalNode,
            positioning: .fixed(x: 50, y: 50)
        )
        engine.overlayHost.present(modalEntry)

        // Modal should take precedence over floating
        var hit = HitTester.hitTest(point: CGPoint(x: 75, y: 75), root: engine.rootMountedNode, overlayHost: engine.overlayHost)
        XCTAssertEqual(hit?.id, modalElem.id)

        // Present toast element overlapping at (50, 50, 100, 100)
        let toastElem = RenderElement(id: ElementID(typeName: "ToastElem"), kind: .custom("Toast"))
            .frame(width: 100, height: 100)
        let toastNode = MountedNode(element: toastElem)
        toastNode.frame = LayoutFrame(x: 50, y: 50, width: 100, height: 100)
        toastNode.mount(superlayer: engine.overlayHost.toastContainer, overlayHost: engine.overlayHost)
        let toastEntry = OverlayEntry(
            id: toastElem.id,
            layer: .toast,
            node: toastNode,
            positioning: .fixed(x: 50, y: 50)
        )
        engine.overlayHost.present(toastEntry)

        // Toast should take precedence over modal
        hit = HitTester.hitTest(point: CGPoint(x: 75, y: 75), root: engine.rootMountedNode, overlayHost: engine.overlayHost)
        XCTAssertEqual(hit?.id, toastElem.id)
    }

    // MARK: - 3. Modal Lifecycle, Focus Transfer & Dismiss Reasons

    func testModalFocusTransferAndDismissReasons() {
        let baseButton = RenderElement(id: ElementID(typeName: "BaseButton"), kind: .custom("BaseButton"))
            .focusable(true, order: 1)
        let root = VStack(spacing: 10) {
            baseButton
        }

        let engine = PrismHostEngine(rootElement: root.render())
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        engine.mount(in: hostLayer)

        // Set focus to base button
        engine.focusTree.setFocus(to: baseButton.id)
        XCTAssertEqual(engine.focusTree.currentFocus, baseButton.id)

        // Create modal with an internal focusable button
        let modalButton = RenderElement(id: ElementID(typeName: "ModalButton"), kind: .custom("ModalButton"))
            .focusable(true, order: 1)
        let modalRoot = RenderElement(
            id: ElementID(typeName: "ModalRoot"),
            kind: .custom("ModalRoot"),
            children: [modalButton]
        ).frame(width: 200, height: 200)

        let modalNode = MountedNode(element: modalRoot)
        let modalChildNode = MountedNode(element: modalButton)
        modalChildNode.mount(in: modalNode)
        modalNode.children = [modalChildNode]
        modalNode.mount(superlayer: engine.overlayHost.modalContainer, overlayHost: engine.overlayHost)

        var reportedDismissReason: DismissReason?
        let modalEntry = OverlayEntry(
            id: modalRoot.id,
            layer: .modal,
            node: modalNode,
            positioning: .center,
            blocksBackgroundPointer: true,
            isFocusTrapped: true,
            onDismiss: { reason in
                reportedDismissReason = reason
            }
        )

        // 1. Present modal: verify focus transferred to modal button
        engine.overlayHost.present(modalEntry)
        XCTAssertEqual(engine.focusTree.currentFocus, modalButton.id, "Focus must transfer to modal's focusable child")
        XCTAssertFalse(engine.overlayHost.backdropLayer.isHidden, "Backdrop layer must be visible")

        // 2. Pointer blocking: clicking outside modal at (10, 10) hits backdrop, blocks content click
        let hit = HitTester.hitTest(point: CGPoint(x: 10, y: 10), root: engine.rootMountedNode, overlayHost: engine.overlayHost)
        XCTAssertNil(hit, "Pointer outside modal must be absorbed by modal backdrop")

        // 3. Backdrop tap dismissal
        let backdropDismissHandled = engine.overlayHost.handleBackdropTap()
        XCTAssertTrue(backdropDismissHandled)
        XCTAssertEqual(reportedDismissReason, .backdropTap)
        XCTAssertEqual(engine.focusTree.currentFocus, baseButton.id, "Focus must be restored to previous element")
        XCTAssertTrue(engine.overlayHost.backdropLayer.isHidden, "Backdrop layer must be hidden after modal dismissal")

        // 4. Test Escape key dismissal
        let modalEntry2 = OverlayEntry(
            id: ElementID(typeName: "Modal2"),
            layer: .modal,
            node: modalNode,
            positioning: .center,
            onDismiss: { reason in
                reportedDismissReason = reason
            }
        )
        engine.overlayHost.present(modalEntry2)
        let escHandled = engine.overlayHost.handleEscapeKey()
        XCTAssertTrue(escHandled)
        XCTAssertEqual(reportedDismissReason, .escapeKey)
    }

    // MARK: - 4. Anchored Positioning and Invalidation

    func testAnchoredOverlayPositioningAndInvalidation() {
        let anchorElement = RenderElement(id: ElementID(typeName: "TriggerBtn"), kind: .custom("Button"))
            .anchor(id: "my_trigger")
            .frame(width: 100, height: 40)

        let root = VStack(spacing: 0) {
            anchorElement
        }

        let engine = PrismHostEngine(rootElement: root.render())
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        engine.bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        engine.mount(in: hostLayer)

        guard let anchorNode = engine.findNodeByAnchor("my_trigger") else {
            XCTFail("Anchor node not found")
            return
        }

        // Set initial frame for anchor: (50, 100, 100, 40)
        anchorNode.frame = LayoutFrame(x: 50, y: 100, width: 100, height: 40)

        // Create anchored popover: bottom, center alignment, 8pt offset
        let popoverElem = RenderElement(id: ElementID(typeName: "Popover"), kind: .custom("Popover"))
            .frame(width: 80, height: 60)
        let popoverNode = MountedNode(element: popoverElem)
        popoverNode.frame = LayoutFrame(x: 0, y: 0, width: 80, height: 60)
        popoverNode.mount(superlayer: engine.overlayHost.floatingContainer, overlayHost: engine.overlayHost)

        var dismissReason: DismissReason?
        let entry = OverlayEntry(
            id: popoverElem.id,
            layer: .floating,
            node: popoverNode,
            positioning: .anchored(anchorID: "my_trigger", edge: .bottom, alignment: .center, offset: 8),
            onDismiss: { reason in
                dismissReason = reason
            }
        )

        engine.overlayHost.present(entry)

        // Expected Y: anchor.maxY (140) + 8 = 148
        // Expected X: anchor.midX (100) - width/2 (40) = 60
        XCTAssertEqual(popoverNode.frame.origin.y, 148, accuracy: 0.1)
        XCTAssertEqual(popoverNode.frame.origin.x, 60, accuracy: 0.1)

        // Simulate anchor scroll: anchor moves to (50, 150)
        anchorNode.frame = LayoutFrame(x: 50, y: 150, width: 100, height: 40)
        engine.invalidateOverlayPositions()

        // Updated Y: 150 + 40 + 8 = 198
        XCTAssertEqual(popoverNode.frame.origin.y, 198, accuracy: 0.1)

        // Simulate anchor unmount: anchor unregisters
        anchorNode.unmount()
        engine.invalidateOverlayPositions()

        XCTAssertEqual(dismissReason, .anchorUnmounted, "Overlay must dismiss when anchor is unmounted")
    }

    // MARK: - 5. TestID Diagnostics and Lookup

    func testTestIDDiagnosticsAndAccessibilityLookup() {
        // Build tree with a duplicate testID conflict
        let elem1 = RenderElement(id: ElementID(typeName: "Btn1"), kind: .custom("Button"))
            .testID("duplicate_id")
        let elem2 = RenderElement(id: ElementID(typeName: "Btn2"), kind: .custom("Button"))
            .testID("duplicate_id")
        let uniqueElem = RenderElement(id: ElementID(typeName: "UniqueBtn"), kind: .custom("Button"))
            .testID("unique_button")
            .accessibilityLabel("Click Here Localized")

        let root = VStack(spacing: 10) {
            elem1
            elem2
            uniqueElem
        }

        let engine = PrismHostEngine(rootElement: root.render())
        let hostLayer = CALayer()
        hostLayer.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        engine.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        engine.mount(in: hostLayer)

        // 1. Verify conflict detection diagnostics
        let conflicts = engine.testIDConflicts
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.testID, "duplicate_id")
        XCTAssertEqual(conflicts.first?.elementIDs.count, 2)

        // 2. Verify UI test lookup independent of localized label
        let found = engine.accessibilityTree.findElement(byTestID: "unique_button")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.label, "Click Here Localized")
    }
}
