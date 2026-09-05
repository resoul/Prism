# ADR 0041: DataGrid Viewport and Bounded Cells

`DataGridViewport` separates row/column metrics from viewport state. Variable extents resolve offsets and visible indices; overscan and pinned rows/columns produce a bounded mounted-cell set for very large datasets. The scroll anchor is the first visible logical row/column, and AX coordinates remain logical rather than layer-based.

Editing, sorting, and platform grid rendering remain outside this contract. Consumers own stable row/column IDs around the integer viewport coordinates.
