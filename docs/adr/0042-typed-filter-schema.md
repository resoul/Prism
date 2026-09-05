# ADR 0042: Typed Filter Schema

`FilterModel` is a Codable, backend-independent AST composed from typed rules and all/any/not groups. Operators and values are explicit; unknown operators decode as `.unknown` so persisted filters can migrate without data loss, then fail validation until the consumer supplies a mapping. Empty fields and missing values are rejected, while `isNull` intentionally accepts a null value.

Consumers own controlled editor state and backend predicate translation. Locale-specific comparison semantics are applied by the backend or consumer, never assumed by the core model.
