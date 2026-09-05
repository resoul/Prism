# ADR 0044: Calendar Civil-Date Layouts

`CalendarLayout` derives deterministic month/week/day cells from `CalendarService`, including locale-first weekday symbols and explicit selected-day flags. Month cells include leading boundary days while marking displayed-month membership; week and day layouts preserve civil dates across DST transitions. RTL is metadata for the host renderer, not a mutation of date order.

Events and scheduling remain outside this model. Consumers can snapshot the value output without platform views.
