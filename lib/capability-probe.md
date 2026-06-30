# lib/capability-probe.md — Substrate availability check + graceful degradation

> Shared module. Loaded by Layer-1 flow skills (`sprint`, `office-hours`, `dojo`, `team-orchestrate`) at startup. Detects what's present — identity contract, a writable work dir, declared `lib/` refs, declared CLIs — then **scaffolds or degrades**. It aborts only when there is no identity contract at all or the cwd cannot be written. Never silently fails.
>
> Design goal: a fresh `/plugin install` user working in their own repo (no `~/.agents/AGENTS.md`, no Obsidian vault, no ext CLIs) reaches a working first session. Missing personal substrate degrades to built-in defaults; missing write dirs are created; only a missing contract or an unwritable cwd blocks — and then with an actionable one-liner.

## When to load

At the START of every Layer-1 flow skill, before any vault read or CLI call. Atomic, <1s.

- `sprint` Stage 0 · `office-hours` Stage 1 · `dojo` opening · `team-orchestrate` opening · any retro / brief run.
- Skip for atomic skills with no substrate dependency (`init`, `freeze`, `careful`, `checkpoint`).

## Checks

Run only the checks the skill declares in `capability_required:`. Each → `ok / degraded / scaffolded / blocked`.

```
[1] identity contract  — a contract exists at ANY of: ~/.agents/AGENTS.md, ./CLAUDE.md, ./AGENTS.md
[2] write location      — cwd is a writable directory (the repo/vault the skill writes into)
[3] declared lib/ refs  — the lib/ files in `reads:` exist
[4] declared CLIs       — each `cli:<name>` the skill needs (its manifest `requires`) is on PATH
[5] write paths         — the parent dir of each `writes:` target exists (created if not)
```

## How to run the probe (concrete)

1. Read THIS skill's frontmatter (`capability_required:`, `reads:`, `writes:`) and its `[skill.<name>]` row in `manifest.toml` (`tier`, `requires`).
2. Evaluate each declared check:
   - **[1] identity contract** → `[ -f ~/.agents/AGENTS.md ] || [ -f ./CLAUDE.md ] || [ -f ./AGENTS.md ]`. Present → `ok`. None → `blocked` (the skill leans on a contract for voice/rules; there is nothing to fall back to). Abort with the actionable message below.
   - **[2] write location** → `[ -d . ] && [ -w . ]`. Yes → `ok`. No → `blocked` (cwd is read-only / not a dir).
   - **[3] lib/ refs** → for each `reads: repo: lib/X.md`, check it resolves. Missing → `degraded` (use the inline fallback the skill carries).
   - **[4] CLIs** → for each CLI the skill's manifest `requires`, `command -v <name>`. Missing → `degraded`, and print the install hint from the manifest tier (below).
   - **[5] write paths** → for each `writes:` target, `mkdir -p "$(dirname <target>)"`. Created any → `scaffolded` (not an error — work dirs are cheap and expected).
3. Print the probe block. Proceed unless a check is `blocked`.

## Manifest tier-awareness (install hints)

When a declared CLI is missing, map the skill's `[skill.<name>]` `requires` token to an actionable hint:

```
cli:<name>   → "<name> not found — install it, then retry"
npm:<pkg>    → "npm install -g <pkg>"
brew:<x>     → "brew install <x>"
pipx:<pkg>   → "pipx install <pkg>"
```

`tier=core` skills run markdown-only — a missing CLI degrades a feature, never blocks. `tier=ext` skills need their CLI for the core job; surface the hint prominently, but still show the probe rather than dying silently.

## Output protocol

```
== capability-probe (skill: {name}, tier: {core|ext}) ==
[1] identity contract : ok
[2] write location    : ok
[3] lib/ refs         : ok
[4] CLIs              : degraded (agent-browser not found → npm install -g agent-browser)
[5] write paths       : scaffolded (created docs/briefs/, docs/plans/)

→ proceeding (degraded: [4], scaffolded: [5], blocked: none)
```

## Action by result

| State | Action |
|---|---|
| all `ok` / `scaffolded` | Proceed normally |
| any `degraded` | Proceed; each degraded item uses its fallback (defaults / inline lib / skip-the-integration) and is named in the block |
| any `blocked` | Abort, print the actionable reason, stop |

There is no "≥N degraded → abort" threshold: degraded features fall back, they do not block. The only two abort paths are `[1] no contract` and `[2] unwritable cwd`.

### Abort messages

```
== capability-probe ABORT ==
{name} needs {what is blocked}:

  [1] identity contract: no ~/.agents/AGENTS.md, ./CLAUDE.md, or ./AGENTS.md found.
      Fix: run `/init` to create a project CLAUDE.md, or add one with your voice/rules.

  [2] write location: cwd is not writable.
      Fix: cd into the repo or vault you want this skill to write into.
```

Exit cleanly. Do not partially run.

## Fresh-install note

A fresh `/plugin install` user typically shows `[4] degraded` (ext CLIs not installed) and `[5] scaffolded` (work dirs created on first write). That is the expected baseline, not a failure — core skills run markdown-only; ext skills surface their one install command. The two hard stops are a missing contract (run `/init`) and an unwritable cwd. See `README.md` § Install for the tier model.

## Why probe ≠ trust

Probe checks **availability**, not **correctness**. A CLI `--version` returning 0 is "ok" (the binary loads); whether it produces correct output for your query is a runtime concern.

Re-probe at the start of every Layer-1 flow run; substrate state is time-varying (a CLI got removed, the cwd changed). Do NOT cache probe results across runs.

## Skills' obligation

Every Layer-1 flow skill declares in frontmatter the checks it needs:

```yaml
capability_required:
  - agents.md            # → check [1] identity contract
  - vault                # → check [2] write location
  - lib/push-once.md     # → check [3] declared lib/ ref
  - cli:<name>           # → check [4], only for a skill that needs a specific CLI
```

`capability-probe` runs only the matching checks. A dependency the skill uses but does not declare = not probed = potential silent failure (and a lint flag against the skill). CLI deps come from the skill's `[skill.<name>] requires` in `manifest.toml`; declare the same set here so the probe and the manifest agree.

## Anti-patterns

- ❌ Aborting a stranger for lacking the author's `~/.agents/AGENTS.md` — a project `./CLAUDE.md` is a valid contract; only no-contract-at-all blocks.
- ❌ Aborting because a work dir (`docs/briefs/`, `Inbox/`) doesn't exist — scaffold it; `mkdir -p` is cheap.
- ❌ Probe failure ignored ("CLI broken, continue silently") — defeats the point; name it in the block and fall back explicitly.
- ❌ Probe expanded to validate substrate CONTENT ("does the contract have a Voice section?") — that is a separate lint; keep the probe to availability.
- ❌ Skill tries a CLI directly without the probe — the probe is the single point of truth for substrate; do not scatter checks.
- ❌ Probe block buried in skill output — print it as the opening block so the user sees substrate state immediately.

## Origin

- codex Q6 (2026-05-04 review) — public-repo dogfood mismatch: slim skills silently failed on a fresh clone. `lib/capability-probe.md` made the substrate dependency explicit + load-bearing.
- v2.1.0 (2026-05-07): probe simplified — gbq / pdctx checks removed; vault path comes from cwd.
- 2026-06-30 (#110, distribution readiness): fresh-user rework. Identity contract accepts `./CLAUDE.md` / `./AGENTS.md`, not just `~/.agents/AGENTS.md`; work dirs are scaffolded instead of aborting; CLI gaps degrade with a manifest-derived install hint; abort narrowed to no-contract / unwritable-cwd, each with an actionable fix line. De-personalized (no named author CLIs, no "install gstack instead").
