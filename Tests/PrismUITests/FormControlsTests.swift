import XCTest
import CoreGraphics
@testable import PrismCore
@testable import PrismUI

final class FormControlsTests: XCTestCase {

    @MainActor
    func testInputComponent() {
        var textStorage = "Hello"
        let binding = Binding(get: { textStorage }, set: { textStorage = $0 })

        let input = Input("Enter text...", text: binding)
            .mode(.password)
            .disabled(true)

        let element = input.render()
        XCTAssertEqual(element.kind, .textEditor(mode: .password, multiline: false))
        XCTAssertEqual(element.props.custom["text"], "Hello")
        XCTAssertEqual(element.props.custom["placeholder"], "Enter text...")
        XCTAssertEqual(element.props.custom["isDisabled"], "true")
    }

    @MainActor
    func testTextareaComponent() {
        var textStorage = "Multi-line\nText"
        let binding = Binding(get: { textStorage }, set: { textStorage = $0 })

        let textarea = Textarea("Description", text: binding, minLines: 4)
        let element = textarea.render()

        XCTAssertEqual(element.kind, .textEditor(mode: .text, multiline: true))
        XCTAssertEqual(element.props.custom["text"], "Multi-line\nText")
        XCTAssertEqual(element.props.custom["minLines"], "4")
    }

    @MainActor
    func testButtonVariantsAndSizes() {
        var tapped = false
        let button = Button("Submit", variant: .destructive, size: .lg) {
            tapped = true
        }

        let element = button.render()
        XCTAssertEqual(element.props.custom["title"], "Submit")
        XCTAssertEqual(element.props.custom["variant"], "destructive")
        XCTAssertEqual(element.props.custom["size"], "lg")

        button.action()
        XCTAssertTrue(tapped)
    }

    @MainActor
    func testCheckboxComponent() {
        var checked = false
        let binding = Binding(get: { checked }, set: { checked = $0 })

        let checkbox = Checkbox("Remember me", isOn: binding)
        let element = checkbox.render()

        XCTAssertEqual(element.props.custom["isChecked"], "false")
        XCTAssertEqual(element.props.custom["label"], "Remember me")
    }

    @MainActor
    func testRadioGroupAndItems() {
        var selectedColor = "red"
        let binding = Binding(get: { selectedColor }, set: { selectedColor = $0 })

        let radioRed = RadioItem(value: "red", selected: binding, label: "Red")
        let radioBlue = RadioItem(value: "blue", selected: binding, label: "Blue")

        XCTAssertEqual(radioRed.render().props.custom["isSelected"], "true")
        XCTAssertEqual(radioBlue.render().props.custom["isSelected"], "false")

        let group = RadioGroup {
            radioRed
            radioBlue
        }
        let groupElement = group.render()
        XCTAssertEqual(groupElement.children.count, 2)
    }

    @MainActor
    func testSwitchAndToggle() {
        var notificationsOn = true
        let binding = Binding(get: { notificationsOn }, set: { notificationsOn = $0 })

        let toggleSwitch = Switch("Enable Notifications", isOn: binding)
        XCTAssertEqual(toggleSwitch.render().props.custom["isOn"], "true")

        let toggleBtn = Toggle("Bold", isOn: binding)
        XCTAssertEqual(toggleBtn.render().props.custom["isOn"], "true")
    }

    @MainActor
    func testFieldWrapper() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let field = Field("Email Address", isRequired: true, error: "Invalid email") {
            Input("user@example.com", text: binding)
        }

        let element = field.render()
        XCTAssertEqual(element.children.count, 3) // Label HStack, Input, Error Text
    }

    @MainActor
    func testFormSubmitTraversal() {
        var submitted = false
        let form = Form(onSubmit: {
            submitted = true
        }) {
            Text("Form Body")
        }

        let element = form.render()
        XCTAssertEqual(element.props.custom["focusScopeID"], "formScope")

        form.onSubmit?()
        XCTAssertTrue(submitted)
    }
}
