# Experimental Clipboard and Scoped Files (P3)

`ClipboardStore` is the host-neutral clipboard contract. `ScopedFileHandle`
models a granted resource with explicit `close`, `cancel`, and `revoke`
lifecycle. Handle errors are typed (`permissionDenied`, `revoked`, `closed`),
and all operations are actor-isolated. Native pasteboard/security-scope
adapters belong in the host and must cancel handles when their screen unmounts.
