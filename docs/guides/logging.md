# Structured logging

`PrismLogging` provides asynchronous, structured diagnostics for Prism applications and framework internals. It is safe to import independently:

```swift
import PrismLogging
```

The umbrella `Prism` product re-exports it for normal applications.

## Setup

Create one `LoggingSystem` at application startup and inject its category loggers into services or environment. Logging calls enqueue records and never wait for a sink on MainActor.

```swift
let logging = LoggingSystem {
    ConsoleSink(minimumLevel: .debug)
    OSLogSink(subsystem: "com.example.myapp")
    FileSink(
        directory: FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appending(path: "Logs"),
        minimumLevel: .info,
        rotation: .keepFiles(count: 5, maximumBytes: 5_000_000)
    )
}

let log = logging.logger(category: .http)
log.info("Profile loaded", metadata: [
    "status": .public(200),
    "itemCount": .public(24),
    "profileID": .private("42")
])
```

## Categories and levels

Use the supplied categories whenever possible: `app`, `ui.vrt`, `ui.layout`, `ui.renderer`,
`ui.events`, `ui.focus`, `ui.scroll`, `ui.performance`, `data.http`, `data.websocket`,
`storage.cache`, `storage.file`, and `navigation`. Custom categories use a stable namespaced string.

Use `trace`/`debug` only for development diagnostics, `info` for normal lifecycle, `warning` for
recoverable unexpected conditions, `error` for failed user-visible operations, and `fault` for an
invariant violation. Errors remain explicit UI/store state; logging is not an error-handling API.

## Privacy rules

Every metadata value has an explicit privacy class.

| Class | Output behavior |
|---|---|
| `.public(...)` | Written to enabled sinks. Use only non-sensitive operational values such as status code or item count. |
| `.private(...)` | Rendered as `<private>` in Console, OSLog and file export. |
| `.sensitive(...)` | Rendered as `<redacted>` in every sink. |

URLs default to private through `.url(url)`. Authorization headers, cookies, request/response bodies,
tokens, passwords, user-entered text, personal IDs, query parameters, and absolute user file paths
must be private or sensitive. Do not interpolate them into the message string, because messages are
always treated as public text.

## Files, retention and export

`FileSink` is opt-in. It writes sanitized newline-delimited JSON (`prism.ndjson`) on its actor,
rotates after the configured byte budget, and keeps only the configured number of rotations. It does
not depend on `PrismStorage`, so the logging module cannot create a package dependency cycle.

Support-log export must use `exportedLines()` or another sanitizing export path. Prism does not upload
logs, analytics, or crash reports. Any future transport/upload feature requires a separate consent,
security, retention, and privacy design.

## Traces and metrics

Wrap one logical operation in a trace to correlate records across an HTTP request, store update and
future render transaction:

```swift
try await LogTrace.withTrace {
    try await repository.refreshProfile()
}
```

`LoggingSystem.metrics()` exposes pending and dropped record counts. A bounded queue may drop records
under pressure; this protects UI work from slow file/console sinks. Performance benchmarks should
record these metrics alongside frame work, layer count and active display tasks.
