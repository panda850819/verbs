# Verbs (repo contract)

Verbs is an opinionated skill pack for taking software work from ambiguity to
verified delivery. The user-facing README lives at the repo root. This file is
the iteration contract: what an agent must keep true when changing this repo.

## Layout

- `skills/{engineering,productivity,meta}/<name>/SKILL.md` — the active
  skills, tiered core / ext in `manifest.toml`.
- `lib/` — canonical shared modules. The copies under `skills/*/lib/` are
  GENERATED from each skill's `resources[]`; never edit a vendored copy.
- `hooks/` — the enforcement layer (SessionStart dispatch injection, Bash
  destructive + ticket-gate guards, Stop verify gate). Prose suggests; hooks
  block.
- `maintainer/` — skill-writing lore and the frontmatter spec. Not a runtime
  surface.
- `.out-of-scope/` — rejected directions with reopen conditions. Check it
  before proposing any new skill, folder, or adapter.

## Sync obligations (the invariants)

When adding, renaming, re-scoping, or removing a skill:

1. `manifest.toml` `[skill.<name>]` is the single source (tier, requires,
   resources, description).
2. Run `python3 scripts/verbs sync` — it regenerates the loader JSONs
   (`.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/`), the vendored lib
   copies, and the resource index. Hand-editing a generated file is drift the
   suite rejects.
3. Update the `RESOLVER.md` catalog row; touch `DISPATCH.md` only when routing
   changes.
4. Bump `[manifest] version` — the bump is what refreshes installed plugin
   caches on both hosts.
5. Record the change in `CHANGELOG.md`.

To retire a lib resource: remove it from `resources[]`, run sync (it prunes
the vendored copy against the still-present canonical file), then delete the
canonical file — in that order; sync fails loud otherwise.

## Verify

`bash tests/run-all.sh` — hook truth tables, sync determinism, doctor parity,
structural lint. Green before any PR; CI runs the same suite on macOS.

## Authoring bar

`maintainer/writing-great-skills.md` (construction lore) and
`maintainer/SKILL-FRONTMATTER.md` (frontmatter contract). A new skill must
name the surface it replaces or extends, clear `.out-of-scope/` precedent,
and take a RESOLVER row plus a dispatch slot if model-routed.

## Learnings

Skills may read the project path configured under `## verbs > learnings` and
emit candidates in `lib/learning-format.md` shape. They do not persist
knowledge; the host/project decides whether and where to store a candidate.

## verbs

test: bash tests/run-all.sh
main: main
tag: none
release: false
deploy: null
learnings: docs/learnings
