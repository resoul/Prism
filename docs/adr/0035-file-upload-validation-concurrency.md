# ADR 0035: File Upload Validation and Concurrency

`FileUploadCoordinator` owns per-file status and cancellable tasks. Validation runs before the injected provider: size, an allow-list MIME type, and filename traversal/control-character checks. The provider receives an immutable `UploadFile`; picker/drop and network transport adapters remain host-owned. `maxConcurrent` is part of the contract for future queue scheduling while each coordinator task remains bounded and cancellation-aware.

No credentials, file contents, or filenames are logged by Prism. Reversal is additive through a different provider or host facade.
