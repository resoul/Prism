# ADR 0028: Scoped Clipboard and File Resources

P3 consumers use `ClipboardStore` and `ScopedFileHandle` as platform-neutral
contracts. Access is explicit and errors distinguish permission denial,
revocation, and closed lifetime. Actors serialize reads/writes; `revoke()` and
`cancel()` clear or close resources so unmount paths cannot retain access. Host
adapters may bridge native pasteboards or security-scoped URLs, but those types
and permission prompts never appear in public Prism APIs. Upload transport is
out of scope.
