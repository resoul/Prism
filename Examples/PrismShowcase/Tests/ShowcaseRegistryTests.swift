import XCTest
import PrismUI
@testable import PrismCore

@MainActor
final class ShowcaseRegistryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActionRegistry.shared.reset()
        ShowcasePreferences().reset()
    }

    override func tearDown() {
        ActionRegistry.shared.reset()
        ShowcasePreferences().reset()
        super.tearDown()
    }

    // MARK: - Registry Completeness Tests

    func testRegistryCompletenessAndNoDuplicateIDs() {
        let allItems = ShowcaseRegistry.allItems
        XCTAssertEqual(allItems.count, 82, "Showcase registry must match the audited catalog components")

        var seenIDs = Set<String>()
        var seenSymbols = Set<String>()

        for item in allItems {
            XCTAssertFalse(item.id.isEmpty, "Component ID cannot be empty")
            XCTAssertFalse(item.name.isEmpty, "Component name cannot be empty for \(item.id)")
            XCTAssertFalse(item.publicSymbol.isEmpty, "Public symbol cannot be empty for \(item.id)")
            XCTAssertFalse(item.summary.isEmpty, "Summary cannot be empty for \(item.id)")
            XCTAssertFalse(item.documentationPath.isEmpty, "Documentation path cannot be empty for \(item.id)")
            XCTAssertFalse(item.sourcePath.isEmpty, "Source path cannot be empty for \(item.id)")

            XCTAssertFalse(seenIDs.contains(item.id), "Duplicate component ID found: \(item.id)")
            seenIDs.insert(item.id)

            XCTAssertFalse(seenSymbols.contains(item.publicSymbol), "Duplicate public symbol found: \(item.publicSymbol)")
            seenSymbols.insert(item.publicSymbol)
        }

        XCTAssertEqual(seenIDs.count, 82)
        XCTAssertEqual(seenSymbols.count, 82)
    }

    func testDescriptorMetadataAndMaturityClassification() {
        let p0Items = ShowcaseRegistry.items(withMaturity: .p0Core)
        let p1Items = ShowcaseRegistry.items(withMaturity: .p1Standard)
        let p2Items = ShowcaseRegistry.items(withMaturity: .p2Advanced)
        let p3Items = ShowcaseRegistry.items(withMaturity: .p3Experimental)

        XCTAssertFalse(p0Items.isEmpty, "p0Core components must not be empty")
        XCTAssertFalse(p1Items.isEmpty, "p1Standard components must not be empty")
        XCTAssertFalse(p2Items.isEmpty, "p2Advanced components must not be empty")
        XCTAssertFalse(p3Items.isEmpty, "p3Experimental components must not be empty")

        XCTAssertEqual(p0Items.count + p1Items.count + p2Items.count + p3Items.count, 82)

        // Verify specific component maturity classifications
        XCTAssertEqual(ShowcaseRegistry.item(for: "text")?.maturity, .p0Core)
        XCTAssertEqual(ShowcaseRegistry.item(for: "button")?.maturity, .p1Standard)
        XCTAssertEqual(ShowcaseRegistry.item(for: "accordion")?.maturity, .p2Advanced)
        XCTAssertEqual(ShowcaseRegistry.item(for: "datagrid")?.maturity, .p3Experimental)

        // Platform capabilities
        let menubar = ShowcaseRegistry.item(for: "menubar")
        XCTAssertNotNil(menubar)
        XCTAssertTrue(menubar?.capabilities.contains(.macOS) ?? false)
        XCTAssertFalse(menubar?.capabilities.contains(.iOS) ?? true)
    }

    func testIncompleteComponentDescriptorsHaveOwnerAndGap() {
        let allItems = ShowcaseRegistry.allItems
        var incompleteCount = 0

        for item in allItems {
            if case .incomplete(let owner, let gap) = item.status {
                incompleteCount += 1
                XCTAssertTrue(owner.hasPrefix("Task 23"), "Incomplete component owner must cite owning task, got: \(owner)")
                XCTAssertFalse(gap.isEmpty, "Gap description must not be empty for \(item.id)")
            }
        }

        XCTAssertGreaterThan(incompleteCount, 10, "Expected multiple incomplete components per Task 23a manifest")

        // Specific checks
        if let datagrid = ShowcaseRegistry.item(for: "datagrid") {
            if case .incomplete(let owner, _) = datagrid.status {
                XCTAssertEqual(owner, "Task 23t")
            } else {
                XCTFail("DataGrid must be marked incomplete")
            }
        }
    }

    func testGroupedComponentItems() {
        let grouped = ShowcaseRegistry.groupedItems
        XCTAssertFalse(grouped.isEmpty)
        for item in grouped {
            if case .grouped(let parent) = item.status {
                XCTAssertFalse(parent.isEmpty)
            } else {
                XCTFail("Grouped item \(item.id) must have .grouped status")
            }
        }
    }

    func testLookupAndSearch() {
        XCTAssertNotNil(ShowcaseRegistry.item(for: "button"))
        XCTAssertNil(ShowcaseRegistry.item(for: "nonexistent_component"))

        XCTAssertNotNil(ShowcaseRegistry.item(forSymbol: "Button"))
        XCTAssertNil(ShowcaseRegistry.item(forSymbol: "NonexistentSymbol"))

        let searchButton = ShowcaseRegistry.search(query: "button")
        XCTAssertTrue(searchButton.contains(where: { $0.id == "button" }))

        let searchEmpty = ShowcaseRegistry.search(query: "xyznonexistent999")
        XCTAssertTrue(searchEmpty.isEmpty)
    }

    // MARK: - Isolated Store & Playground State Tests

    func testIsolatedExampleStoreStateAndActions() {
        let store1 = ShowcaseExampleStore(componentID: "button", initialState: "default", initialVariant: "primary")
        let store2 = ShowcaseExampleStore(componentID: "accordion", initialState: "default", initialVariant: "default")

        XCTAssertEqual(store1.state.localCount, 0)
        XCTAssertEqual(store2.state.localCount, 0)

        // Mutate store 1
        store1.increment()
        store1.setState("hover")
        store1.setVariant("secondary")
        store1.setText("Hello")
        store1.setBool(true)
        store1.setDouble(0.75)

        XCTAssertEqual(store1.state.localCount, 1)
        XCTAssertEqual(store1.state.selectedState, "hover")
        XCTAssertEqual(store1.state.selectedVariant, "secondary")
        XCTAssertEqual(store1.state.localText, "Hello")
        XCTAssertEqual(store1.state.localBool, true)
        XCTAssertEqual(store1.state.localDouble, 0.75)

        // Verify store 2 remains completely isolated
        XCTAssertEqual(store2.state.localCount, 0)
        XCTAssertEqual(store2.state.selectedState, "default")
        XCTAssertEqual(store2.state.selectedVariant, "default")
        XCTAssertEqual(store2.state.localText, "")
        XCTAssertEqual(store2.state.localBool, false)
        XCTAssertEqual(store2.state.localDouble, 0.5)

        // Reset store 1
        store1.reset()
        XCTAssertEqual(store1.state.localCount, 0)
        XCTAssertEqual(store1.state.selectedState, "default")
        XCTAssertEqual(store1.state.selectedVariant, "primary")
        XCTAssertEqual(store1.state.localText, "")
        XCTAssertEqual(store1.state.localBool, false)
    }

    func testAccordionInteractiveToggleAndExpansion() {
        let store = ShowcaseExampleStore(componentID: "accordion", initialState: "default", initialVariant: "default")

        XCTAssertTrue(store.isExpanded("item-1"))
        XCTAssertFalse(store.isExpanded("item-2"))

        // Expand item-2
        store.toggleExpanded("item-2")
        XCTAssertTrue(store.isExpanded("item-2"))

        // Collapse item-1
        store.toggleExpanded("item-1")
        XCTAssertFalse(store.isExpanded("item-1"))

        // Test binding
        let binding = store.expandedBinding()
        XCTAssertEqual(binding.wrappedValue, ["item-2"])

        binding.wrappedValue = ["item-1", "item-2"]
        XCTAssertTrue(store.isExpanded("item-1"))
        XCTAssertTrue(store.isExpanded("item-2"))
    }

    func testShowcaseStoreManagesExampleStores() {
        let showcaseStore = ShowcaseStore()
        var publishedCount = 0
        showcaseStore.onChange = { _ in
            publishedCount += 1
        }

        let exStore1 = showcaseStore.exampleStore(for: "accordion")
        let exStore2 = showcaseStore.exampleStore(for: "accordion")
        XCTAssertTrue(exStore1 === exStore2, "Example store must be cached and reused")

        // Mutating example store notifies ShowcaseStore.onChange
        exStore1.toggleExpanded("item-2")
        XCTAssertEqual(publishedCount, 1)

        // Resetting example store
        exStore1.reset()
        XCTAssertEqual(publishedCount, 2)

        showcaseStore.teardown()
    }

    // MARK: - Detail Screen Automation IDs & Preview Tests

    func testDetailScreenRendersIncompleteBannerForIncompleteComponent() {
        let store = ShowcaseStore()
        store.navigate(to: .component(id: "datagrid"))
        let root = store.rootElement()
        let tree = root.dumpTree()

        XCTAssertTrue(tree.contains("showcase.detail.title"))
        XCTAssertTrue(tree.contains("showcase.detail.symbol"))
        XCTAssertTrue(tree.contains("showcase.detail.maturity"))
        XCTAssertTrue(tree.contains("showcase.detail.capabilities"))
        XCTAssertTrue(tree.contains("showcase.detail.doc_path"))

        // Incomplete banner must be explicitly rendered
        XCTAssertTrue(tree.contains("showcase.detail.incomplete"))
        XCTAssertTrue(tree.contains("showcase.detail.incomplete_title"))
        XCTAssertTrue(tree.contains("showcase.detail.incomplete_owner"))
        XCTAssertTrue(tree.contains("showcase.detail.incomplete_gap"))
    }

    func testDetailScreenRendersInteractiveAccordion() {
        let store = ShowcaseStore()
        store.navigate(to: .component(id: "accordion"))
        let root = store.rootElement()
        let tree = root.dumpTree()

        XCTAssertTrue(tree.contains("showcase.detail.title"))
        XCTAssertTrue(tree.contains("showcase.preview.container"))
        XCTAssertTrue(tree.contains("showcase.preview.accordion"))
        XCTAssertTrue(tree.contains("showcase.accordion.toggle_1"))
        XCTAssertTrue(tree.contains("showcase.accordion.toggle_2"))
        XCTAssertTrue(tree.contains("showcase.detail.state_readout"))
        XCTAssertTrue(tree.contains("showcase.detail.reset"))
    }
}
