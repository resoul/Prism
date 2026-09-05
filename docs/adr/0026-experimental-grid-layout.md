# ADR 0026: Experimental Grid Layout

Grid remains a P3 experimental API. `GridTrack` describes fixed, fractional,
and bounded (`minmax`) columns; `GridPlacement` supplies stable item identity
and spans. `GridLayoutSolver` is pure and deterministic: it resolves tracks
against a constrained width, clamps invalid values, and returns finite frames.
The solver owns no state, platform objects, or cancellation; consumers retain
state by stable item IDs and cancel their own async work on removal.

The first release covers track sizing, spans, nested constrained measurement,
RTL mirroring, and resize recalculation. DataGrid, sorting, and virtualization
remain separate work.
