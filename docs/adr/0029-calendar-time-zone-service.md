# ADR 0029: Calendar and Time-zone Service

`CalendarService` owns a configured Foundation calendar, locale, time zone, and injected `PrismClock`. It validates civil components, reports DST gaps, exposes explicit repeated-time selection, and performs arithmetic in the configured calendar. The API contains no platform UI or EventKit types; adapters remain host-owned. Fixed clocks make tests deterministic and cancellation remains the responsibility of the consumer task.

Alternatives considered: exposing `DateFormatter`/`Calendar` directly (leaks mutable configuration) and using system time globally (non-deterministic tests). Reversal is additive: consumers can replace the service with their own implementation behind an injected boundary.
