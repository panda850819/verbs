# Panda Verbs

An opinionated skill pack for taking software work from ambiguity to verified delivery. Hard-won ways of working, encoded as composable skills for coding agents.

Verified on Claude Code and Codex. Hermes supports selective manual import.

## Product boundary

Panda Verbs ships **skills, shared procedural primitives, dispatch, narrow host adapters, install manifests, evals, and tests**. It does not own: identity, context, brain or memory, project truth, runtimes or models, scheduling, autonomous drivers, connectors, or global routing.

## Skills

**Core** = markdown-first with only baseline `git` where declared. **Ext** =
needs an additional public CLI. Full spec in `manifest.toml`.

| Skill | Tier | Purpose |
|---|---|---|
| `/verbs:grill` | core | Atomic adversarial discovery, 5-10 min. Use `--brief` for a written brief + executable plan. |
| `/verbs:careful` | core | Confirmation gate before destructive commands (prod, rm -rf, force-push). |
| `/verbs:debug` | core | Root-cause debugging: hypothesis → instrument → bisect → scope-blast. NOT diff review. |
| `/verbs:ui` | core | Build/fix UI with a point of view. NOT browser-test (qa) or render-bug (debug). |
| `/verbs:review` | core | 3-pass review + cross-model adversarial check. |
| `/verbs:sprint` | core | 1-2h focused execution: scope → grill-lite → execute → review → ship. |
| `/verbs:write` | core | Voice-aware drafting + slop detection. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills / MCPs / repos. |
| `/verbs:skill-creator` | core | Create new Panda Verbs skills. `--eval` scores existing skills. |
| `/verbs:writing-great-skills` | core | Reference + scorecard for well-constructed skills. |
| `/verbs:qa` | core | Browser-based UI QA when the host provides browser automation. |
| `/verbs:ship` | ext | Test + commit + push + PR for completed code work. Needs cli:gh. |
| `/verbs:handover` | ext | Hand unfinished work to Codex (sync or async). Needs cli:codex. |
| `/verbs:advisor` | ext | Cross-model second opinion. Needs cli:codex and cli:claude for opposite-seat routing. |

## Install

```bash
git clone https://github.com/panda850819/panda-verbs.git
cd panda-verbs
bash scripts/bootstrap.sh             # report only
bash scripts/bootstrap.sh --claude    # print Claude Code install steps
bash scripts/bootstrap.sh --codex     # print Codex CLI install steps
```

### Per-host

| Host | Install after clone |
|---|---|
| Claude Code | `claude plugin marketplace add /absolute/path/to/panda-verbs --scope user` then `claude plugin install verbs@verbs --scope user` |
| Codex CLI | `codex plugin marketplace add /absolute/path/to/panda-verbs --json` then `codex plugin add verbs@verbs --json` |
| Hermes | Import/symlink selected skills into `~/.hermes/skills/` (see `docs/HERMES.md`) |

**Work dirs** (`Inbox/`, `docs/briefs/`, etc.) are auto-created on first write; you don't pre-make them.

Full install, verification, and v3 migration commands are in
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
| Claude Code | Verified plugin marketplace install |
| Codex CLI | Verified plugin marketplace install |
| Hermes | Selective manual skill import |

## v3 to v4 migration

v4 keeps the 14-skill catalog and makes the product boundary explicit. The
plugin id, namespace, CLI, and repository name change. Before migrating, pin
v3.4.2 commit `8d9a382b74d5b3e0ef0b6e91375fab3a172a916f` in a detached rollback
worktree as documented in the install guide. Never enable both plugins at once.

```bash
claude plugin validate "/absolute/path/to/panda-verbs"
claude plugin marketplace add "/absolute/path/to/panda-verbs" --scope user
claude plugin uninstall pandastack@pandastack --scope user --keep-data
claude plugin install verbs@verbs --scope user
# After /reload-plugins and strict verification pass:
claude plugin marketplace remove pandastack --scope user
```

If v4 fails before verification, repoint the old marketplace to that immutable
rollback checkout and reinstall `pandastack@pandastack`. Then migrate Codex
with the commands in the install guide.
`/pandastack:*` has no alias. Use `/verbs:*` or an unqualified skill name when
the host displays one.

## Development and verification

Check a checkout:
```bash
bash scripts/bootstrap.sh
python3 scripts/verbs sync --check
claude plugin validate .
bash tests/run-all.sh
```

Score a skill against the construction quality SSOT:
```bash
/verbs:skill-creator --eval <skill-name>
```

## Release

Maintainer workflow:

1. Update `manifest.toml`, `CHANGELOG.md`, and skill content on an issue branch.
2. Run `scripts/verbs sync`, `bash tests/run-all.sh`, and
   `bash scripts/release-preflight.sh --candidate vX.Y.Z` from a clean commit.
3. Merge the green PR to `main`.
4. Create an annotated tag whose subject equals the changelog heading.
5. Run `bash scripts/release-preflight.sh --tag vX.Y.Z`, then run
   `bash scripts/installer-smoke.sh claude "$PWD" vX.Y.Z` and the same command
   for `codex`.
6. Push only the tag after both real installer smokes pass.

The release workflow publishes archives and checksums; release stays draft until
all artifacts upload. If automation fails after tag push, repair the workflow on
`main` and manually dispatch that same immutable tag. Never rewrite the tag.


## License

[MIT License](LICENSE). See [Third-party notices](THIRD_PARTY_NOTICES.md) for
attributions and included or adapted license terms.

## Acknowledgements

Release and skill-writing conventions are adapted from
[mattpocock/skills](https://github.com/mattpocock/skills); Chinese writing
references include [tw93/Waza](https://github.com/tw93/Waza). See the notices
for exact attribution.
