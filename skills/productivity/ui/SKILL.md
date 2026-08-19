---
name: ui
description: |
  Production UI craft route when a page or component needs a committed visual
  direction, or a taste complaint such as 不好看、突兀、死板、沒回饋感 needs
  correction. Name the direction, implement required states, and verify rendered
  locales. Use `prototype` while direction is open, `debug` for render failures,
  and `qa` for browser acceptance evidence.
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
