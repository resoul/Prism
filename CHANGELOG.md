# Changelog

All notable changes to Prism will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Added a release-scope evidence audit for original Tasks 01–21, including
  reproducible platform, accessibility, visual, and performance gaps.
- Added the pinned fresh-consumer sign-off fixture and proposed `0.1.0`
  compatibility/migration policy; tagging and publishing remain owner actions.

### Added
- Experimental P3 `DataGridInteractionModel`/`DataGridInteractionProvider`
  contracts with ID selection, sort/filter descriptors, and stale-load cancellation.
- Experimental P3 typed `FilterModel`/`FilterEditor` contracts with composable
  expressions, Codable migration, explicit null semantics, and validation.
- Experimental P3 `DataGridViewport`/`DataGrid` contracts with variable axis
  metrics, bounded mounted cells, pinned headers, anchors, and logical AX coordinates.
- Experimental P3 `TreeModel`/`LazyTreeLoader`/`Tree` contracts with stable
  ancestry, expansion, cancellable lazy loading, and bounded visible rows.
- Experimental P3 `CommandRegistry`/`CommandPaletteEngine` contracts with
  cancellable search, scoped shortcuts, stale-result protection, and safe ID execution.
- Experimental P3 `MenubarModel`/`Menubar` contracts with hierarchical command
  state, keyboard navigation, shortcut conflict handling, and focus metadata.
- Experimental P3 `SortableListModel`/`Sortable` contracts with stable-ID
  reorder, keyboard alternatives, cancellation, and bounded visible windows.
- Experimental P3 `ResizableSplit`/`Resizable` contracts with bounded ratios,
  RTL-aware keyboard resizing, nested composition, and cancellable capture.
- Experimental P3 `FileUploadCoordinator` with bounded validation,
  cancellation/retry statuses, filename sanitization, and injected transport.
- Experimental P3 `OTPDocument`/`InputOtp` contracts with bounded paste,
  backspace/autofill handling, visual segments, and privacy-safe AX semantics.
- Experimental P3 `PhoneInput`/`PhoneNumber` contracts with country-aware
  canonical formatting and shape-only validation.
- Experimental P3 `DateSelector` with CalendarService-backed formatting,
  min/max validation, navigation, cancellation, and focus-restore state.
- Experimental P3 `AutocompleteEngine` and `Autocomplete` facade with debounced,
  cancellable suggestions and generation protection for stale responses.
- Experimental P3 `Combobox` with searchable single selection, keyboard highlight,
  disabled-option handling, cancellation, and bounded virtualized windows.
- Experimental P3 `CalendarService` with injected clocks, non-Gregorian calendars,
  locale/time-zone formatting, DST gap/fold handling, and calendar arithmetic.
- Experimental P3 scoped `ClipboardStore` and `ScopedFileHandle` contracts with
  typed permission, revocation, close, and cancellation errors.
- Experimental P3 `DragSession` with stable-ID pointer capture, target
  negotiation, keyboard movement, scroll arbitration, and cancellation.
- Experimental P3 `GridLayoutSolver` for deterministic fixed, fractional,
  minmax, spanning, constrained, and RTL grid geometry.
- Release-gate artifacts: executable P0/P1/P2 catalog manifest, catalog tests, first-app and architecture docs, baseline procedure, 0.x release checklist, MIT licence, and dependency notice.
- P2 overlay, feedback, and navigation APIs: toast queueing/deduplication, progress, breadcrumbs, pagination, navigation menus, and semantic modal/floating overlay surfaces with deterministic single-modal coordination.
- P2 data-entry components: `ButtonGroup`, `NumberField`, `ToggleGroup`, `Slider`, `RangeSlider`, `Stepper`, `Rating`, `InputGroup`, `Select`, and `NativeSelect`, with shared Binding-based range and selection semantics.
- Initial Swift Package structure supporting iOS 16+, macOS 14+, and tvOS 17+.
- Modular target structure: `PrismCore`, `PrismUI`, `PrismStorage`, `PrismData`, `PrismLogging`, and umbrella `Prism`.
- Remote package dependency to `Flux` (v1.1.0).
- Architectural contracts: `MODULE_CONTRACT.md`, `API_DECISIONS.md`.
- Architecture Decision Record `ADR 0001: Encapsulation of Platform UI Frameworks Behind Pure Prism Abstractions`.
- Element identity foundation (`ElementID`) supporting type, explicit key, and sibling position.
- Selective import guarantees and package verification test suites.
- `PrismLogging`: structured Console, OSLog and opt-in rotating NDJSON file sinks with category filters, privacy redaction, trace context and bounded asynchronous delivery.
- Design Token System (`Color`, `Spacing`, `Radius`, `Shadow`, `Motion`, `ThemeColors`, `Colors`).
- `PrismConfig` and `BaseTokens` declarative result-builder DSL with pre-render validation (inheritance cycles, duplicate IDs, missing parents, negative metrics, empty families, and invalid hexes).
- Theme resolution and multi-level inheritance supporting `ThemeID` (`.light`, `.dark`, `.midnight`, `.brand(...)`) with complete token resolution.
- Three-tier theme priority resolution separating `ColorScheme` and `ThemeSelection` with subtree overrides.
- Typography engine: `FontRole`, `FontWeight`, `TypeScale`, `TextStyle`, `FontResolver` with thread-safe `CTFont` caching and system fallbacks, and `FontLoader` for bundle and URL registration.
- Architecture Decision Record `ADR 0003: Immutable Design Tokens and Pre-Render Theme Resolution`.
- Fail-fast theme construction and environment resolution: invalid configurations and unknown selected themes now throw typed `ConfigValidationError`s instead of silently substituting a fallback theme.
- `FontResolver` now exposes an optional `FontResolutionDiagnostic` callback when it uses a system-font fallback.
- Localization and adaptive text engine (`Locale`, `LayoutDirection`, `ContentSizeCategory`, `LocalizationEnvironment`).
- `LocalizedStringKey` with parameter interpolation and `LocalizationBundle` supporting in-memory tables, plural cardinality rules, development missing-key markers, and pseudo-localization.
- Typography scaling with Dynamic Type multiplier and `DynamicTypeConfig` min/max clamping.
- Direction-aware layout semantics: `DirectionalEdgeInsets` (`leading`/`trailing`) and `HorizontalAlignment` with automatic physical coordinate resolution.
- Thread-safe zero-allocation formatter cache: `LocaleFormatterCache` for date, number, and currency formatters.
- Architecture Decision Record `ADR 0003: Unified Localization, Dynamic Type and Directional Layout`.
- Immutable Virtual Render Tree (VRT): pure value types `RenderElement`, `ElementKind`, `ElementProps`, and `ElementID` (`typeName`, `key`, `siblingIndex`) completely decoupled from `CALayer` and host platform views.
- Declarative Component API: `Component` protocol, `ComponentContext`, and `@resultBuilder ComponentBuilder` supporting empty blocks, optionals, conditionals (`if/else`), and loops.
- Structural primitives: `Group` (inlined children with zero intermediate container nodes) and `Empty` (zero layout/visual footprint).
- Keyed `ForEach` enforcing stable entity identifiers for dynamic data, with identity preservation across reordering.
- P0 declarative component facade: `Text`, `Stack`, `HStack`, `VStack`, `Spacer`, `Rectangle`, `Circle`, and semantic placeholder `Icon`.
- Copy-on-write modifier pipeline (`width`, `height`, `frame`, `padding`, `margin`, `background`, `opacity`, `zIndex`, `key`, `testID`) with deterministic accumulation and overriding precedence rules.
- Visual tree debug serialization (`dumpTree()`) for developer diagnostics and test snapshot assertions.
- Architecture Decision Record `ADR 0004: Virtual Render Tree (VRT) & Declarative Component API` and getting started guide.
- Two-pass layout engine foundation: `LayoutNode`, `LayoutStyle`, `SizeValue` (`fixed`, `fraction`, `intrinsic`, `fill`, `range`), `SizeConstraint` (`unspecified`, `atMost`, `exactly`), `MeasuredSize`, `LayoutFrame`, and `EdgeValues`.
- Dimension constraints resolver with min/max clamping, conflicting constraint arbitration (`min > max` where min takes precedence), and prohibition of NaN, negative sizes, and infinite dimensions.
- CoreText leaf measurement engine (`TextMeasurePolicy`) with multi-line wrapping, line limits, custom line heights, and Unicode/emoji support.
- Shape (`Rectangle`/`Circle`) and `Spacer` leaf measurement policies.
- Scale-aware `PixelRoundingPolicy` for subpixel antialiasing and hairline gap prevention.
- Explicit invalidation lifecycle (`.clean`, `.layoutInvalidated`, `.measureInvalidated`) and developer diagnostic data (`LayoutDebugData`).
- Architecture Decision Record `ADR 0005: Two-Pass Layout Engine Architecture & Constraint Resolution` and layout constraints guide.
- Flexbox layout engine (`FlexSolver`): main and cross axis solvers, direction (`row`, `column`, `rowReverse`, `columnReverse`), `justifyContent` (`start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly`), `alignItems` and `alignSelf` (`start`, `center`, `end`, `stretch`, `baseline`), and gap distributions.
- Flexible space distribution with `flexGrow` and overflow absorption with `flexShrink`.
- Multi-line flex wrapping (`flexWrap: .wrap`) with line cross gap spacing.
- Multi-model positioning: `.flow`, `.absolute` (with `top`, `leading`, `bottom`, `trailing` offsets and containing block resolution), `.fixed` (viewport-relative), and `zIndex` stacking order; absolute children do not expand flow container dimensions.
- Formatted layout tree trace diagnostics (`LayoutTrace.dump` / `node.dumpTrace()`).
- Architecture Decision Record `ADR 0006: Flexbox Layout Engine & Multi-Model Positioning` and flex layout guide.
- CALayer rendering pipeline: `@MainActor` layer ownership model (`LayerRenderer`, `RendererFactory`), container renderer (`ContainerRenderer`), vector shape renderer (`ShapeRenderer` for `Rectangle` and `Circle`), and text renderer (`TextRenderer` with `CATextLayer` and CoreText typography).
- Implicit Core Animation action suppression by default via `RenderTransaction.perform(disableActions: true)`.
- Idempotent layer tree synchronization with element ID keying: zero duplicate layers and zero leaks across 100 repeated render passes.
- Display scale factor support (`@1x`, `@2x`, `@3x`) on `CATextLayer.contentsScale` for crisp Retina rendering.
- Deterministic sublayer z-index ordering and child renderer lifecycle (`destroy()` removes detached layers).
- Layer diagnostics (`LayerDiagnostics`) with total layer counting, layer tree formatted dumps, and detection of GPU offscreen-rendering hazards (`masksToBounds` combined with shadow).
- Architecture Decision Record `ADR 0007: CALayer Rendering Pipeline, Node Ownership, and Implicit Action Suppression` and CALayer rendering pipeline guide.
- Platform host bridge foundation: `PrismHost` protocol and platform-agnostic `@MainActor` `PrismHostEngine` driving two-pass layout (`LayoutTreeBuilder`) and CALayer synchronization without platform framework leaks.
- Native host view adapters: `HostUIView` (iOS/tvOS) and `HostNSView` (macOS) forwarding bounds, scale factors, safe area insets, and color scheme appearance updates.
- Universal `PrismHostView` typealias in `PrismUI` providing a unified consumer entry point across platforms.
- Cross-platform vertical smoke scene (`SmokeScene`) combining theme background, vertical stack, typography, vector shapes (`Rectangle`, `Circle`), `Spacer`, and icons.
- Developer runtime inspector overlay (`isInspectorOverlayEnabled`) drawing layout wireframe boundaries, plus structured diagnostics dump (`engine.dumpDiagnostics()`).
- Host lifecycle test suite: 20-pass create/destroy cycles with zero layer accumulation or retention.
- Architecture Decision Record `ADR 0008: Platform Host Views, Host Engine, and Cross-Platform Smoke Verification` and platform host & smoke test guide.
- Persistent `MountedNode` hierarchy with owned `LayerRenderer`/`CALayer`, parent/child traversal, and isolated `SubscriptionBag` for lifecycle-scoped Flux cancellation.
- `Reconciler.diff` computing minimal patch sets (`NodePatch`): in-place updates with layer reuse, insertions, removals, keyed moves, and type replacements.
- Keyed sibling reconciliation with duplicate key detection, plus unkeyed sibling sequential fallback and mutation warnings.
- Topological patch application: removals/unmounts -> updates/replaces with layer reuse -> insertions/mounts -> two-pass layout -> CALayer frame synchronization.
- Reactive state-binding layer (`MountedNode.bind(to:)` / `ReactiveBinding`) over Flux `CurrentValue`, `CurrentValueDistinct`, and generic `Flux` streams on `@MainActor`.
- High-frequency update coalescing (`UpdateCoalescer`) buffering rapid state bursts (100+ updates) into a single frame pass while strictly delivering the final settled value.
- Comprehensive developer reconciliation diff log (`ReconcilerDiff`) with counters for mounts, updates, unmounts, moves, and reused layers.
- Architecture Decision Record `ADR 0009: VRT Reconciler, MountedNode Lifecycle, and Flux-Driven Reactivity` and reconciler guide.
- Local component state store (`ComponentStateStore`) retained per `(ElementID, name)`, executing initial state closures once on mount and surviving parent rebuilds.
- Automatic component state purging on `MountedNode.unmount()` or explicit element key/type change during reconciliation.
- Two-way data binding (`Binding<Value>`) with getter/setter closures, dynamic member lookup for struct properties, projection mapping (`map`), optional fallback subscripts (`[default:]`), and collection indexing (`[index]`).
- Reactive feedback loop prevention in bindings via `setIfChanged(_:)` to avoid redundant render passes when assigning identical values.
- Asynchronous lifecycle effect management (`EffectScope`) supporting `.task(id:priority:operation:)`, `.onAppear`, and `.onDisappear` hooks with automatic structured task cancellation on unmount (`.unmounted`) and ID changes (`.idChanged`).
- Four explicit state ownership tiers (`StateOwnershipTier`): `appStore` (Flux), `screenState` (`ComponentContext`), `componentState` (`ComponentStateStore`), and `keyedListItemState` (virtualized list rows).
- State inspector diagnostics (`StateInspector.dump(for:)`) reporting active Flux subscriptions, running async effects, cancellation reasons, and component state keys.
- Architecture Decision Record `ADR 0010: Component State, Two-Way Binding, and Lifecycle-Scoped EffectScope` and component state and lifecycle guide.
- Unified, platform-neutral input event system (`Event`, `EventPhase`, `EventResult`, `EventModifiers`, `PointerType`, `PointerButton`) with strongly-typed pointer, keyboard, scroll, and focus payloads.
- Three-phase event propagation engine (`EventDispatcher`) implementing capturing, target, and bubbling dispatch with `stopPropagation()` and `preventDefault()` semantics.
- Reverse-z hit testing engine (`HitTester`) respecting zIndex hierarchy, sibling drawing order, clipping boundaries (`.clipped()`), and element opacity.
- Hover transition tracking (`.pointerEnter`, `.pointerLeave`) and gesture synthesis (`.tap`).
- Reactive `FocusTree` managing keyboard Tab order, explicit `focusOrder` prioritization, and 2D spatial direction navigation (`.up`, `.down`, `.left`, `.right`) backed by Flux `CurrentValueDistinct`.
- Automatic stale focus clearing to prevent focus retention when a focused node unmounts.
- Synchronized semantic accessibility tree (`AccessibilityTree`) supporting `AccessibilityTraits`, actions (`.activate`, `.increment`, `.decrement`), labels, hints, values, and strict stale record invalidation.
- Deterministic UI-test identifier lookup (`testID`) in iOS and macOS host view bridges (`findAccessibilityElement(byTestID:)`) isolated from user-facing localized text.
- System accessibility tokens (`reduceMotion`, `increaseContrast`) added to `LocalizationEnvironment`.
- Centralized `KeyboardShortcutRegistry` with duplicate shortcut conflict detection diagnostics (`ShortcutConflict`).
- Architecture Decision Record `ADR 0011: Unified Input Events, FocusTree, and Synchronized Accessibility Tree` and events, focus, and accessibility guide.
- Root `OverlayHost` with named tiers (`content`, `floating`, `modal`, `toast`, `debug`), strict z-ordering (0, 1000, 2000, 3000, 4000), unclipped child containers (`masksToBounds = false`), and modal backdrop layer.
- `Portal(layer:)` component and `.portal(layer:)` modifier projecting visual CALayers into overlay tiers while retaining logical component parentage, state ownership, environment inheritance, and event bubbling.
- Geometric anchor preference contract (`.anchor(id:)`, `AnchorRegistry`) supporting popover/tooltip positioning relative to an anchor with automatic invalidation on scroll, resize, and unmount.
- Automatic anchor unmount handling dismissing associated overlays with `.anchorUnmounted`.
- Modal lifecycle management: focus transfer on presentation, automatic focus restoration on dismissal, pointer blocking via backdrop, backdrop tap dismissal (`.backdropTap`), and Escape key dismissal (`.escapeKey`).
- Public `.testID(String)` modifier on `RenderElement` and `Component` with development diagnostics (`TestIDValidator`, `TestIDConflict`) for duplicate test ID detection and automated UI test lookup.
- Reverse-z overlay hit testing in `HitTester` evaluating tiers in top-down order (`debug` -> `toast` -> `modal` -> `floating` -> `content`) and blocking background pointer events during modal presentation.
- Architecture Decision Record `ADR 0012: OverlayHost, Portal Projection, and Component Testability` and overlay host & portal guide.
- Unified `IconSource` supporting `.sf(name:)`, `.svg(named:bundle:)`, `.svgURL(URL)`, `.path(CGPath, viewBox: CGRect)`, and `.raster(named:bundle:)`.
- Standardized icon modifiers: `.iconSize(IconSize | Double)`, `.iconColor(Color)`, `.iconWeight(IconWeight)`, and `.renderingMode(IconRenderingMode)`.
- Safe XML parser for SVG vector graphics subset supporting `<path>`, `<rect>`, `<circle>`, `<ellipse>`, `<line>`, `<polyline>`, `<polygon>`, `<g>`, `viewBox`, fill, stroke, stroke-width, opacity, and 2D transforms.
- W3C-compliant path data parser (`SVGPathParser`) with elliptical arc to cubic bezier subdivision and token scanner.
- Strict security rejection of XML external entities, `<script>`, `<style>`, `<foreignObject>`, `<filter>`, `<text>`, and external URLs with structured `SVGDiagnostic` emission and typed `SVGError.securityViolation`.
- Platform-internal bridge (`SFSymbolAdapter`) rendering Apple SF Symbols to `CGImage` without exposing AppKit or UIKit in public API.
- Dedicated `IconRenderer: LayerRenderer` visualizing vector SVGs via GPU-accelerated `CAShapeLayer` hierarchies and symbol bitmaps via `CALayer.contents`.
- Thread-safe `IconCache` with bounded capacity and automatic disk modification date invalidation.
- `IconRegistry` for registering named icon packs, asset directories, and collision policies (`.overwrite`, `.ignore`, `.error`).
- `Icon` component primitive in `PrismUI` with semantic static factory helpers (`Icon.sf`, `Icon.svg`, `Icon.path`, `Icon.raster`).
- Architecture Decision Record `ADR 0013: Icon System and Safe SVG Subset` and icon system & SVG developer guide.
- CoreText-driven text editing engine: `TextDocument` managing text mutations, UTF-16 and Swift String index bridging, `TextSelection` ranges, composing/marked IME text, and Foundation `UndoManager` integration.
- `TextEditorMetrics` CoreText measurement engine calculating line fragments, character rects, caret geometry, and hit-testing (point-to-index).
- `TextEditorRenderer: LayerRenderer` managing pure CALayer rendering: textLayer, selectionLayer, caretLayer with 1.0s blinking animation (pausing when unfocused), placeholderLayer, and scroll offset tracking.
- Platform text-input bridge (`PlatformTextInputAdapter`) and `HostNSView` conformance to `NSTextInputClient` supporting IME composition, clipboard cut/copy/paste, and keyboard navigation without leaking platform UI framework classes.
- Focus scopes and keyboard submission: `FocusScopeManager`, focus restoration after dismissal, `.focusScope()`, `.onSubmit()`, and `.submitLabel()`.
- Data validation rules: `ValidationRule` (`.required`, `.email`, `.minLength`, `.maxLength`, `.custom`) and `ValidationResult`.
- P1 interactive data entry controls in `PrismUI`: `Input`, `Textarea`, `Button` (with variants and sizes), `Checkbox`, `RadioGroup`, `Switch`, `Toggle`, `Field` (with labels and error feedback), and `Form`.
- Architecture Decision Record `ADR 0014: Core Text Editing Engine and Interactive Form Controls` and text editing & forms developer guide.
- Value-type asynchronous state machine: `Loadable<Value>` with `.idle`, `.loading(previous:)`, `.loaded`, `.refreshing(previous:)`, and `.failure(error:previous:)` preserving stale data during background revalidations and retry states.
- Typed error classification: `LoadableError` with categorized error codes (`.network`, `.timeout`, `.unauthorized`, `.forbidden`, `.notFound`, `.serverError`, `.decoding`, `.cancelled`) and sanitized debugging details.
- Generic `PageLoader` and `PageCache` protocols decoupled from concrete networking or database engines.
- Generic `PagedStore<Item, Query, Cursor>`: actor/serialized state machine with reactive Flux `CurrentValueDistinct` stream, synchronous `currentState` snapshot, automatic in-flight request deduplication, deterministic stable item ID merging, and monotonic query generation tracking.
- Declarative UI `Resource<Value>` component in `PrismUI`: customizable content, loading, failure, and empty state builders with accessibility traits and zero network ownership.
- Architecture Decision Record `ADR 0015: Loadable, Resource, and Generic PagedStore` and loadable & paged store developer guide.
- Pure Swift deterministic scroll physics engine: `ScrollPhysicsEngine`, `ScrollPosition`, `ScrollAxis`, `ScrollAnchor`, `ScrollStateSnapshot`, and `PullToRefreshState` supporting drag deltas, friction deceleration decay, rubber-band spring dampening, and unconsumed remainder propagation for nested containers.
- Render-tree scroll container: `ScrollAreaRenderer: LayerRenderer` with clipped viewport container (`masksToBounds = true`), content translation layer (`CATransform3DMakeTranslation`), and automatic vertical/horizontal fading scroll indicator layers.
- Declarative `ScrollArea` component in `PrismUI` with `ScrollProxy` programmatic coordinate/anchor targeting (`scrollTo`), `.pinnedHeader()`, and `.scrollTarget(id:)`.
- Keyed virtualized list and grid windowing: `VirtualizationWindow` computing visible and overscan item ranges to enforce strictly bounded CALayer and memory consumption (e.g. ~35 layers for 10,000 items).
- Cell reuse pool (`CellReusePool`) caching and recycling idle layer hierarchies by template identifier with full transient state reset (`isSelected`, `isHighlighted`, transforms).
- Priority render scheduler: `RenderScheduler` and `DisplayTransaction` providing background execution queues across prioritized tiers (`immediate`, `prefetch`, `idle`) with task cancellation tokens, element-scoped eviction, and atomic `@MainActor` layer synchronization.
- Asynchronous downsampled image pipeline: `ImageSource`, `ImageDownsampler` off-main-thread decoding via `CGImageSourceCreateThumbnailAtIndex` with exact pixel bounds and retina scaling, `ImageMemoryCache` (LRU byte budget), `ImageLoader` with concurrent in-flight deduplication, and `ImageRenderer` with stale cell reuse protection and smooth fade-in transitions.
- Declarative UI components in `PrismUI`: `LazyList` (virtualized vertical list with prefetch triggers), `LazyGrid` (responsive multi-column virtualized grid), and `Image` (content modes, corner radii, and placeholder builders).
- Architecture Decision Record `ADR 0016: Scroll Engine, Virtualization Windowing, and Async Image Pipeline` and scroll virtualization & images developer guide.
- Shared collapsing header coordinator: `HeaderCollapseCoordinator` managing `expandedHeight`, `collapsedHeight`, `collapseRange`, and `collapseProgress` with cross-tab header collapse preservation and independent page residual scroll depth tracking.
- 2D pan gesture disambiguation engine: `GestureArena` providing slop-threshold (default 10pt) arbitration between horizontal page transitions and vertical active list scrolling.
- Horizontal page container with neighbour mount policy: `PagePager` and `NeighbourMountPolicy` instantiating only active and immediate neighbour pages (`[index - 1, index, index + 1]`) while unmounting distant pages to release CALayers and pause background tasks.
- Sticky tabs component: `PinnedTabs` with sliding indicator line, selection state, keyboard navigation, and VoiceOver accessibility traits.
- End-to-end collapsing tab pager component: `CollapsingTabPager` in `PrismUI` with `@TabPageListBuilder` declarative API and `Binding` support.
- Heavy integration benchmark & demo: `ProfilePageDemo` reproducing `ProfilePage-main` with three independent `PagedStore`s (Posts, Likes, Reposts) rendering 10,000 synthetic items in virtualized `LazyGrid`s with async images, prefetch triggers, in-flight deduplication, and query generation cancellation.
- Architecture Decision Record `ADR 0017: CollapsingTabPager, Gesture Arena, and Shared Header Coordinator` and collapsing tab pager developer guide.
- P1 Data Display components in `PrismUI`: `Badge` (with semantic variants `.default`, `.secondary`, `.destructive`, `.outline`), `Label` (icon and text composite with accessibility synthesis), `Avatar` (with async image loading and fallback initials), `Card` (with `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, and `CardFooter` subcomponents), and `IconTile` (rounded accent tile with optional badge).
- P1 Feedback components: `Alert` (semantic variants `.info`, `.warning`, `.success`, `.destructive` with automatic icon pairing) and `Spinner` (Core Animation rotating indicator with automatic `reduceMotion` accessibility adaptation).
- P1 Navigation component: `Tabs` with two-way selection binding, keyboard navigation (arrow keys), and semantic `tab` / `tabpanel` accessibility linking.
- P1 Modal Overlay components: `Dialog` (with focus trap, dimmed backdrop layer, and Escape/action dismissal) and `Tooltip` (floating contextual hint in `.floating` tier with placement and delay).
- P1 Layout primitives: `Divider` (hairline separator with theme-aware border color) and `Frame` (explicit dimension boundaries and alignment constraints).
- Extensible styling contracts in `PrismUI`: `ButtonStyle`, `InputStyle`, and `CardStyle` protocols with built-in ShadCN-style defaults, decoupling aesthetics from accessibility invariants.
- Vertical integration screen: `P1DemoScreen` verifying cohesive operation across form validation, tabs, avatars, alerts, dialogs, and tooltips.
- Architecture Decision Record `ADR 0018: P1 Component Catalog and Extensible Style Contracts` and P1 component catalog developer guide.
- Declarative animation primitives in `PrismCore`: `Animation` supporting timing curves (`.linear`, `.easeIn`, `.easeOut`, `.easeInOut`, `.timingCurve`), physically-based springs (`.spring`, `.bouncy`, `.snappy`, `.smooth`, `.interpolatingSpring`), and chainable modifiers (`.delay`, `.speed`, `.repeatCount`, `.repeatForever`).
- Ambient transaction scoping: `Transaction` and `withAnimation` with nested transaction inheritance and suppression under `disablesAnimations: true`.
- Zero model drift Core Animation layer bridge: `LayerAnimationBridge` immediately synchronizing layer model properties under actions-disabled `CATransaction` and attaching explicit `CAAnimation` objects sampled from the current presentation layer, eliminating jump-back glitches upon completion or interruption.
- Structural transitions in `PrismCore` and `PrismUI`: `Transition` supporting `.identity`, `.opacity`, `.scale`, `.slide`, `.move`, `.offset`, `.combined`, and `.asymmetric` transitions.
- Reconciler deferred removal retention and resurrection: `Reconciler` holds nodes undergoing exit transitions mounted in `parent.animatingOutChildren` until completion, and cleanly cancels exit animations and resurrects nodes if re-inserted mid-transition.
- Universal `Reduce Motion` accessibility support: `ReduceMotionPreference` automatically collapses animation durations to zero and converts physical spatial transitions to gentle crossfades without component boilerplate.
- Keyframe animation API: `KeyframeTrack` and `KeyframeAnimationToken` supporting bounded or repeating playback with cancellation on unmount.
- Telemetry and diagnostics: `AnimationInspector` and `AnimationInspectorTelemetry` displaying active transaction IDs, running animation counts, and transition lifecycle logs.
- Architecture Decision Record `ADR 0019: Declarative Animation and Transition Lifecycle` and animation & transitions developer guide.
- Persistence and Preferences subsystem in `PrismStorage`: `Preferences`, `PrefKey`, and `@Preference` property wrapper providing type-safe `UserDefaults` access with reactive Flux change streams.
- Platform Keychain security: `SecureStore` isolating tokens and credentials with accessibility policies (`.afterFirstUnlock`, `.whenUnlocked`), namespaced service isolation, and zero log leakage.
- Actor-backed atomic filesystem storage: `FileStore` and `FilePath` supporting thread-safe atomic writes, automated directory creation, corruption recovery, and `FileWatcher` broadcasting file change events via `Flux<FileChangeEvent>`.
- Multi-tier composite caching in `PrismStorage`: `MemoryLRUCache` (O(1) doubly-linked list LRU eviction with cost, count, and TTL limits), `DiskCache` (actor-isolated sandbox persistence with size-budget pruning and TTL), and `HybridCache` (two-tier memory + disk cache with automatic disk promotion).
- Pure HTTP value models and client in `PrismData`: `HTTPRequest` (fluent builder, query items, JSON encoding), `HTTPResponse` (status checking, decoding), `HTTPTransport` protocol, `URLSessionTransport`, and `HTTPClient` with interceptor chains (`BearerTokenInterceptor`), exponential retry policy with jitter (`RetryPolicy`), and header credential redaction (`HeaderSanitizer`).
- Resilient WebSocket client: `WebSocketClient` built on `URLSessionWebSocketTask` with exponential reconnect loops (`ReconnectPolicy`), lifecycle state tracking (`WebSocketState`), and reactive `Flux<WebSocketMessage>` message streams.
- Reactive Repository & Store: `Repository<Key, Entity>` orchestrating `HybridCache` and remote fetches with `FetchStrategy` (`.cacheOnly`, `.networkOnly`, `.cacheFirst`, `.networkFirst`, `.cacheAndNetwork`), and reactive `Store<State>` actor isolating mutations and publishing state strictly via `Flux<State>` without UI dependencies.
- Test doubles and domain reference implementations: `MockHTTPTransport`, `MockWebSocketTransport`, `UserProfile`, `ProfileRepository`, and `ProfileStore` enabling 100% offline testing with synthetic data.
- Architecture Decision Record `ADR 0020: Storage, Cache, and Reactive Data Layer` and storage and data developer guide.
- Route pattern matching and deep linking engine in `PrismUI`: `RouteParameters`, `RoutePattern` (static, `:parameter`, wildcard `*`, query items `?k=v`), `Route`, `Router` with 404 fallback handler, and `DeepLinkResolver` parsing custom schemes (`prism://...`) and Universal Links (`https://...`).
- Versioned navigation stack manager in `PrismUI`: `RouteEntry`, `NavigationState` (`version = 1`, Codable), `Navigator` with stack operations (`push`, `pop`, `replace`, `reset`, `restore`), safe root pop boundary enforcement (safe no-op returning `false`), and `NavigatorView` with customizable transitions.
- Container-derived responsive layout subsystem in `PrismUI`: `Breakpoint` (`compact`, `medium`, `expanded`, `wide`), `ResponsiveValue<T>` with downward cascading fallbacks, `ResponsiveContainer`, and `.visible(on:)` / `.hidden(on:)` component modifiers.
- Turnkey application layout: `Scaffold` in `PrismUI` with named slots (`topBar`, `bottomBar`, `sidebar`, `overlay`, `content`), `SafeAreaPolicy`, and `AutoScrollPolicy` with automatic `ScrollArea` wrapping.
- macOS thin platform bridge in `PrismUI`: `ToolbarItem`, `ToolbarPlacement`, `MenuCommand`, `WindowGroup`, and `WindowManager` modeling desktop toolbars, menu hierarchies, and multiple windows without leaking AppKit types.
- Decoupled navigation state restoration in umbrella `Prism`: `PrismStorageNavigationStore` bridging `NavigationState` to `PrismStorage.Preferences` without violating `MODULE_CONTRACT.md` dependencies.
- Interactive cross-platform demo flow: `NavigationDemoFlow.swift` with deep-linked profile, responsive mobile/desktop scaffold switching, and multi-window management.
- Architecture Decision Record `ADR 0021: Navigation, Responsive Layout, and macOS Window Integration` and navigation & responsive layout developer guide.
- Optional GPU-accelerated Metal backend in `PrismCore`: `MetalDeviceContext` with device discovery, async pipeline compilation, and GPU frame budget tracking (`MetalFrameBudget`).
- Embedded Metal Shading Language (MSL) shaders: anti-aliased Signed Distance Field (SDF) rounded rectangles, frosted glassmorphism with blur, saturation boost, and specular tint, and multi-point 2D mesh gradients.
- `CAMetalLayer` lifecycle and compositing: `MetalLayer` managing Retina scale factors, sRGB color spaces, dynamic resize policies, and unmount resource purging (`purgeResources`).
- Graceful CALayer fallback path: `MetalEffectRenderer` seamlessly falling back to standard `CALayer` corner radii, borders, semi-transparent frosted tints, and `CAGradientLayer`s on non-Metal environments or simulated failures.
- Declarative public API in `PrismUI`: `MeshGradient` component and `.sdfRoundedRect(...)`, `.glassmorphism(...)`, and `.meshGradient(...)` modifiers extending `Component` and `RenderElement` without leaking Metal types.
- Isolated demonstration scene: `MetalEffectsDemo` showcasing SDF cards, frosted glassmorphism, multi-color mesh gradient, and live fallback simulation.
- Architecture Decision Record `ADR 0022: Optional Metal Renderer and Visual Effects` and Metal effects and shaders developer guide.
- P2 Data Display components in `PrismUI`: `Kbd` (keyboard shortcut badges with monospace typography and semantic accessible names), `CodeBlock` (safe multi-line snippet viewer with line numbers and copy action), `Table` (static multi-column table supporting up to ~1,000 rows with zebra striping, borders, and column text alignments), `Timeline` (vertical chronological milestone progression with status markers, timestamps, and connecting lines), and `Empty` (turnkey empty state view with icon, title, description, and action button).
- P2 Feedback and Layout primitives in `PrismUI`: `Skeleton` (placeholder shimmer loader with `.rounded`, `.circle`, and `.rectangle` shapes, automatically suppressing animation under `reduceMotion`), `HoverCard` (contextual preview popup projecting into `OverlayLayer.floating` via `Portal`), and `AspectRatio` (container enforcing fixed $w/h$ ratios with `.fit` and `.fill` modes and fluent `.aspectRatio(_:contentMode:)` modifier).
- P2 Disclosure components in `PrismUI`: `Collapsible` (standalone expandable panel with smooth opacity/height transition and keyboard accessibility) and `Accordion` (multi-section coordinator supporting `.single` and `.multiple` expansion modes with two-way `Binding<Set<String>>`).
- Interactive showcase demo: `P2DemoScreen` cohesively demonstrating all 9 P2 display, feedback, layout, and disclosure primitives.
- Architecture Decision Record `ADR 0023: P2 Data Display and Layout Components` and P2 components developer guide.
