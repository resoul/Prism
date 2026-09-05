# ADR 0045: Event Calendar Overlap and Rescheduling

`EventCalendarModel` stores stable event IDs and separates all-day events from timed overlap layout. Timed events are assigned deterministic columns by start time and prior end; viewport filtering bounds layout work. Rescheduling mutates only an existing ID and can be cancelled before commit, allowing drag/keyboard hosts to restore the prior event.

Native calendar integrations, persistence, and recurring-event expansion remain outside the public API.
