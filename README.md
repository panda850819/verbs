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
| `/verbs:grill` | core | Atomic adversarial discovery, 5-10 min. Use `--brief` for a written brief + executable plan. |
| `/verbs:careful` | core | Confirmation gate before destructive commands (prod, rm -rf, force-push). |
| `/verbs:debug` | core | Root-cause debugging: hypothesis → instrument → bisect → scope-blast. NOT diff review. |
| `/verbs:ui` | core | Build/fix UI with a point of view. NOT browser-test (qa) or render-bug (debug). |
| `/verbs:review` | core | Risk-adaptive diff review with scoped evidence and cold-context escalation. |
| `/verbs:sprint` | core | Acceptance-driven execution with bounded review and delivery evidence. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills / MCPs / repos. |
| `/verbs:qa` | core | Browser-based UI QA when the host provides browser automation. |
| `/verbs:ship` | ext | Test + commit + push + PR for completed code work. Needs cli:gh. |
| `/verbs:handover` | ext | Hand unfinished work to Codex (sync or async). Needs cli:codex. |
| `/verbs:advisor` | ext | Cross-model second opinion. Needs cli:codex and cli:claude for opposite-seat routing. |

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

Full install, verification, and migration commands are in
[`INSTALL_FOR_AGENTS.md`](INSTALL_FOR_AGENTS.md).

## Manual chaining examples

Dev work: grill then sprint.
```
/verbs:grill --brief "<problem>"
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
3. Optionally tag `vX.Y.Z` and create a GitHub release with
   `gh release create` from the changelog heading. GitHub supplies the
   standard source archives; no custom release assets.

The version bump is what refreshes installed plugin caches; reinstall or
`/reload-plugins` after merging.


## License

[MIT License](LICENSE). See [Third-party notices](THIRD_PARTY_NOTICES.md) for
attributions and included or adapted license terms.

## Acknowledgements

Skill-writing conventions are adapted from
[mattpocock/skills](https://github.com/mattpocock/skills). See the notices for
exact attribution.
