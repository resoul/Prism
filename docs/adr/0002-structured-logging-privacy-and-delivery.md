# ADR 0002: Structured logging with redaction and bounded asynchronous delivery

## Status

Accepted

## Context

Prism needs consistent diagnostics across Core, UI, Data, Storage and future renderer work. Direct
`print`, ad-hoc OSLog calls and synchronous file appends make traces hard to correlate, can block UI,
and risk exposing credentials or personal data in support files.

## Decision

1. `PrismLogging` is an independent target with no dependency on PrismUI, PrismData or PrismStorage.
2. Logs are immutable structured records with level, category, metadata, source location and optional
   TaskLocal trace context.
3. Metadata is explicitly public, private or sensitive. Console, OSLog and file sinks receive only
   a sanitized representation; sensitive values are never emitted.
4. Sink delivery is asynchronous through a bounded queue. A slow sink may cause record drops rather
   than block a caller or MainActor.
5. File logging is opt-in, NDJSON, rotating and retention-bounded. Prism does not upload diagnostics.

## Consequences

- Components and data services can share one correlation model without introducing UI/Data cycles.
- A message string must never include secret/user data because it is public by default.
- Logging is best-effort diagnostics, not a persistence, crash-reporting or error-recovery mechanism.
- Future upload/analytics/crash capture requires a separate ADR and explicit user-consent design.
