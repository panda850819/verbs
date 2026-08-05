---
name: ui
description: |
  Build or fix UI surfaces with a committed visual direction: pages, components,
  layout, typography, motion, screenshots, or design review. Use for frontend
  work or visual complaints such as 不好看、突兀、死板、沒回饋感. NOT for backend
  logic, browser QA (`qa`), render bugs (`debug`), or throwaway exploration
  (`prototype`).
user-invocable: true
---
# UI

Native frontend tooling can render a surface; this skill adds a committed visual
direction, craft review, and rendered evidence. Load `references/craft.md` before
writing CSS, not after. A CJK gut-feel complaint (很傻 / 突兀 / 丑 / 乱) is taste, not a bug — keep the
word, name the defect, fix; do not send it to `debug`.

- **Fight your defaults.** Your first draft is the AI-default — Inter, purple→blue gradient, centered hero
  with two CTAs, a grid of identical cards. Lock one named direction, then scan the first screen against the
  default-trap checklist in `craft.md` and replace what drifted.
- **Verify the render, not the source.** Screenshot at 375px and 1280px in every shipped locale before
  "done". Wraps, overflow, and widows are invisible in code.
- **Build past the happy path.** States (loading/empty/error) and the shippability layer a visual pass
  skips — 404, back-nav, form validation, skip-link, footer legal — are in `craft.md`.

Done when the named direction passes the default-trap scan, required states are covered, and 375px/1280px screenshots are captured for every shipped locale.

Everything else — fonts, CJK type, OKLCH, CSS bans, motion, spacing, content rules — is craft you cannot
derive: `references/craft.md`.
