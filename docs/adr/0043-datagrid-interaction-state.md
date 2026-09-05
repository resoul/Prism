# ADR 0043: DataGrid Interaction State

`DataGridInteractionModel` owns stable-ID selection and controlled sort/filter descriptors; replacing rows intersects selection so IDs survive reorder but disappear when removed. `DataGridInteractionProvider` cancels prior requests and applies results only for the current generation. Inline editing and backend-specific query semantics remain out of scope.
