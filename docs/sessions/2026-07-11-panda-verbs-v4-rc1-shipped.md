---
date: 2026-07-11
type: ship-record
status: shipped-rc
version: 4.0.0-rc.1
release: https://github.com/panda850819/panda-verbs/releases/tag/v4.0.0-rc.1
stable_not_before: 2026-07-18
---

# Panda Verbs v4 RC1 shipped

## Outcome

`pandastack` is now **Panda Verbs**: an opinionated skill pack for taking
software work from ambiguity to verified delivery. The repository is
`panda850819/panda-verbs`, the plugin and marketplace selector is
`verbs@verbs`, the callable namespace is `verbs:*`, and the canonical CLI is
`scripts/verbs`.

The RC contains 14 skills: 11 core and 3 extension skills. It owns procedural
skills, shared primitives, dispatch, explicit host adapters, install metadata,
evals, tests, and release validation. Identity, personal context, durable
knowledge/state, project systems of record, runtimes, schedulers, connectors,
and global model routing remain outside the package.

## Git and release evidence

| Surface | Evidence |
|---|---|
| Product migration | [Issue #180](https://github.com/panda850819/panda-verbs/issues/180), [PR #181](https://github.com/panda850819/panda-verbs/pull/181), source commit `96efbf3`, merge `a55a61b` |
| Repository rename | `panda850819/pandastack` → [`panda850819/panda-verbs`](https://github.com/panda850819/panda-verbs), repository ID unchanged at `1192890641`; the old URL redirects |
| Release recovery | [Issue #182](https://github.com/panda850819/panda-verbs/issues/182), [PR #183](https://github.com/panda850819/panda-verbs/pull/183), merge `db43282` |
| Annotated tag | `v4.0.0-rc.1`, tag object `dcf537e232de82b282021c962c6cbc5270ea71e5`, commit `a55a61bf37fa6f61c025f34fe1f62469fa5c1851` |
| Published prerelease | [`v4.0.0-rc.1 — Verbs`](https://github.com/panda850819/panda-verbs/releases/tag/v4.0.0-rc.1), published 2026-07-11 |
| Successful workflow | [Run 29134291215](https://github.com/panda850819/panda-verbs/actions/runs/29134291215): restore tag object, tag preflight, upload, draft-first publish |
| Archive digest | `sha256:4ff5f65564d69dc686d669978238a8a63d2eb75832bc10e4735c678ab7e770ee` |

The downloaded GitHub archive and checksum file matched the locally proven tag
artifacts byte for byte.

## Verification matrix

| Gate | Result |
|---|---|
| Source suite | `16 passed, 0 failed, 0 quarantined` |
| Candidate preflight | Clean commit, extracted archive suite 16/16, deterministic archive/checksum, synthetic cache scanner clearly labeled |
| Tag preflight | Annotated tag subject, tag ancestry, extracted archive suite, source registrations, and Claude/Codex cache-shaped parity passed |
| Exact-tag Claude installer smoke | Official marketplace install in a disposable profile; init event proved the exact installed path; `Skill` tool launched `verbs:careful`; cold result matched its activation contract |
| Exact-tag Codex installer smoke | Official marketplace install in a disposable profile; enabled receipt, strict parity, and `$verbs:careful` cold invocation passed |
| Cross-model review | All 145 file patches covered in four bounded payloads with no truncation; confirmed installer, compatibility, adapter, and test-mode defects fixed before merge |
| Real profiles | Claude and Codex each expose exactly one enabled `verbs@verbs 4.0.0-rc.1`; neither inventory contains `pandastack@pandastack` |

## Release failure and immutable-tag recovery

The first tag-push run, [29134103831](https://github.com/panda850819/panda-verbs/actions/runs/29134103831), failed before artifact upload. `actions/checkout` fetched the annotated tag, then overwrote the local `refs/tags/v4.0.0-rc.1` with `github.sha`, turning it into a lightweight ref. `release-preflight.sh --tag` rejected it as designed.

The public tag was never deleted or rewritten. PR #183 added an offline fixture
that reproduces `tag → commit → tag`, restores the exact remote tag object before
preflight, and permits a guarded manual dispatch of an existing immutable tag.
The recovery run then published the original RC tree.

## Real-machine migration

- v3 rollback is pinned at
  `/Users/panda/site/skills/pandastack-v3-rollback`, detached at
  `8d9a382b74d5b3e0ef0b6e91375fab3a172a916f`. Keep it through dogfood.
- Claude installs `verbs@verbs 4.0.0-rc.1` at
  `/Users/panda/.claude/plugins/cache/verbs/verbs/4.0.0-rc.1`.
- Codex installs the exact-tag local marketplace from
  `/Users/panda/site/skills/pandastack-worktrees/180-panda-verbs-v4`.
- Both old plugins and both old marketplace declarations were removed only
  after strict doctor and cold invocation passed.
- The primary checkout remains at `/Users/panda/site/skills/pandastack` to keep
  linked worktrees valid. It is clean at `db43282` and points to the renamed
  GitHub repository.
- Hermes' stale whole-pack `pandastack` symlink was removed. No whole-pack
  `verbs` symlink was created; Hermes remains selective manual import only.

The task that performed the migration started with the v3 plugin snapshot.
Current installation truth comes from fresh Claude/Codex processes; open a new
task or reload plugins before judging the interactive skill catalog.

## Seven-day dogfood gate

Stable is blocked until **2026-07-18** at the earliest. Before a stable tag:

1. Start fresh Claude and Codex tasks and verify only the `verbs` namespace is
   present; run strict doctor on both hosts again.
2. Exercise the core delivery path on real work: `grill --brief` → `sprint` →
   `review` → `ship`.
3. Exercise one cross-model `advisor` call and one Claude-orchestrated
   `handover`; confirm the Codex-seat handover guard remains a no-op.
4. Use `debug`, `qa`, `careful`, and `gatekeeper` only on genuine triggers and
   record any P0/P1 contract failure.
5. Confirm no lifecycle-state writes, automatic policy hooks, old namespace,
   or whole-pack Hermes import reappears.
6. Retain the v3 rollback worktree until the full window closes.

Any P0/P1 product or migration defect resets the stable gate. Cosmetic docs and
workflow-only fixes do not rewrite the published RC tag.

## Rollback

Use the pinned v3 worktree and the host-specific sequence in
`INSTALL_FOR_AGENTS.md`. Remove v4 only after the v3 marketplace and plugin have
installed successfully. Do not delete the public RC tag or release as a rollback
shortcut.
