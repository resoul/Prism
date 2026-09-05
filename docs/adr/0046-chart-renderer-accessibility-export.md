# ADR 0046: Chart Renderer and Data Representation

`ChartModel` is a renderer-neutral value model for line, bar, and pie data. Non-finite points are dropped before hit-testing or decimation; deterministic endpoint-preserving decimation bounds 100k-point datasets. The same normalized data feeds an accessible table and CSV export, avoiding color-only meaning. Hosts may choose Metal, Core Graphics, or a text fallback without changing the public API.
