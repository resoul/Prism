# FileUpload (P3)

Use the coordinator with an injected provider and validate before transport:

```swift
let uploads = FileUploadCoordinator(allowedMIMETypes: ["image/png"]) { file in
    try await transport.send(file.data)
}
await uploads.start(id: "avatar", file: UploadFile(name: "avatar.png", mimeType: "image/png", data: bytes))
```

Statuses cover idle, uploading, succeeded, failed, and cancelled. Call `cancel(id:)` on unmount or user cancellation and `retry(id:file:)` for an explicit retry. Filenames are checked for traversal/control characters, and MIME values are allow-listed when configured.

## Extending

Implement picker/drop adapters that create scoped handles and release them after ingestion. Keep transport credentials and file contents outside logs; use a bounded `maxBytes` and provider-level streaming for very large files.

## Limitations

This core contract stores `Data` in memory and does not itself implement streaming, queue-wide concurrency scheduling, MIME sniffing, or resumable uploads. Native permissions and network transport are host responsibilities.
