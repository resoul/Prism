# Release Performance Baseline

This is a pre-1.0 baseline procedure, not a claim of Instruments certification. The package suite currently verifies bounded 10k virtualization, pager prefetch behavior, renderer lifecycle, and effect fallback in deterministic tests.

| Scenario | Dataset / duration | Release budget | Automated evidence |
|---|---:|---:|---|
| 10k `LazyList` / `LazyGrid` | 10,000 stable IDs | bounded visible window; no linear layer growth | `VirtualizationTests` |
| Pager data flow | 10,000 synthetic items | only active/neighbour pages mounted | `CollapsingPagerIntegrationTests` |
| Theme churn | repeated rebuild | no duplicate mounted layers | `CALayerRendererTests` |
| Effects soak | 16.67 ms GPU target | documented fallback when unavailable | `MetalDeviceContextTests` |

Before a tagged release, record device/OS, cold launch, CPU, GPU, peak memory, layer count, and subscription/leak results for iOS, iPadOS, and macOS. Keep raw Instruments traces out of the repository; add only sanitized aggregate metrics to this table.
