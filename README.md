# Verbs

An opinionated skill pack for taking software work from ambiguity to verified
delivery. It gives coding agents named operating procedures for the points
where software work usually goes wrong.

The Marketplace Plugin is the recommended skills-only Claude Code and Codex
surface. Pi can load the same skill tree directly; selective Hermes import is
also supported.

## Why Verbs exists

Coding agents can write code without knowing when the goal is still ambiguous,
when evidence is too weak, or when “done” has stopped short of delivery. Verbs
turns those recurring failure modes into explicit routes:

| Failure mode | Verbs route |
|---|---|
| The request lacks a clear owner, reference, or next route | `ask-boss` orients the work and selects one existing specialist. |
| The request sounds clear but hides product choices | `grill` discovers requirements before implementation. |
| The topic is too large for one plan or session | `grill` charts the map; `wayfinder` resolves one frontier at a time. |
| The cause, architecture target, design seam, or UI direction is unknown | `debug`, `improve-codebase-architecture`, `codebase-design`, `prototype`, or `ui` answers the right kind of question. |
| A change could be unsafe or an external artifact is untrusted | `careful` and `gatekeeper` add the appropriate trust boundary. |
| Code exists but proof or delivery is missing | `sprint` drives verification, review, and delivery; `qa`, `review`, and `ship` own their specialist stages. |

Verbs does not replace model judgment. It gives that judgment a route,
acceptance conditions, and evidence requirements.

## How work flows

The primary product-engineering record uses six familiar stages:

```text
Product Planning
→ Backlog Refinement
→ Sprint Planning
→ Sprint
→ Sprint Review
→ Retro
```

| Stage | Question | Record |
|---|---|---|
| `product-planning` | Why does this matter, and what outcome comes first? | Product Goal, priority, candidate backlog outcomes |
| `backlog-refinement` | Is one backlog item clear and ready? | `READY` / `NOT_READY`, scope, acceptance, dependencies |
| `sprint-planning` | What will this Sprint deliver? | Human-approved Sprint Goal and selected ready work |
| `sprint` | How will one selected finish line be completed? | Acceptance, review, and delivery evidence |
| `sprint-review` | Did the delivered product achieve the Goal? | `ACCEPTED`, `NEEDS_CHANGES`, or `UNPROVEN` |
| `retro` | What should change in the next Sprint? | Keep, Change, and at most one evidenced Action |

The stages are not an automatic pipeline. Each stage stops after its record; a
human chooses when to invoke the explicit planning, execution, review, and Retro
entry points. No stage claims the next Issue, schedules work, or starts its
successor.

Clear typed work bypasses the stage layer. A reproducible failure enters through
`debug`; a production UI change through `ui`; code-diff review through `review`;
browser acceptance through `qa`; and completed Git delivery through `ship`.
`codebase-design`, `prototype`, `handover`, and the trust or safety skills keep
their established specialist contracts.

The supporting planning routes also remain available. `ask-boss` resolves an
unclear owner, source, target, or route. `grill` supplies dependency-aware
requirements discovery for Backlog Refinement. `wayfinder` owns multi-session
Decision Maps. Spec-sized work still follows `to-spec --> canonical GitHub Spec
Issue --> to-tickets --> child Issue graph`; decomposition reports a frontier
but never selects it.

Work is spec-sized when it is expected to require at least two implementation
Issues, or when even one PR changes a public contract, schema or migration, or
security boundary. A human selects one ready implementation Issue, and one
Sprint owns that finish line through one independently reviewable and
revertible PR.

[`RESOLVER.md`](RESOLVER.md) is the complete human-facing operating model.
Each `SKILL.md` description is the machine-routing surface.

## Invocation boundaries

Verbs relies on each host's native skill discovery and invocation controls. It
registers no lifecycle hooks, injects no routing context, and intercepts no tool
or stop events.

`product-planning` and `backlog-refinement` remain available to both people and
models. `sprint-planning`, `sprint`, `sprint-review`, and `retro` require an
explicit human invocation, as do other authority-bearing entry points documented
in the resolver. Human-only skills declare `disable-model-invocation: true` for
Claude Code and Pi plus matching `allow_implicit_invocation: false` Codex policy.
Skill prose owns safety and verification discipline; Verbs does not claim
host-level enforcement.

## Product boundary

Verbs ships **skills, shared procedural primitives, install manifests, evals,
and tests**. It does not own identity,
context, brain or memory, project truth, runtimes, scheduling, autonomous
drivers, connectors, or global model routing.

## Skills

**Core** = markdown-first with only baseline `git` where declared. **Ext** =
needs an additional public CLI. Full spec in `manifest.toml`.

<!-- BEGIN GENERATED: skill-catalog -->
| Skill | Tier | Purpose |
|---|---|---|
| `/verbs:careful` | core | Confirmation gate for production, shared infrastructure, live harness paths, and destructive commands. |
| `/verbs:gatekeeper` | core | Pre-adoption trust check for external skills / MCPs / repos. |
| `/verbs:ask-boss` | core | Route unclear workplace requests to one existing specialist by retrieving facts and resolving intent, target, audience, and minimum sufficient authority. Use for an unclear starting point, owner, reference, or next route; clear typed requests, named maps, bugs, UI work, and code review go directly to their specialist. |
| `/verbs:product-planning` | core | Clarify the product problem, Product Goal, priority, and candidate backlog outcomes before readiness or implementation work. |
| `/verbs:backlog-refinement` | core | Make one backlog item READY or NOT_READY by clarifying outcome, scope, acceptance criteria, dependencies, and unresolved decisions. |
| `/verbs:sprint-planning` | core | Plan one Sprint Goal and select ready work after a human approval gate. |
| `/verbs:sprint-review` | core | Review one Sprint outcome against its Goal and product acceptance evidence. |
| `/verbs:retro` | core | Review one completed Sprint and choose one evidence-backed process improvement. |
| `/verbs:grill` | core | Adversarial requirement discovery for unclear scope or a 3+ file feature/refactor; routes large foggy work to Wayfinder, spec-sized work to one canonical GitHub Spec Issue, and smaller work to a local brief and plan. |
| `/verbs:setup-verbs` | core | Configure or repair the existing per-repository Verbs issue-tracker setting with Git-derived identity, an idempotent preview, and one approval gate. |
| `/verbs:review` | core | Risk-adaptive diff review on request, before commit, or before PR, with a bounded low-risk fast path and cold-context escalation. |
| `/verbs:debug` | core | Systematic root-cause debugging: hypothesis gate, instrument-first by bug class, bisect, scope-blast, known bug classes. NOT diff review (review) or UI taste (ui). |
| `/verbs:sprint` | core | Acceptance-driven execution with bounded review and delivery evidence. |
| `/verbs:ui` | core | Build/fix UI with a committed point of view. Four override reflexes + craft lore in references (reflex-font blocklist, CJK+Latin type, OKLCH, CSS bans+rewrites, strategic omissions). NOT browser-test (qa) or render-bug debugging (debug). |
| `/verbs:qa` | core | Browser-based UI QA with PR-ready acceptance evidence through a host-provided browser automation capability. |
| `/verbs:codebase-design` | core | Deep-module design vocabulary: small interface at a clean seam, depth-as-leverage, deletion test, testable through the interface. Reference core reached by design asks or by other skills needing the terms. |
| `/verbs:improve-codebase-architecture` | core | Produce a read-only visual survey of codebase architecture opportunities. |
| `/verbs:prototype` | core | Throwaway prototype answering ONE design question: logic → terminal state driver; UI → N structurally different variants behind ?variant=. Verdict outlives the code. NOT production UI (ui). |
| `/verbs:wayfinder` | core | Chart or work cross-session decision maps when the request itself names a map or ask-boss identifies multi-session decision fog: with no map yet, run the interview and write it here, then stop; with an existing map, take ONE unblocked entry, resolve it by type, write the decision back, and graduate the fog. A request without a named map that only needs one-session requirement discovery goes to grill. |
| `/verbs:to-tickets` | ext | Decompose one canonical GitHub Spec Issue into an approved vertical-slice child Issue graph with native relations, body fallbacks, and verified frontier reporting. |
| `/verbs:to-spec` | ext | Synthesize established requirements and repository evidence into one canonical GitHub Spec Issue after confirming the highest practical test seams. |
| `/verbs:ship` | ext | Close completed code work through test, commit, push, PR, and QA evidence publication. Needs `gh`, hence ext. |
| `/verbs:handover` | ext | Hand one unfinished mechanical unit to an explicit fresh worker while the source agent keeps ownership. Detect a managed Herdr pane before choosing sibling-agent transport; otherwise use Claude/Codex fresh-run or an async payload. |
| `/verbs:advisor` | ext | Pull a decorrelated second opinion from a DIFFERENT model into the current session (executor-calls-advisor). Zero-config self-locate seat: Claude seat reaches out to codex/GPT, Codex seat to `claude -p`. Default = one cross-model consult on a load-bearing judgment; --panel = blind cross-model critics on a prepared plan. Verified minimums: Codex CLI 0.144.1, Claude Code 2.1.206. |
| `/verbs:harness-slim` | ext | Audit a live multi-runtime agent harness after adoption: installed parity, cold context, routing overlap, available usage evidence, and human-attention load. Proposes reversible reductions; does not mutate the harness. |
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

Inside a repository, invoke `verbs:setup-verbs` once to configure the issue
tracker in its existing `## verbs` block. Repository identity stays derived
from the Git remote.

The Marketplace Plugins distribute the same skill directories and register no
lifecycle hooks.

Pi loads the checkout directly through `~/.pi/agent/settings.json`:

```json
{
  "skills": ["/absolute/path/to/verbs/skills"]
}
```

This adds no Pi extension, package, hook, or copied skill tree.

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
python3 scripts/verbs doctor --host codex --strict
bash scripts/conformance-smoke.sh claude   # or codex
```

`doctor --strict` compares plugin version and skill set against this checkout.
For a local-checkout install, use
`claude plugin marketplace add "$PWD" --scope user` or
`codex plugin marketplace add "$PWD" --json` with the same install commands
above. `python3 scripts/verbs init --host <claude|codex|hermes> --dry-run`
prints the local install commands without changing the host.

## Host support

| Host | Status |
|---|---|
| Claude Code | Skills-only Marketplace Plugin |
| Codex CLI | Skills-only Marketplace Plugin |
| Pi | Direct Agent Skills loading |
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
Claude/Codex/Pi parity checks, and reinstall drills.

`v0.21.0` is the install-contract reset: it removed runtime hooks and made
skills the complete product surface. The stability count starts after that
reset and requires two consecutive **tagged GitHub releases** whose product ID,
plugin selector, manifest schema, and documented install commands remain
compatible. Patch releases within one minor line do not restart the count.

Each supported host passes through its declared install mode: fresh plugin
install plus reinstall for Claude Code and Codex, direct-load setup plus reload
for Pi, and import plus re-import of a reviewed selected skill for Hermes. Every
lane also needs a cold-start invocation on the author's machine. The gate claims
both installability and a current behavioral invocation; installation evidence
alone never becomes an invocation PASS.

`ACCEPTED LIMITATION` is a host-specific release qualification, not a PASS. It
requires passing evidence for every accessible part of the lane, prior passing
behavioral evidence for the unavailable part, an explicit maintainer decision,
and no known product defect or open `release-blocker` hidden by the exception.
It does not block v1 while those conditions hold. The qualification expires as
soon as access resumes or the affected host mode, invocation semantics, or
load-bearing contract materially changes. A newly observed regression always
gets a product Issue and cannot be qualified away. `OPEN` still means the gate
blocks v1; `WAIVED` is not used because it would hide which claim lacks current
evidence.

| v1 gate | Observable pass condition | Current evidence (2026-08-08) | Status |
|---|---|---|---|
| Install-contract stability | Two consecutive tagged post-reset 0.x release lines satisfy the compatibility rule above. | `v0.22.0` and the released `v0.23.x` line preserve the product ID, selector, schema, and documented install commands. | PASS |
| Supported-host install | Every declared host mode completes its fresh/reinstall-or-reload/cold-start drill on the version being cut, unless one inaccessible host-specific invocation qualifies under the `ACCEPTED LIMITATION` policy above. | Issue #334 records current Claude/Codex install parity, Pi direct-load, and isolated Hermes import evidence. Claude cold invocation is unavailable because the maintainer no longer has subscription or API access; prior Claude behavior is recorded, and #334 closed by explicit maintainer exception, not a new invocation PASS. The limitation expires when Claude access resumes or its affected contract changes; any observed regression gets a new product Issue. | ACCEPTED LIMITATION |
| Current-model fitness | A recorded audit names exact host, model, effort, and skill commit, and has no load-bearing regression after the latest host-semantics or load-bearing skill change. | [The current 19-skill audit](evals/2026-08-08-current-model-fitness.md) records passing #340 Sprint-boundary, #341 Grill-frontier, and #345 writable-Wayfinder reruns. Remaining primary outcomes stay explicitly UNPROVEN rather than inferred from routing. | PASS |
| Product-contract failures | The query for [open `release-blocker` Issues](https://github.com/panda850819/verbs/issues?q=is%3Aissue+is%3Aopen+label%3Arelease-blocker) returns zero. | Read the live query; individual Issue numbers are not copied here. | LIVE QUERY |

The table above is the living v1 gate. GitHub Issues are the executable work
queue; older decision maps remain evidence and must not be used as a second
roadmap.

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
