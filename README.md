# Verbs

An opinionated skill pack for taking software work from ambiguity to verified delivery. Hard-won ways of working, encoded as composable skills for coding agents.

The Marketplace Plugin is the recommended Claude Code and Codex surface.
Portable hook-free skills and selective Hermes import are also supported.

## Product boundary

Verbs ships **skills, shared procedural primitives, dispatch, narrow host adapters, install manifests, evals, and tests**. It does not own identity, context, brain or memory, project truth, runtimes, scheduling, autonomous drivers, connectors, or global model routing.

## Skills

**Core** = markdown-first with only baseline `git` where declared. **Ext** =
needs an additional public CLI. Full spec in `manifest.toml`.

| Skill | Tier | Purpose |
|---|---|---|
| `/verbs:grill` | core | Adversarial discovery, one question at a time. Drills then writes a brief + executable plan by default; say "quick" for a chat-only log. |
| `/verbs:careful` | core | Confirmation gate before destructive commands (prod, rm -rf, force-push). |
| `/verbs:debug` | core | Root-cause debugging: hypothesis → instrument → bisect → scope-blast. NOT diff review. |
| `/verbs:ui` | core | Build/fix UI with a point of view. NOT browser-test (qa) or render-bug (debug). |
| `/verbs:review` | core | Risk-adaptive diff review with scoped evidence and cold-context escalation. |
| `/verbs:sprint` | core | Acceptance-driven execution with bounded review and delivery evidence. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills / MCPs / repos. |
| `/verbs:qa` | core | Browser-based UI QA with acceptance evidence ready for a PR. |
| `/verbs:ship` | ext | Test + commit + push + PR, including QA evidence comments when present. Needs cli:gh. |
| `/verbs:handover` | ext | Hand bounded unfinished work from Claude or Codex to one fresh Claude or Codex worker. Needs both CLIs for the full four-route matrix. |
| `/verbs:advisor` | ext | Cross-model second opinion. Needs cli:codex and cli:claude for opposite-seat routing. |
| `/verbs:harness-slim` | ext | Post-adoption multi-runtime harness evaluation. Needs cli:git, cli:codex, and cli:claude. |

## Install

### Recommended: Marketplace Plugin

Claude Code:

```bash
claude plugin marketplace add panda850819/verbs --scope user
claude plugin install verbs@verbs --scope user
```

Codex:

```bash
codex plugin marketplace add panda850819/verbs --json
codex plugin add verbs@verbs --json
```

The Marketplace Plugin registers three lifecycle adapters: SessionStart
dispatch, Bash PreToolUse destructive + ticket-gate guards, and the Stop
verification gate. High-signal guard decisions append to
`$XDG_STATE_HOME/verbs/guard-events.jsonl` when set, otherwise
`~/.local/state/verbs/guard-events.jsonl`. Override the path with
`VERBS_GUARD_EVENT_LOG`, disable it with `off`, or set
`VERBS_GUARD_EVENT_LEVEL=all` to include routine allow decisions.

### Inspect or develop locally

```bash
git clone https://github.com/panda850819/verbs.git
cd verbs
bash scripts/bootstrap.sh             # report only
bash scripts/bootstrap.sh --claude    # print Claude Code install steps
bash scripts/bootstrap.sh --codex     # print Codex CLI install steps
```

**Work dirs** (`Inbox/`, `docs/briefs/`, etc.) are auto-created on first write; you don't pre-make them.

### Verify an install

```bash
claude plugin list --json
python3 scripts/verbs doctor --host claude --strict
codex plugin list --json
python3 scripts/verbs doctor --host codex --strict --live-hooks
bash scripts/conformance-smoke.sh claude   # or codex
```

`doctor --strict` compares plugin version, skill set, `DISPATCH.md`, and the
registered hook tree against this checkout. For a local-checkout install, use
`claude plugin marketplace add "$PWD" --scope user` or
`codex plugin marketplace add "$PWD" --json` with the same install commands
above. `python3 scripts/verbs init --host <claude|codex|hermes> --dry-run`
prints the local install commands without changing the host.

## Manual chaining examples

Dev work: grill then sprint.
```
/verbs:grill "<problem>"
/verbs:sprint
```

Code review: review then ship.
```
/verbs:review
/verbs:ship
```

Artifacts flow between skills; you decide when to invoke each step.

## Host support

| Host | Status |
|---|---|
| Claude Code | Marketplace Plugin |
| Codex CLI | Marketplace Plugin |
| Hermes | Selective manual skill import |

## Version reset

`v0.5.0` started the Verbs version line. Older `v1.*` tags belong to
pandastack; `v4.0.0-rc.1` belongs to the short-lived product name used during
the boundary cut. Those tags and releases stay immutable history, and their
migration paths live in git history. `/pandastack:*` has no alias.

## Development and verification

Check a checkout:
```bash
bash scripts/bootstrap.sh
python3 scripts/verbs sync --check
claude plugin validate .
bash tests/run-all.sh
```

Skill-writing lore for maintainers lives in
`maintainer/writing-great-skills.md`. It is not exposed in normal runtime
sessions.

## Release

1. Update `manifest.toml` (version bump), `CHANGELOG.md`, and skill content on
   an issue branch.
2. Run `python3 scripts/verbs sync` and `bash tests/run-all.sh` from a clean
   commit, then merge the green PR to `main`.
3. Optionally tag `vX.Y.Z` and push the tag;
   `.github/workflows/release.yml` publishes a GitHub release with generated
   notes. GitHub supplies the standard source archives; no custom assets.

The version bump is what refreshes installed plugin caches; reinstall or
`/reload-plugins` after merging.


## Roadmap

Verbs is pre-1.0 and personal-first: a public, installable skill pack whose
primary user is its author. 0.x releases may break contracts when real usage
exposes a bad boundary; breaking changes ship with migration notes in the
changelog. The work queue is limited to failures found through daily use of
the 11 active skills, Claude/Codex parity checks, and reinstall drills.

Cut `v1.0.0` only when: the product identifiers and install contracts survive
two consecutive 0.x releases without a breaking rename; both hosts pass fresh
install, reinstall, cold-start invocation, and full hook registration on the
author's machines; one model-upgrade audit (capability / context / neither
recut) has run against the then-current frontier model without a load-bearing
regression; and no P0/P1 product-contract failure is open.

Out of scope: identity, personal context, brain or memory, project truth,
runtime/model selection, scheduling, autonomous drivers, connectors, global
routing, and fresh-user certification — see
[`.out-of-scope/`](.out-of-scope/) for rejected directions and their reopen
conditions.

## License

[MIT License](LICENSE). See [Third-party notices](THIRD_PARTY_NOTICES.md) for
attributions and included or adapted license terms.

## Acknowledgements

Skill-writing conventions are adapted from
[mattpocock/skills](https://github.com/mattpocock/skills). See the notices for
exact attribution.
