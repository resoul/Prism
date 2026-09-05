# Experimental Grid Layout (P3)

`GridLayoutSolver` resolves deterministic column tracks (`fixed`, `fraction`,
`minmax`) and stable `GridPlacement` spans against a constrained width. It
returns finite `LayoutFrame` values and mirrors horizontal placement for RTL.

The API is experimental until two independent consumer scenarios and host
performance evidence are complete. DataGrid, sorting, and virtualization are
not part of this component.
