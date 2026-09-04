import XCTest
@testable import PrismCore
@testable import PrismUI

private enum TestTab: String, CaseIterable, TabItem {
    case first, second

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct CustomBrandButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonConfiguration, context: ComponentContext) -> RenderElement {
        var modifiers: [ElementModifier] = [
            .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20)),
            .background(Color.hex("#FF5500"))
        ]
        if !configuration.isEnabled {
            modifiers.append(.opacity(0.4))
        }

        return RenderElement(
            id: ElementID(typeName: "BrandButton"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 4.0),
            modifiers: modifiers,
            children: [configuration.label]
        )
    }
}

final class P1ComponentTests: XCTestCase {

    // MARK: - Data Display Tests

    func testBadgeVariantsAndSizes() {
        let badge = Badge("New", variant: .destructive, size: .sm)
        let element = badge.body(context: .default)

        XCTAssertEqual(element.id.typeName, "Badge")
        XCTAssertEqual(element.props.custom["badgeVariant"], "destructive")
        XCTAssertEqual(element.props.custom["badgeSize"], "sm")
        XCTAssertEqual(element.children.first?.kind, .text("New"))
    }

    func testLabelCompositionAndAccessibility() {
        let label = Label("Favorites", systemImage: "heart.fill", spacing: 8.0, iconSize: 18.0)
        let element = label.body(context: .default)

        XCTAssertEqual(element.id.typeName, "Label")
        XCTAssertEqual(element.props.accessibilityLabel, "Favorites")
        XCTAssertEqual(element.children.count, 2)
        XCTAssertEqual(element.children.first?.id.typeName, "Icon")
        XCTAssertEqual(element.children.last?.id.typeName, "Text")
    }

    func testAvatarImageVsInitialsFallback() {
        // 1. With image
        let avatarWithImage = Avatar(url: URL(string: "https://example.com/avatar.jpg"), size: .md)
        let imageElement = avatarWithImage.body(context: .default)
        XCTAssertEqual(imageElement.id.typeName, "Avatar")
        XCTAssertEqual(imageElement.children.first?.kind, .image(source: .url(URL(string: "https://example.com/avatar.jpg")!)))

        // 2. Fallback initials
        let avatarInitials = Avatar(initials: "TC", size: .lg)
        let initialsElement = avatarInitials.body(context: .default)
        XCTAssertEqual(initialsElement.id.typeName, "Avatar")
        XCTAssertEqual(initialsElement.children.count, 2) // background circle + text
        XCTAssertEqual(initialsElement.children.last?.kind, .text("TC"))
    }

    func testCardSectionHierarchy() {
        let card = Card {
            CardHeader {
                CardTitle("Card Title")
                CardDescription("Card subtitle description")
            }
            CardContent {
                Text("Body text inside card")
            }
            CardFooter {
                Button("Action", action: {})
            }
        }

        let element = card.body(context: .default)
        XCTAssertEqual(element.id.typeName, "Card")
        XCTAssertEqual(element.children.count, 3) // Header, Content, Footer
        XCTAssertEqual(element.children[0].id.typeName, "CardHeader")
        XCTAssertEqual(element.children[1].id.typeName, "CardContent")
        XCTAssertEqual(element.children[2].id.typeName, "CardFooter")
    }

    func testIconTileWithBadge() {
        let tile = IconTile(systemImage: "envelope.fill", size: 48.0, iconSize: 20.0, badgeCount: 5)
        let element = tile.body(context: .default)

        XCTAssertEqual(element.id.typeName, "IconTile")
        XCTAssertEqual(element.children.count, 2) // Icon + Badge
        XCTAssertEqual(element.children.first?.id.typeName, "Icon")
        XCTAssertEqual(element.children.last?.id.typeName, "Badge")
    }

    // MARK: - Feedback Tests

    func testAlertVariantsAndProps() {
        let alert = Alert(title: "Warning", description: "Storage almost full", variant: .warning)
        let element = alert.body(context: .default)

        XCTAssertEqual(element.id.typeName, "Alert")
        XCTAssertEqual(element.props.custom["alertVariant"], "warning")
        XCTAssertEqual(element.props.accessibilityLabel, "Warning: Storage almost full")
    }

    func testSpinnerRespectsReduceMotion() {
        // Normal context
        let normalSpinner = Spinner(size: .md).body(context: .default)
        XCTAssertEqual(normalSpinner.props.custom["reduceMotion"], "false")

        // Reduced motion environment
        var env = LocalizationEnvironment()
        env.reduceMotion = true
        let reducedContext = ComponentContext(environment: env)

        let reducedSpinner = Spinner(size: .md).body(context: reducedContext)
        XCTAssertEqual(reducedSpinner.props.custom["reduceMotion"], "true")
    }

    // MARK: - Navigation Tests

    func testTabsStructureAndPanelMapping() {
        let tabs = Tabs(TestTab.allCases, selection: .first, onSelect: { _ in }) { tab in
            [RenderElement(id: ElementID(typeName: "PanelContent", key: tab.rawValue), kind: .text("Content for \(tab.title)"))]
        }

        let element = tabs.body(context: .default)
        XCTAssertEqual(element.id.typeName, "Tabs")
        XCTAssertEqual(element.children.count, 2) // TabList + TabPanel

        let tabList = element.children[0]
        XCTAssertEqual(tabList.props.custom["role"], "tablist")
        XCTAssertEqual(tabList.children.count, 2)

        // First tab is selected
        XCTAssertEqual(tabList.children[0].props.custom["selected"], "true")
        XCTAssertEqual(tabList.children[1].props.custom["selected"], "false")

        let tabPanel = element.children[1]
        XCTAssertEqual(tabPanel.props.custom["role"], "tabpanel")
        XCTAssertEqual(tabPanel.props.custom["labelledBy"], "tab_first")
    }

    // MARK: - Overlay Tests

    func testDialogModalPresentation() {
        // 1. Not presented -> empty
        let hiddenDialog = Dialog(isPresented: false, title: "Hidden", onDismiss: {}) {
            Text("Content")
        }
        let hiddenElement = hiddenDialog.body(context: .default)
        XCTAssertEqual(hiddenElement.kind, .empty)

        // 2. Presented -> modal portal with backdrop and dialog card
        let visibleDialog = Dialog(isPresented: true, title: "Alert Title", onDismiss: {}) {
            Text("Message")
        } actions: {
            Button("OK", action: {})
        }
        let visibleElement = visibleDialog.body(context: .default)
        XCTAssertEqual(visibleElement.kind, .portal(targetLayer: .modal))
        XCTAssertEqual(visibleElement.children.first?.children.count, 2) // Backdrop + DialogCard
    }

    func testTooltipVisibilityAndPlacement() {
        // 1. Invisible
        let hiddenTooltip = Tooltip("Info hint", placement: .top, isVisible: false) {
            Text("Hover trigger")
        }
        let hiddenElement = hiddenTooltip.body(context: .default)
        XCTAssertEqual(hiddenElement.children.count, 1) // Just trigger

        // 2. Visible
        let visibleTooltip = Tooltip("Info hint", placement: .top, isVisible: true) {
            Text("Hover trigger")
        }
        let visibleElement = visibleTooltip.body(context: .default)
        XCTAssertEqual(visibleElement.children.count, 2) // Trigger + Portal bubble
        XCTAssertEqual(visibleElement.children.last?.kind, .portal(targetLayer: .floating))
    }

    // MARK: - Layout & Styling Tests

    func testDividerOrientationAndRole() {
        let hDivider = Divider(.horizontal, thickness: 2.0).body(context: .default)
        XCTAssertEqual(hDivider.props.custom["role"], "separator")
        XCTAssertEqual(hDivider.props.custom["orientation"], "horizontal")

        let vDivider = Divider(.vertical, thickness: 1.0).body(context: .default)
        XCTAssertEqual(vDivider.props.custom["orientation"], "vertical")
    }

    func testFrameDimensionConstraints() {
        let frame = Frame(width: 200.0, height: 100.0, alignment: .start) {
            Text("Inside frame")
        }
        let element = frame.body(context: .default)
        XCTAssertEqual(element.id.typeName, "Frame")
        XCTAssertTrue(element.modifiers.contains(.width(200.0)))
        XCTAssertTrue(element.modifiers.contains(.height(100.0)))
    }

    func testCustomButtonStyleContractConformance() {
        let style = CustomBrandButtonStyle()
        let label = RenderElement(id: ElementID(typeName: "Text"), kind: .text("Submit"))

        // Enabled
        let configEnabled = ButtonConfiguration(label: label, isEnabled: true)
        let styledElement = style.makeBody(configuration: configEnabled, context: .default)
        XCTAssertEqual(styledElement.id.typeName, "BrandButton")
        XCTAssertEqual(styledElement.children.first?.kind, .text("Submit"))

        // Disabled
        let configDisabled = ButtonConfiguration(label: label, isEnabled: false)
        let disabledElement = style.makeBody(configuration: configDisabled, context: .default)
        XCTAssertTrue(disabledElement.modifiers.contains(.opacity(0.4)))
    }
}
