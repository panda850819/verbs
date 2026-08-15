# Verbs (repo contract)

Verbs is an opinionated skill pack for taking software work from ambiguity to
verified delivery. The user-facing README lives at the repo root. This file is
the iteration contract: what an agent must keep true when changing this repo.

## Layout

- `skills/{engineering,productivity,meta}/<name>/SKILL.md` — the active
  skills, tiered core / ext in `manifest.toml`.
- `lib/` — canonical shared modules. The copies under `skills/*/lib/` are
  GENERATED from each skill's `resources[]`; never edit a vendored copy.
- `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/` — GENERATED
  skills-only distribution metadata.
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
3. Update the `RESOLVER.md` catalog row and the skill's own description when
   routing changes.
4. Bump `[manifest] version` — the bump is what refreshes installed plugin
   caches on both hosts.
5. Record the change in `CHANGELOG.md`.

To retire a lib resource: remove it from `resources[]`, run sync (it prunes
the vendored copy against the still-present canonical file), then delete the
canonical file — in that order; sync fails loud otherwise.

## Verify

`bash tests/run-all.sh` — invocation policy, sync determinism, doctor parity,
structural lint. Green before any PR; CI runs the same suite on macOS.

## Authoring bar

`maintainer/writing-great-skills.md` (construction lore) and
`maintainer/SKILL-FRONTMATTER.md` (frontmatter contract). A new skill must
name the surface it replaces or extends, clear `.out-of-scope/` precedent,
and take a RESOLVER row plus a concrete routing description.

## Project Contract

The root `AGENTS.md` `## verbs` block is the only authoritative project policy.
`CLAUDE.md` is a compatibility target for the `AGENTS.md` symlink, not a second
contract. Every coding task must apply `lib/project-contract.md`: search GBrain
first, establish the Work Contract, automatically enter a Grilling Session when
intent is unclear, and implement only after confirmation.

GBrain stores evidence-backed project decisions, conventions, pitfalls,
preferences, and failed approaches in `lib/learning-format.md` shape. It is
historical evidence, not policy. GBrain failure is fail-soft. Promoting stable
memory into this file requires an exact preview and explicit human approval.

## verbs

work-source: github-issues
ticket-policy: required
goal-source: ticket-or-confirmed-prompt
acceptance-source: ticket-or-confirmed-work-contract
unclear-intent: automatic-grilling-session
gbrain: required-lookup-fail-soft
test: bash tests/run-all.sh
main: main
tag: semver
release: true
deploy: null
tracker: github

### Intake contract

Before implementation, read relevant GBrain memory and establish Goal, Scope,
Out of Scope, Acceptance Criteria, Constraints, and Delivery Target. If any
field is missing, ambiguous, or contradictory, automatically enter a Grilling
Session. Retrieve repository and ticket facts first, ask only current blocking
questions, present the resulting Work Contract, and wait for confirmation.

### Learning contract

Write only evidence-backed project memory to GBrain. GBrain never changes this
contract. Stable policy requires a previewed `AGENTS.md` diff and explicit human
approval.
