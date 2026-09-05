import XCTest
@testable import PrismCore

final class FilterModelTests: XCTestCase {
    func testRoundTripCompositionAndValidation() throws {
        let expression: FilterExpression = .all([.rule(FilterRule(field: "name", op: .contains, value: .string("Ada"))), .not(.rule(FilterRule(field: "age", op: .greaterThan, value: .number(100))))])
        let model = FilterModel(expression: expression); try model.validate(); let restored = try FilterModel.migrate(try model.serialized()); XCTAssertEqual(restored, model)
    }
    func testUnknownSchemaAndEmptyNullLocaleSemantics() throws {
        let json = #"{"schemaVersion":7,"expression":{"rule":{"_0":{"field":"name","op":"futureOp","value":null}}}}"#.data(using: .utf8)!
        let migrated = try FilterModel.migrate(json); XCTAssertEqual(migrated.schemaVersion, 1); XCTAssertThrowsError(try migrated.validate())
        let nullRule = FilterModel(expression: .rule(FilterRule(field: "deleted", op: .isNull))); XCTAssertNoThrow(try nullRule.validate())
    }
}
