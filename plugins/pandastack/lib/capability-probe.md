# lib/capability-probe.md — Substrate availability check + graceful degradation

> Shared module. Loaded by Layer 1 flow skills (`sprint`, `office-hours`, `boardroom`, `dojo`, `prep`) at startup. Detects missing substrate (vault, AGENTS.md, lib/ files, declared CLIs) and either degrades to generic mode or aborts with a missing-deps list. Never silently fails.
>
> Origin: pandastack v1.0 is public, but slim skills assume the user has Obsidian + AGENTS.md + a few CLIs set up. Fresh-clone users hit silent degradation. Codex Q6 (2026-05-04 review) flagged this. capability-probe makes the substrate dependency explicit + load-bearing.

## When to load

At the START of every Layer 1 flow skill — before any vault read, before any CLI call. Atomic check that runs in <500ms.

Specifically:

- `sprint` Stage 0 (dojo loaded inside)
- `office-hours` Stage 1 (load context)
- `boardroom` Stage 0 (load plan + persona-frame)
- `dojo` / `prep` opening
- `gatekeeper` opening (if integrating vault past-case lookup)
- Any retro / brief / curate-feeds run

Skip for atomic skills that have no substrate dependency (`init`, `done`, `freeze`, `careful`, `checkpoint`).

## Probe checks (6 items)

Run all 6 checks. Each returns `ok / missing / broken / unknown`.

```
[1] AGENTS substrate    — `~/.agents/AGENTS.md` exists, readable, non-empty
[2] vault root          — cwd looks like a vault (has Inbox/ or .obsidian/)
[3] lib/ files          — required lib/ refs for THIS skill exist (read frontmatter `reads:` to determine list)
[4] persona skills      — if skill chains personas, check `skills/{persona}/SKILL.md` exists in plugin
[5] cli tools           — domain-specific CLIs (gog, slack, bird, notion, defuddle) only if frontmatter `reads: cli: <name>`
[6] write paths         — directories the skill will write to exist + are writable (Inbox/ / docs/ / Blog/ etc.)
```

Each check has a 500ms timeout. Probe total ≤3s.

## Output protocol

```
== capability-probe (skill: {name}) ==
[1] AGENTS substrate    : ok
[2] vault root          : ok
[3] lib/ files          : missing (lib/push-once.md not found)
[4] persona skills      : ok
[5] cli tools           : ok
[6] write paths         : ok

→ degraded: [3]
→ blocked:  [] (none — degrade rather than block)
```

## Action by probe result

| Result | Action |
|---|---|
| All 6 ok | Proceed normally |
| 1-2 degraded, 0 blocked | Proceed in degraded mode (see below) |
| ≥3 degraded OR ≥1 blocked | Abort, print missing list, suggest fix command, exit |

### Degraded mode rules

For each degraded check:

- **lib/ file missing** → load the inline fallback embedded in the skill body (each skill MUST have a 3-line summary of each lib it uses, for fallback) OR proceed with `[lib/X.md missing — using inline fallback]` warning
- **persona skill missing** → if persona file isn't there, prompt user "persona X not installed, proceed without?" with N as default
- **cli tool missing** → skip that integration, proceed without; log `[skipped: cli:X not available]`
- **vault path missing** → ABORT (this is structural, can't degrade)
- **AGENTS.md missing** → ABORT (substrate is gone, behavior would drift wildly)

### Fresh-clone dev-mode note

If you are a fresh-clone user and this probe shows degraded items 2 / 5 (vault root / cli tools), this is **expected**, not broken. pandastack assumes you bring your own Obsidian vault and the CLIs declared by the skill you're invoking. See `ROADMAP.md` at repo root and the `Stability scope` section in `README.md`.

The skill will degrade gracefully where possible per the rules above. If degradation hits ≥4 items or the vault path itself is missing, the skill aborts cleanly. That is the contract, not a regression.

### Abort messages

When aborting, print:

```
== capability-probe ABORT ==
skill {name} requires substrate that is missing:

  [{check-id}] {check-name}: {why missing}

To fix:
  - {fix command 1}
  - {fix command 2}

If you don't intend to fix and want to use a generic version, install gstack
or another fully-bundled skill stack instead. pandastack assumes the substrate
declared in `pandastack/README.md` § "Install".
```

Exit cleanly. Do not partially run.

## Why probe ≠ trust

Probe checks **availability**, not **correctness**. A CLI `--version` returning 0 is "ok" (the binary loads); whether it produces correct output for your query is a runtime concern.

Skills should NOT trust probe results indefinitely. Re-probe at start of every Layer 1 flow run; the substrate state is time-varying (a CLI got removed, vault path changed, etc.).

## Skills' obligation

Every Layer 1 flow skill MUST declare in frontmatter:

```yaml
capability_required:
  - agents.md
  - vault
  - lib/push-once.md
  - lib/escape-hatch.md
  - lib/persona-frame.md  # if persona-routed
  - cli:gog               # for skills that depend on a specific CLI
```

`capability-probe` reads this list and runs the matching subset of checks. Items not declared = not probed = potential silent failure (and a lint flag against the skill).

## Anti-patterns

- ❌ Probe runs only on first invocation per session, then cached forever — substrate state changes, re-probe each run
- ❌ Probe failure ignored ("oh well, CLI broken, just continue silently") — defeats the whole point
- ❌ Probe expanded to validate substrate CONTENT ("does AGENTS.md have section Voice?") — that's a separate lint, keep probe to availability
- ❌ Skill tries a CLI directly without probe ("if it fails I'll catch it") — probe is the single point of truth for substrate, do NOT scatter checks
- ❌ Probe degrade message buried in skill output — must print as opening block so user sees substrate state immediately

## Origin

- codex Q6 (2026-05-04 review of pandastack v1.1 redesign) — public repo dogfood mismatch, slim skills silently fail on fresh clone
- pandastack 2026-05-04 — `lib/capability-probe.md` created to make substrate dependency explicit + load-bearing
- v2.1.0 (2026-05-07): probe simplified — gbq / pdctx checks removed. Vault path comes from cwd, persona skills resolve via plugin paths.
