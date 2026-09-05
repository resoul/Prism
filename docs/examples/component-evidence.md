# Prism component evidence matrix

This inventory was audited against `main` revision `0242313` on 2026-09-05.
It distinguishes a public symbol from evidence that a user can operate the
rendered component. A model test or `props.custom` metadata entry is not native
interaction evidence.

## Evidence vocabulary

| Status | Meaning |
|---|---|
| `rendered` | A component-specific render path exists and has package/render-tree coverage. |
| `model-only` | A state/model contract and tests exist, but the visual component is a facade or placeholder. |
| `catalog-fallback` | The current Catalog routes the entry to a generic Card description. |
| `interaction-unverified` | A render path exists, but native iOS/macOS input and visible result have not been run. |
| `grouped` | This symbol is a slot/helper/alias covered by its owning component. |

## P0 and layout

| Symbol | Source area | Current evidence | Next owner |
|---|---|---|---|
| Text, Stack, HStack, VStack, Spacer | Primitives | rendered; Catalog metadata only | 23g |
| Rectangle, Circle, Icon, Image | Primitives | rendered; native visual evidence missing | 23g/23h |
| Frame, Divider, AspectRatio | Layout | rendered; native matrix missing | 23g |
| Grid, ScrollArea, ResponsiveContainer, Scaffold | Layout | rendered/model contracts; host behavior unverified | 23g/23l |
| LazyList, LazyGrid | DataDisplay | rendered/model virtualization tests; native scroll unverified | 23l |
| Resource | Feedback | model/component contract; no dedicated Catalog case | 23h |

## P1 and P2 components

| Category | Symbols | Current evidence | Next owner |
|---|---|---|---|
| Data display | Badge, Label, Avatar, Card, IconTile | component render paths; only Badge/Card have explicit Catalog cases | 23h |
| Data display | CodeBlock, Kbd, Skeleton, Empty | explicit Catalog cases; native actions/states unverified | 23h |
| Data display | Table, Timeline, HoverCard | render/model contracts; Catalog fallback or host-only behavior | 23h/23k |
| Data entry | Button, Input, Textarea, Checkbox, RadioGroup, RadioItem | component render paths; Button/Input explicit cases; native typing/focus unverified | 23i |
| Data entry | Switch, Toggle, Field, Form | component render paths; Catalog fallback; native validation unverified | 23i |
| Data entry | ButtonGroup, NumberField, ToggleGroup, Slider, RangeSlider | component/model contracts; Catalog fallback; native boundary/drag unverified | 23j |
| Data entry | Stepper, Rating, InputGroup, Select, NativeSelect | component/model contracts; Catalog fallback; host popup behavior unverified | 23j |
| Feedback | Alert, Spinner, Progress | component render paths; Catalog fallback; lifecycle/announcement unverified | 23k |
| Feedback | Toast | deterministic queue/model and component; native presentation remains host-owned | 23k |
| Navigation | Tabs, Breadcrumb, Pagination, NavigationMenu | render/model paths; no complete native route evidence | 23l |
| Overlay | Dialog, Tooltip, HoverCard, AlertDialog, Sheet, Drawer | render paths; native focus/anchor behavior unverified | 23k |
| Overlay | Popover, DropdownMenu, ContextMenu | semantic contracts; native menu/pointer paths unverified | 23k |
| Layout | Accordion, Collapsible | explicit Accordion Catalog case; expanded-state integration is incomplete | 23k/23q |

## P3 components and data contracts

| Symbol | Current evidence | Gap / owner |
|---|---|---|
| Combobox, Autocomplete | model/input facade; suggestions are metadata, not rendered rows | 23m |
| DateSelector | model and formatted trigger | 23n |
| PhoneInput, InputOtp | input contracts and simple render paths | 23o |
| FileUpload | status facade; chooser/drop/progress not proven | 23p |
| Resizable, Sortable | model/component facade; gesture/keyboard outcomes unverified | 23q |
| Menubar, CommandPalette | semantic facade; menu/results interaction unverified | 23s |
| Tree | stable model and text facade | 23r |
| DataGrid, FilterEditor | viewport/filter models and metadata facade | 23t/23u |
| CalendarView, EventCalendar | calendar/event models and metadata facades | 23v/23w |
| Chart | series model and semantic image facade | 23x |
| Kanban | stable board model and list facade | 23y |
| Gantt | dependency/reschedule model and grid facade | 23z |

## Shared APIs and grouped symbols

These are consumer-facing extension points and need examples, but they are not
separate visual screens: `Component`, `Screen`, `ComponentBuilder`, `Binding`,
`RenderElement`, `Theme`, `ThemeID`, `ThemeSelection`, `PrismConfig`,
`SystemThemeMapping`, `ButtonStyle`, `InputStyle`, `CardStyle`, `TabsStyle`,
`AnimationInspector`, `NavigatorView`, `PagePager`, `PinnedTabs`,
`CollapsingHeader`, `CollapsingTabPager`, and `PrismCatalogHost`.

Slots and structural helpers (`CardTitle`, `CardDescription`, `CardHeader`,
`CardContent`, `CardFooter`, `Option`, `AccordionItem`, `RadioItem`, and tab
item protocols) are grouped with their owning component. The registry must still
list them so a missing helper does not silently become a generic Card.

## Coverage rules for the next tasks

The Phase 07 registry must contain one descriptor for every symbol above. Each
descriptor is either a real interactive example, an explicitly grouped helper,
or an `incomplete` entry with an owner and a reproducible gap. “Pass” requires
visible rendered behavior and native input evidence on every platform claimed by
the descriptor. Unsupported platform actions must say `unavailable` and provide
the documented alternative.
