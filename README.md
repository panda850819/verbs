# Verbs

An opinionated skill pack for taking software work from ambiguity to verified
delivery. It gives coding agents named operating procedures for the points
where software work usually goes wrong.

The Marketplace Plugin is the recommended Claude Code and Codex surface.
Portable, hook-free skill imports and selective Hermes import are also
supported.

## Why Verbs exists

Coding agents can write code without knowing when the goal is still ambiguous,
when evidence is too weak, or when “done” has stopped short of delivery. Verbs
turns those recurring failure modes into explicit routes:

| Failure mode | Verbs route |
|---|---|
| The request sounds clear but hides product choices | `grill` discovers requirements before implementation. |
| The topic is too large for one plan or session | `grill` charts the map; `wayfinder` resolves one frontier at a time. |
| The cause, design seam, or UI direction is unknown | `debug`, `codebase-design`, `prototype`, or `ui` answers the right kind of question. |
| A change could be unsafe or an external artifact is untrusted | `careful` and `gatekeeper` add the appropriate trust boundary. |
| Code exists but proof or delivery is missing | `sprint` drives verification, review, and delivery; `qa`, `review`, and `ship` own their specialist stages. |

Verbs does not replace model judgment. It gives that judgment a route,
acceptance conditions, and evidence requirements.

## How work flows

The normal development route is conditional, not a mandatory chain:

```text
request
  |
  v
grill -- clarify the outcome and acceptance conditions
  |
  +-- bounded plan, one execution context --> sprint
  |                                           |
  |                                           +--> verify --> review --> ship
  |
  +-- large or cross-session uncertainty --> decision map
                                              |
                                              +--> wayfinder resolves one frontier
                                                   until a bounded plan can sprint
```

Use `handover` only when a plan already contains a bounded, mechanical build
unit that benefits from fresh context. The worker returns evidence to the
orchestrator; it does not replace `sprint` ownership of the final acceptance
and delivery loop.

Other skills are typed on-ramps or supporting gates:

- A reproducible failure enters through `debug`.
- A production UI change enters through `ui`; browser acceptance enters
  through `qa`.
- An architecture seam enters through `codebase-design`; a single unresolved
  design question may justify a throwaway `prototype`.
- An external repo, package, MCP, skill, or document enters through
  `gatekeeper`.
- Production or destructive work adds `careful`.
- A load-bearing judgment may call `advisor` for a decorrelated model opinion.
- A multi-runtime harness that has already accumulated complexity enters
  through `harness-slim`.

[`RESOLVER.md`](RESOLVER.md) is the complete human-facing operating model.
[`DISPATCH.md`](DISPATCH.md) is the compact machine-routing table injected into
supported hosts.

## Enforcement boundaries

Skills describe how to work. Plugin hooks enforce only the small set of
boundaries where advice is too easy to skip:

| Hook | Where it runs | What it enforces | What it does not do |
|---|---|---|---|
| `SessionStart` | Startup, clear, and compact events | Injects `DISPATCH.md` so the host can route the next message. | It does not invoke a skill, schedule work, or choose a model. |
| `PreToolUse: Bash` destructive guard | Before Bash commands | Blocks positive matches for scoped destructive commands, with explicit escape hatches. | It is not a complete shell sandbox; documented parser residuals fail visibly or remain out of scope. |
| `PreToolUse: Bash` ticket gate | Before Git-changing Bash commands | Blocks commits on `main`/`master`, pushes to default branches, and broad pushes that bypass the issue-branch contract. | It does not create issues, branches, worktrees, or PRs. |
| `Stop` verify gate | When the agent tries to stop | Blocks the first stop after a code edit when no recognized verification ran, then allows a second stop to prevent a loop. | It does not prove the chosen test was sufficient or block prose-only work. |

The destructive and ticket guards are safety gateways: they prevent known
high-cost shortcuts before execution. The Stop gate is an evidence gateway: it
prevents a code-editing turn from silently ending without verification. Manual
skill imports are hook-free, so they provide procedures without these
enforcement guarantees.

## Product boundary

Verbs ships **skills, shared procedural primitives, dispatch, narrow host
adapters, install manifests, evals, and tests**. It does not own identity,
context, brain or memory, project truth, runtimes, scheduling, autonomous
drivers, connectors, or global model routing.

## Skills

**Core** = markdown-first with only baseline `git` where declared. **Ext** =
needs an additional public CLI. Full spec in `manifest.toml`.

<!-- BEGIN GENERATED: skill-catalog -->
| Skill | Tier | Purpose |
|---|---|---|
| `/verbs:careful` | core | Confirmation gate before destructive commands. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills / MCPs / repos. |
| `/verbs:grill` | core | Adversarial requirement discovery that drills then writes a structured brief by default. |
| `/verbs:review` | core | Risk-adaptive diff review with a bounded low-risk fast path, scoped evidence, and cold-context escalation. |
| `/verbs:debug` | core | Systematic root-cause debugging: hypothesis gate, instrument-first by bug class, bisect, scope-blast, known bug classes. NOT diff review (review) or UI taste (ui). |
| `/verbs:sprint` | core | Acceptance-driven execution with bounded review and delivery evidence. |
| `/verbs:ui` | core | Build/fix UI with a committed point of view. Four override reflexes + craft lore in references (reflex-font blocklist, CJK+Latin type, OKLCH, CSS bans+rewrites, strategic omissions). NOT browser-test (qa) or render-bug debugging (debug). |
| `/verbs:qa` | core | Browser-based UI QA with PR-ready acceptance evidence through a host-provided browser automation capability. |
| `/verbs:codebase-design` | core | Deep-module design vocabulary: small interface at a clean seam, depth-as-leverage, deletion test, testable through the interface. Reference core reached by design asks or by other skills needing the terms. |
| `/verbs:prototype` | core | Throwaway prototype answering ONE design question: logic → terminal state driver; UI → N structurally different variants behind ?variant=. Verdict outlives the code. NOT production UI (ui). |
| `/verbs:wayfinder` | core | Chart or work cross-session decision maps: with a large, fuzzy topic, use grill to create the map and stop; with an existing map, take ONE unblocked entry, resolve it by type, write the decision back, and graduate the fog. |
| `/verbs:ship` | ext | Close completed code work through test, commit, push, PR, and QA evidence publication. Needs `gh`, hence ext. |
| `/verbs:handover` | ext | Hand unfinished mechanical work from a Claude or Codex orchestrator to one fresh Claude or Codex worker through a bounded synchronous contract; Codex-only --async remains available. |
| `/verbs:advisor` | ext | Pull a decorrelated second opinion from a DIFFERENT model into the current session (executor-calls-advisor). Zero-config self-locate seat: Claude seat reaches out to codex/GPT, Codex seat to `claude -p`. Default = one cross-model consult on a load-bearing judgment; --panel = blind cross-model critics on a prepared plan. Verified minimums: Codex CLI 0.144.1, Claude Code 2.1.206. |
| `/verbs:harness-slim` | ext | Audit a live multi-runtime agent harness after adoption: installed parity, cold context, routing overlap, telemetry semantics, and human-attention load. Proposes reversible reductions; does not mutate the harness. |
<!-- END GENERATED: skill-catalog -->

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
changelog. The work queue is limited to failures found through daily use,
Claude/Codex parity checks, and reinstall drills.

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
