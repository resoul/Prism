# ADR 0024: P2 Data Entry Components

## Status
Accepted

## Context
Prism already has one platform-neutral text editing, binding, focus, and undo pathway. Extended form controls must preserve that ownership model under rapid reactive reconciliation rather than introducing per-component input state or platform framework types into the public API.

## Decision

- Add `ButtonGroup`, `NumberField`, `ToggleGroup`, `Slider`, `RangeSlider`, `Stepper`, `Rating`, and `InputGroup` to `PrismUI`.
- Numeric controls centralize finite-value validation, clamp to declared ranges, and quantize to `step`; their host semantics provide keyboard and accessibility increment/decrement behavior.
- Add generic `SelectionOption`, `Select`, and `NativeSelect`. `NativeSelect` carries only the semantic presentation request; the actual AppKit/UIKit adapter remains internal.
- Keep searchable selection and multi-select menu behavior explicitly in P3. `ToggleGroup` covers bounded inline multiple selections.
- Every control emits a role, current value, bounds where applicable, and a stable accessibility label for the existing accessibility tree.

## Consequences

Consumers compose all P2 controls using existing bindings and receive consistent range semantics. The immediate limitation is that host-native select presentation, pointer drag delivery, UI automation, and undo/redo need platform-host integration coverage; no alternate input engine or platform type leaks into the public product.
