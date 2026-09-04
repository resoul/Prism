import XCTest
@testable import PrismUI

@MainActor
final class P2DataEntryTests: XCTestCase {
    func testNumberFieldClampsAndRoundsToStep() {
        var stored = 2.0
        let field = NumberField("Quantity", value: Binding(get: { stored }, set: { stored = $0 }), range: 0...10, step: 0.5)

        field.setValue(10.3)
        XCTAssertEqual(stored, 10)
        field.decrement()
        XCTAssertEqual(stored, 9.5)
        XCTAssertEqual(field.render().props.custom["role"], "spinButton")
    }

    func testSliderAndRangeSliderMaintainBounds() {
        var value = 0.0
        let slider = Slider(value: Binding(get: { value }, set: { value = $0 }), in: 0...1, step: 0.25, label: "Opacity")
        slider.setValue(0.63)
        XCTAssertEqual(value, 0.75)
        slider.increment()
        XCTAssertEqual(value, 1)

        var range = 2.0...8.0
        let rangeSlider = RangeSlider(value: Binding(get: { range }, set: { range = $0 }), in: 0...10, step: 1)
        rangeSlider.setLower(9)
        XCTAssertEqual(range, 8...9)
        rangeSlider.setUpper(-2)
        XCTAssertEqual(range, 0...8)
    }

    func testStepperAndRatingRespectTheirLimits() {
        var amount = 1.0
        let stepper = Stepper(value: Binding(get: { amount }, set: { amount = $0 }), range: 0...2, step: 1)
        stepper.increment(); stepper.increment()
        XCTAssertEqual(amount, 2)

        var rating = 0
        let control = Rating(value: Binding(get: { rating }, set: { rating = $0 }), maximum: 5, label: "Quality")
        control.setValue(8)
        XCTAssertEqual(rating, 5)
        XCTAssertEqual(control.render().props.custom["role"], "rating")
    }

    func testToggleGroupSelectionSemantics() {
        let first = SelectionOption("one", label: "One")
        let second = SelectionOption("two", label: "Two")
        var selected: Set<String> = ["one"]
        let binding = Binding<Set<String>>(get: { selected }, set: { selected = $0 })
        let group = ToggleGroup(options: [first, second], selected: binding, mode: .single, label: "Choice")

        group.toggle(second)
        XCTAssertEqual(selected, ["two"])
        group.toggle(second)
        XCTAssertTrue(selected.isEmpty)
        XCTAssertEqual(group.render().props.custom["role"], "radioGroup")
    }

    func testSelectAndNativeSelectUseSameBindingWithDifferentPresentation() {
        let one = SelectionOption(1, label: "One")
        let two = SelectionOption(2, label: "Two")
        var selected = 1
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let select = Select("Count", selection: binding, options: [one, two])
        select.select(two)
        XCTAssertEqual(selected, 2)
        XCTAssertEqual(select.render().props.custom["presentation"], "menu")

        let native = NativeSelect("Count", selection: binding, options: [one, two])
        XCTAssertEqual(native.render().props.custom["presentation"], "native")
        XCTAssertEqual(native.render().props.custom["role"], "comboBox")
    }

    func testInputAndButtonGroupsExposeSemanticRoles() {
        var text = ""
        let inputGroup = InputGroup(
            leading: { Text("$") },
            input: { Input(text: Binding(get: { text }, set: { text = $0 })) }
        )
        XCTAssertEqual(inputGroup.render().props.custom["role"], "inputGroup")

        let buttons = ButtonGroup(label: "Actions") { Button("Save") {} }
        XCTAssertEqual(buttons.render().props.custom["role"], "group")
        XCTAssertEqual(buttons.render().props.accessibilityLabel, "Actions")
    }

    func testCatalogFixtureBuildsAllP2EntryControls() {
        let fixture = P2DataEntryDemoScreen().render()
        XCTAssertGreaterThanOrEqual(fixture.children.count, 10)
    }
}
