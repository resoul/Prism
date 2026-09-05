# Release Performance Baseline

This is a pre-1.0 baseline procedure, not a claim of Instruments certification. The package suite verifies bounded 10k virtualization, pager prefetch behavior, renderer lifecycle, effect fallback, and deterministic release-soak scenarios. Wall-clock values printed by tests are host-dependent and sanitized; CPU/GPU/memory certification still requires local Instruments traces.

| Scenario | Dataset / duration | Release budget | Automated evidence |
|---|---:|---:|---|
| 10k `LazyList` / `LazyGrid` | 10,000 stable IDs | bounded visible window; no linear layer growth | `VirtualizationTests` |
| Pager data flow | 10,000 synthetic items | only active/neighbour pages mounted | `CollapsingPagerIntegrationTests` |
| Theme churn | repeated rebuild | no duplicate mounted layers | `CALayerRendererTests` |
| Effects soak | 16.67 ms GPU target | documented fallback when unavailable | `MetalDeviceContextTests` |
| 100-toast queue | 100 synthetic toasts; dismiss all | visible/pending queues return to zero | `PerformanceBaselineTests` |
| Theme churn | 100 catalog rebuilds | stable root tree size | `PerformanceBaselineTests` |

Before a tagged release, record device/OS, cold launch, CPU, GPU, peak memory, layer count, and subscription/leak results for iOS, iPadOS, and macOS. Keep raw Instruments traces out of the repository; add only sanitized aggregate metrics to this table.

Run the deterministic release-soak checks with `swift test --filter PerformanceBaselineTests`. The test output includes `elapsed_ms` and bounded counts; it does not claim frame rate, GPU, or memory results. Record unavailable Instruments environments as unverified.

## Sanitized deterministic sample

Captured 2026-09-05 on Apple M2, macOS 26.4.1, arm64, debug test build;
synthetic datasets, one process, single run. These values are regression
signals, not cross-device budgets.

| Scenario | Dataset / duration | Result |
|---|---|---:|
| Virtualization soak | 10,000 IDs, 101 windows | 126.93 ms; max rendered 56 |
| Toast queue soak | 100 toasts, enqueue + dismiss-all | 1.09 ms; visible/pending 0/0 |
| Theme churn | 100 catalog rebuilds | 169.95 ms; root children stable at 4 |
