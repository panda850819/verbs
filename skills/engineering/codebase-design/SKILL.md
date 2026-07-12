---
name: codebase-design
description: |
  Deep-module design vocabulary: a lot of behaviour behind a small interface,
  placed at a clean seam, testable through that interface. Use when designing
  or reshaping a module's interface, deciding where a seam goes, judging
  shallow vs deep, making code testable, or when another skill needs these
  terms. NOT diff review (use `review`) or requirement discovery (use `grill`).
reads:
  - repo: "**"
writes:
  - cli: stdout
domain: shared
classification: tool
user-invocable: false
---
# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at
a clean seam, testable through that interface. The aim is leverage for callers,
locality for maintainers, and testability for everyone. Use these terms
exactly — consistent language is the point.

## Glossary

- **Module** — anything with an interface and an implementation; deliberately
  scale-agnostic (a function, class, package, or tier-spanning slice).
  _Avoid_: unit, component, service.
- **Interface** — everything a caller must know to use the module correctly:
  the type signature, plus invariants, ordering constraints, error modes,
  required configuration, and performance characteristics. _Avoid_: API,
  signature (type surface only).
- **Implementation** — what's inside the module.
- **Depth** — leverage at the interface: how much behaviour a caller (or test)
  can exercise per unit of interface learned. Deep = small interface, lots
  behind it; shallow = interface nearly as complex as the implementation.
- **Seam** _(Michael Feathers)_ — a place where behaviour can be altered
  without editing in that place; where a module's interface lives. Placing the
  seam is its own design decision, distinct from what goes behind it.
  _Avoid_: boundary (collides with DDD's bounded context).
- **Adapter** — a concrete thing satisfying an interface at a seam. Names the
  role it fills, not the substance inside.
- **Leverage** — what callers get from depth: one implementation pays back
  across N call sites and M tests.
- **Locality** — what maintainers get from depth: change, bugs, knowledge, and
  verification concentrate in one place.

## Deep vs shallow

```
┌─────────────────┐         ┌─────────────────────────────────┐
│ Small interface │         │         Large interface         │
├─────────────────┤   vs    ├─────────────────────────────────┤
│                 │         │       Thin implementation       │
│    Deep impl    │         └─────────────────────────────────┘
│                 │             (pass-through — avoid)
└─────────────────┘
```

When designing an interface, ask: fewer methods? simpler params? more
complexity hidden inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep
  module may be internally composed of small, mockable, swappable parts — they
  just aren't part of the interface. Internal seams (private to the
  implementation, used by its own tests) can coexist with the external seam.
- **The deletion test.** Imagine deleting the module. If complexity vanishes,
  it was a pass-through. If complexity reappears across N callers, it was
  earning its keep.
- **The interface is the test surface.** Callers and tests cross the same
  seam. Wanting to test past the interface means the module is probably the
  wrong shape.
- **One adapter means a hypothetical seam; two adapters make it real.** Don't
  introduce a seam until something actually varies across it.

## Designing for testability

1. **Accept dependencies, don't create them** — `processOrder(order, gateway)`
   beats constructing the gateway inside the function.
2. **Return results, don't produce side effects** —
   `calculateDiscount(cart): Discount` beats mutating the cart in place.
3. **Small surface area** — fewer methods, fewer tests; fewer params, simpler
   setup.

## Rejected framings

- **Depth as implementation-lines over interface-lines**: rewards padding the
  implementation. Use depth-as-leverage.
- **"Interface" as the language keyword or a class's public method list**: too
  narrow — include every fact a caller must know.
- **"Boundary"**: say seam or interface.
