import XCTest
@testable import PrismCore
@testable import PrismUI

final class ComponentBuilderTests: XCTestCase {
    // MARK: - 1. Basic Component Construction

    func testBasicStackAndText() {
        let stack = Stack(.vertical, alignment: .start, spacing: 16) {
            Text("Title")
            Spacer()
            Text("Footer")
        }

        let element = stack.render()
        XCTAssertEqual(element.id.typeName, "Stack")
        XCTAssertEqual(element.children.count, 3)
        XCTAssertEqual(element.children[0].kind, .text("Title"))
        XCTAssertEqual(element.children[1].kind, .spacer(minLength: nil))
        XCTAssertEqual(element.children[2].kind, .text("Footer"))
    }

    func testHStackAndVStackConvenience() {
        let vstack = VStack(spacing: 8) {
            HStack(spacing: 4) {
                Icon("star")
                Text("Favorite")
            }
            Rectangle(cornerRadius: 8)
                .width(120)
                .height(40)
            Circle()
                .width(24)
                .height(24)
        }

        let element = vstack.render()
        XCTAssertEqual(element.children.count, 3)

        let hstackElement = element.children[0]
        XCTAssertEqual(hstackElement.children.count, 2)
        XCTAssertEqual(hstackElement.children[0].kind, .icon(name: "star", bundle: nil))
        XCTAssertEqual(hstackElement.children[1].kind, .text("Favorite"))

        let rectElement = element.children[1]
        XCTAssertEqual(rectElement.kind, .shape(.rectangle(cornerRadius: 8)))
        XCTAssertEqual(rectElement.resolvedStyle.width, 120)
        XCTAssertEqual(rectElement.resolvedStyle.height, 40)

        let circleElement = element.children[2]
        XCTAssertEqual(circleElement.kind, .shape(.circle))
        XCTAssertEqual(circleElement.resolvedStyle.width, 24)
        XCTAssertEqual(circleElement.resolvedStyle.height, 24)
    }

    // MARK: - 2. Conditionals & Optionals

    func testConditionalRendering() {
        func makeView(isLoggedIn: Bool, hasNotification: Bool) -> RenderElement {
            VStack {
                Text("Welcome")

                if isLoggedIn {
                    Text("Dashboard")
                } else {
                    Text("Sign In")
                }

                if hasNotification {
                    Text("New notification")
                }
            }.render()
        }

        let loggedIn = makeView(isLoggedIn: true, hasNotification: false)
        XCTAssertEqual(loggedIn.children.count, 2)
        XCTAssertEqual(loggedIn.children[0].kind, .text("Welcome"))
        XCTAssertEqual(loggedIn.children[1].kind, .text("Dashboard"))

        let loggedOut = makeView(isLoggedIn: false, hasNotification: true)
        XCTAssertEqual(loggedOut.children.count, 3)
        XCTAssertEqual(loggedOut.children[0].kind, .text("Welcome"))
        XCTAssertEqual(loggedOut.children[1].kind, .text("Sign In"))
        XCTAssertEqual(loggedOut.children[2].kind, .text("New notification"))
    }

    // MARK: - 3. Group and Empty

    func testGroupInliningInComponentBuilder() {
        let vstack = VStack {
            Text("Top")
            Group {
                Text("Grouped A")
                Text("Grouped B")
                Empty()
            }
            Text("Bottom")
        }

        let element = vstack.render()
        // Group inlined, Empty pruned
        XCTAssertEqual(element.children.count, 4)
        XCTAssertEqual(element.children[0].kind, .text("Top"))
        XCTAssertEqual(element.children[1].kind, .text("Grouped A"))
        XCTAssertEqual(element.children[2].kind, .text("Grouped B"))
        XCTAssertEqual(element.children[3].kind, .text("Bottom"))
    }

    // MARK: - 4. ForEach Loop

    func testForEachInComponentBuilder() {
        struct Member: Identifiable {
            let id: String
            let name: String
        }

        let members = [
            Member(id: "m1", name: "Alice"),
            Member(id: "m2", name: "Bob"),
            Member(id: "m3", name: "Charlie")
        ]

        let stack = VStack {
            ForEach(members) { member in
                Text(member.name)
            }
        }

        let element = stack.render()
        XCTAssertEqual(element.children.count, 3)
        XCTAssertEqual(element.children[0].id.key, "m1")
        XCTAssertEqual(element.children[0].kind, .text("Alice"))
        XCTAssertEqual(element.children[1].id.key, "m2")
        XCTAssertEqual(element.children[1].kind, .text("Bob"))
        XCTAssertEqual(element.children[2].id.key, "m3")
        XCTAssertEqual(element.children[2].kind, .text("Charlie"))
    }

    // MARK: - 5. Modifiers on Components

    func testModifierChainingOnComponents() {
        let text = Text("Styled Text")
            .padding(16)
            .background(.hex("#635BFF"))
            .opacity(0.85)
            .key("custom_key")
            .testID("styled_text_id")

        XCTAssertEqual(text.id.key, "custom_key")
        XCTAssertEqual(text.props.testID, "styled_text_id")
        XCTAssertEqual(text.resolvedStyle.padding.top, 16)
        XCTAssertEqual(text.resolvedStyle.opacity, 0.85)
        XCTAssertEqual(text.resolvedStyle.background, Color.hex("#635BFF"))
    }

    // MARK: - 6. Localization with ComponentContext

    func testTextLocalizationInContext() {
        let key: LocalizedStringKey = "greeting_key"

        // Setup mock localization table
        LocalizationBundle.shared.registerStrings(["greeting_key": "Hello World"], localeIdentifier: "en")
        LocalizationBundle.shared.registerStrings(["greeting_key": "Hola Mundo"], localeIdentifier: "es")

        let textComponent = Text(key)

        let englishContext = ComponentContext(
            environment: LocalizationEnvironment(locale: Locale(identifier: "en"))
        )
        let elementEn = textComponent.render(in: englishContext)
        XCTAssertEqual(elementEn.kind, .text("Hello World"))

        let spanishContext = ComponentContext(
            environment: LocalizationEnvironment(locale: Locale(identifier: "es"))
        )
        let elementEs = textComponent.render(in: spanishContext)
        XCTAssertEqual(elementEs.kind, .text("Hola Mundo"))
    }
}
