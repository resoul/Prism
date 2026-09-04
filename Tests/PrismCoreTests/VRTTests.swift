import XCTest
@testable import PrismCore

final class VRTTests: XCTestCase {
    // MARK: - 1. ElementID & Key Tests

    func testElementIDPropertiesAndFormatting() {
        let idWithoutKey = ElementID(typeName: "Stack", key: nil, siblingIndex: 3)
        XCTAssertEqual(idWithoutKey.description, "Stack@3")
        XCTAssertEqual(idWithoutKey.typeName, "Stack")
        XCTAssertNil(idWithoutKey.key)
        XCTAssertEqual(idWithoutKey.siblingIndex, 3)

        let idWithKey = ElementID(typeName: "Text", key: "item-42", siblingIndex: 0)
        XCTAssertEqual(idWithKey.description, "Text[item-42]@0")
        XCTAssertEqual(idWithKey.key, "item-42")

        let updatedIndex = idWithKey.withSiblingIndex(7)
        XCTAssertEqual(updatedIndex.siblingIndex, 7)
        XCTAssertEqual(updatedIndex.key, "item-42")

        let updatedKey = idWithoutKey.withKey("newKey")
        XCTAssertEqual(updatedKey.key, "newKey")
        XCTAssertEqual(updatedKey.siblingIndex, 3)
    }

    func testElementKeyLiteralConstructors() {
        let stringKey: ElementKey = "profile_header"
        let intKey: ElementKey = 101

        XCTAssertEqual(stringKey.value, "profile_header")
        XCTAssertEqual(intKey.value, "101")
        XCTAssertEqual(stringKey.description, "profile_header")
    }

    // MARK: - 2. Value Semantics Test

    func testValueSemanticsImmutability() {
        let original = RenderElement(
            id: ElementID(typeName: "Text", key: "orig"),
            kind: .text("Hello"),
            props: ElementProps(testID: "original_text"),
            modifiers: [.opacity(1.0)]
        )

        var clone = original
        clone.id = clone.id.withKey("mutated")
        clone.props.testID = "mutated_text"
        clone.modifiers.append(.opacity(0.5))

        // Original remains untouched
        XCTAssertEqual(original.id.key, "orig")
        XCTAssertEqual(original.props.testID, "original_text")
        XCTAssertEqual(original.modifiers.count, 1)
        XCTAssertEqual(original.resolvedStyle.opacity, 1.0)

        // Clone was modified independently
        XCTAssertEqual(clone.id.key, "mutated")
        XCTAssertEqual(clone.props.testID, "mutated_text")
        XCTAssertEqual(clone.modifiers.count, 2)
        XCTAssertEqual(clone.resolvedStyle.opacity, 0.5)
    }

    // MARK: - 3. Modifier Precedence & Resolution Tests

    func testModifierPrecedenceAndAccumulation() {
        let element = RenderElement(
            id: ElementID(typeName: "Box"),
            kind: .custom("Box")
        )
        .width(100)
        .width(250) // Later overrides earlier dimension
        .padding(DirectionalEdgeInsets(top: 10, leading: 12, bottom: 14, trailing: 16))
        .padding(5) // Accumulates with inner padding
        .opacity(0.8)
        .opacity(0.5) // Multiplicative: 0.8 * 0.5 = 0.4
        .zIndex(1)
        .zIndex(99) // Later overrides earlier zIndex
        .background(.hex("#FF0000"))
        .background(.hex("#0000FF")) // Later overrides earlier background

        let style = element.resolvedStyle

        // Width overridden
        XCTAssertEqual(style.width, 250)

        // Padding accumulated
        XCTAssertEqual(style.padding.top, 15)
        XCTAssertEqual(style.padding.leading, 17)
        XCTAssertEqual(style.padding.bottom, 19)
        XCTAssertEqual(style.padding.trailing, 21)

        // Opacity multiplied
        XCTAssertEqual(style.opacity, 0.4, accuracy: 0.001)

        // zIndex overridden
        XCTAssertEqual(style.zIndex, 99)

        // Background overridden
        XCTAssertEqual(style.background, Color.hex("#0000FF"))
    }

    // MARK: - 4. Group Flattening & Empty Elimination

    func testGroupInliningAndEmptyPruningInVRT() {
        let unnormalized = RenderElement(
            id: ElementID(typeName: "Stack"),
            kind: .stack(axis: .vertical, alignment: .start, spacing: 10),
            children: [
                RenderElement(id: ElementID(typeName: "Text"), kind: .text("Item 1")),
                RenderElement(id: ElementID(typeName: "Empty"), kind: .empty),
                RenderElement(
                    id: ElementID(typeName: "Group"),
                    kind: .group,
                    children: [
                        RenderElement(id: ElementID(typeName: "Text"), kind: .text("Grouped 1")),
                        RenderElement(id: ElementID(typeName: "Empty"), kind: .empty),
                        RenderElement(id: ElementID(typeName: "Text"), kind: .text("Grouped 2"))
                    ]
                ),
                RenderElement(id: ElementID(typeName: "Text"), kind: .text("Item 2"))
            ]
        )

        let normalized = unnormalized.normalized()

        // Empty should be pruned, and Group inlined
        XCTAssertEqual(normalized.children.count, 4)
        XCTAssertEqual(normalized.children[0].kind, .text("Item 1"))
        XCTAssertEqual(normalized.children[1].kind, .text("Grouped 1"))
        XCTAssertEqual(normalized.children[2].kind, .text("Grouped 2"))
        XCTAssertEqual(normalized.children[3].kind, .text("Item 2"))

        // Sibling indices recomputed sequentially
        XCTAssertEqual(normalized.children[0].id.siblingIndex, 0)
        XCTAssertEqual(normalized.children[1].id.siblingIndex, 1)
        XCTAssertEqual(normalized.children[2].id.siblingIndex, 2)
        XCTAssertEqual(normalized.children[3].id.siblingIndex, 3)
    }

    // MARK: - 5. Stable Key Identity & Reordering

    func testKeyedSiblingsPreserveIdentityAcrossReorder() {
        struct Item: Identifiable {
            let id: String
            let title: String
        }

        let initialData = [
            Item(id: "item_a", title: "Alpha"),
            Item(id: "item_b", title: "Beta"),
            Item(id: "item_c", title: "Gamma")
        ]

        let initialElements = ForEach(initialData) { item in
            RenderElement(
                id: ElementID(typeName: "Text"),
                kind: .text(item.title)
            )
        }.elements

        XCTAssertEqual(initialElements[0].id.key, "item_a")
        XCTAssertEqual(initialElements[0].id.siblingIndex, 0)
        XCTAssertEqual(initialElements[1].id.key, "item_b")
        XCTAssertEqual(initialElements[1].id.siblingIndex, 1)
        XCTAssertEqual(initialElements[2].id.key, "item_c")
        XCTAssertEqual(initialElements[2].id.siblingIndex, 2)

        // Reorder items
        let reorderedData = [
            Item(id: "item_c", title: "Gamma"),
            Item(id: "item_a", title: "Alpha"),
            Item(id: "item_b", title: "Beta")
        ]

        let reorderedElements = ForEach(reorderedData) { item in
            RenderElement(
                id: ElementID(typeName: "Text"),
                kind: .text(item.title)
            )
        }.elements

        // Each element still carries its stable explicit key
        XCTAssertEqual(reorderedElements[0].id.key, "item_c")
        XCTAssertEqual(reorderedElements[0].id.siblingIndex, 0)
        XCTAssertEqual(reorderedElements[1].id.key, "item_a")
        XCTAssertEqual(reorderedElements[1].id.siblingIndex, 1)
        XCTAssertEqual(reorderedElements[2].id.key, "item_b")
        XCTAssertEqual(reorderedElements[2].id.siblingIndex, 2)

        // Simulating state reconciliation by key:
        var stateStore: [String: String] = [
            "item_a": "StateA",
            "item_b": "StateB",
            "item_c": "StateC"
        ]

        // Looking up state using the reordered element key returns the correct state:
        let resolvedStateForFirst = stateStore[reorderedElements[0].id.key!]
        XCTAssertEqual(resolvedStateForFirst, "StateC")
    }

    // MARK: - 6. Debug Tree Representation

    func testDumpTreeFormat() {
        let tree = RenderElement(
            id: ElementID(typeName: "Stack", key: "root"),
            kind: .stack(axis: .vertical, alignment: .center, spacing: 8),
            props: ElementProps(testID: "main_stack"),
            modifiers: [.opacity(0.9)],
            children: [
                RenderElement(
                    id: ElementID(typeName: "Text", key: "title", siblingIndex: 0),
                    kind: .text("Hello Prism"),
                    modifiers: [.padding(DirectionalEdgeInsets(all: 12))]
                ),
                RenderElement(
                    id: ElementID(typeName: "Shape", siblingIndex: 1),
                    kind: .shape(.circle),
                    modifiers: [.width(48), .height(48)]
                )
            ]
        )

        let dump = tree.dumpTree()
        XCTAssertTrue(dump.contains("Stack(axis: vertical, alignment: center, spacing: 8.0)"))
        XCTAssertTrue(dump.contains("[key: \"root\"]"))
        XCTAssertTrue(dump.contains("[testID: \"main_stack\"]"))
        XCTAssertTrue(dump.contains("Text(\"Hello Prism\")"))
        XCTAssertTrue(dump.contains("Shape(circle)"))
        XCTAssertTrue(dump.contains("padding(t: 12.0, l: 12.0, b: 12.0, tr: 12.0)"))
    }
}
