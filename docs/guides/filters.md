# Filters (P3)

Build typed, composable filters and serialize them for controlled editors:

```swift
let filter = FilterModel(expression: .all([
    .rule(FilterRule(field: "status", op: .equals, value: .string("active"))),
    .rule(FilterRule(field: "deletedAt", op: .isNull))
]))
try filter.validate()
let data = try filter.serialized()
```

Unknown schema operators migrate as `.unknown` and remain visible for user repair. Empty fields and missing rule values are invalid; null semantics are explicit through `.null` and `.isNull`.

## Extending

Add operators through a migration layer and translate validated rules into your backend predicates. Keep locale/collation policy in that layer and persist stable field names.

## Limitations

The core model does not execute queries, provide locale-specific comparison, or include a filter-chip UI. Unknown operators require an application migration before validation succeeds.
