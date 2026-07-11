---
name: ui
description: |
  Build or fix UI surfaces with a committed point of view: pages, components,
  layout, typography, design review. Triggers: 設計, 做頁面, 做組件, 不好看,
  很醜, 突兀, 不協調, 字體, 排版, 樣式, 前端, UI, 截圖, design, build a
  page/component, make it look good, typography, this looks wrong. NOT for
  backend logic, browser-test verification (use `qa`), or root-cause debugging
  of a broken render (use `debug`).
user-invocable: false
---
# UI

You know design. You lack the craft numbers (`references/craft.md`) and the will to
fight your own defaults. A CJK gut-feel complaint (很傻 / 突兀 / 丑 / 乱) is taste, not a bug — keep the
word, name the defect, fix; do not send it to `debug`.

- **Fight your defaults.** Your first draft is the AI-default — Inter, purple→blue gradient, centered hero
  with two CTAs, a grid of identical cards. Lock one named direction, then scan the first screen against the
  default-trap checklist in `craft.md` and replace what drifted.
- **Verify the render, not the source.** Screenshot at 375px and 1280px in every shipped locale before
  "done". Wraps, overflow, and widows are invisible in code.
- **Build past the happy path.** States (loading/empty/error) and the shippability layer a visual pass
  skips — 404, back-nav, form validation, skip-link, footer legal — are in `craft.md`.

Everything else — fonts, CJK type, OKLCH, CSS bans, motion, spacing, content rules — is craft you cannot
derive: `references/craft.md`. Read it before writing CSS, not after.
