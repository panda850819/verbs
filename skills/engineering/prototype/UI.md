# UI Prototype

Several **structurally different** variants on a single route, switchable from
a floating bottom bar. The user flips between them in the browser, picks one
(or steals bits from each), and the rest is thrown away. If the question is
about logic or state, wrong branch: [LOGIC.md](LOGIC.md).

## Two sub-shapes — strongly prefer A

Variants are easiest to judge **butting up against the rest of the app** —
real header, real data, real density. A route in a vacuum makes every variant
look fine.

- **A — inside an existing page (default).** Variants render on the existing
  route behind `?variant=`; data fetching, params, and auth all stay — only
  the rendered subtree swaps. Something new that would naturally live inside
  an existing page (a new dashboard section, a new settings card) is still
  sub-shape A: mount the variants inside the host page.
- **B — a new throwaway route (last resort).** Only when there is genuinely no
  existing page to host it. Follow the project's routing convention and name
  the route obviously-prototype. Sanity-check first: an empty route hides
  design problems a populated one would expose.

## Process

### 1. State the question and pick N

Default **3 variants**, cap 5 — beyond that stops being radically different
and starts being noise. One-line plan in a top-of-file comment: "Three
variants of the settings page via `?variant=` on `/settings`."

### 2. Generate structurally different variants

Hold each variant to the page's purpose, the data it actually has, and the
project's component/styling system; export clear names (`VariantA`, …).
Variants must disagree about structure — layout, information hierarchy,
primary affordance — not colours. Two drafts too similar → redo one with
explicit "do not use a card grid" style guidance.

### 3. Wire the switcher

One switcher component on the route reads `?variant=` and renders the matching
variant; existing data fetching stays above it. Sub-shape B mounts the same
switcher on the throwaway route.

### 4. The floating bar

Fixed at bottom-centre: left arrow · current label (`B — Sidebar layout`) ·
right arrow, wrapping both ways. Arrows update the URL param through the
framework's router so a variant is shareable and reload-stable; `←`/`→` keys
also cycle, except when an input, textarea, or contenteditable is focused.
Visually distinct from the design under judgment (high-contrast pill), and
hidden in production builds (`NODE_ENV !== 'production'` or equivalent) so a
stray merge can't ship it. One shared component, located with the project's
shared UI.

### 5. Hand it over

Surface the URL and the variant keys. The real feedback is usually "the header
from B with the sidebar from C" — that's the design they want.

### 6. Capture and clean up

Per [SKILL.md](SKILL.md): fold the winner into the existing page (A) or
promote it to a real route (B). The full variant set and the switcher land on
the throwaway branch, never the default branch — leftover variants rot fast
and confuse the next reader. Variant code was written under prototype
constraints (no tests, minimal error handling); rewrite it properly when
folding it in.

## Anti-patterns

- **Variants that differ only in colour or copy.** Real variants disagree
  about structure.
- **Sharing a `<Layout>` between variants.** A shared `<Header>` is fine; each
  variant must be free to throw the layout away.
- **Wiring variants to real mutations.** Read-only; stub anything that writes.
  The question is "what should this look like", not "does the backend work".
- **Promoting prototype code directly to production.**
