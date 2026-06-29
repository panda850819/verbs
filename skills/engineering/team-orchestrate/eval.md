---
type: skill-eval
skill: team-orchestrate
bucket: engineering
evaluated_skill_hash: d186352bb965a57118236f74cde89967d91cee18
evaluated_at: 2026-06-29
rubric: writing-great-skills@1.0.0
---

# Eval — team-orchestrate

**Verdict: SOLID.** Tightly determinate phase machine with a hard independence gate and checkable per-branch criteria; loses points on a body running ~2x the soft budget and an Origin/intake tail that re-states the decision-tree SSOT.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | Fixed Phase 0→1→2→3 spine; the abort path is deterministic and Phase 1 builds each branch prompt from its brief + hard rules, so the same process runs every time. |
| Description / invocation | pass | L4 — front-loads "Conductor-driven parallel execution"; one trigger per branch (parallel / fan out / N independent); explicit skip→sprint clause; no body-identity restated in the description. |
| Completion criteria | pass | L118 — every Phase-2 step is checkable (worktree exists + has commits, files match declared scope, self-report vs actual worktree state), and the independence audit (L63) is a hard PASS/ABORT, not "reviewed the structure". |
| Information hierarchy | pass | Gate schema deferred behind `lib/gate-contract.md`, Inbox skeleton behind `lib/inbox-template.md`; the dispatch steps stay hot, reference loads cold via pointers. |
| Leading words | pass | L34 — "conductor", "gate per branch as it returns", "fan out" are pretrained anchors carrying the execution model; "wall-clock parallel" (L39) collapses the latency rationale into two words. |
| Pruning | weak | L181 — Origin block (L181-185) is changelog/provenance sediment that belongs in git history, and the intake locus table (L29-32) re-states `lib/skill-decision-tree.md`'s own locus table (its L7-14), a second source for one meaning. |
| Granularity | pass | Each phase split earns its load: intake / dispatch / gate / synthesis are distinct user-visible stages each with its own completion criterion, none collapsible without losing a gate. |
| pandastack conformance | weak | L25 — frontmatter valid (name=folder) and all `lib/` refs resolve, but the body is ~145 lines (185 incl. frontmatter) against the ~80 soft budget, and `lib/capability-probe.md` is declared in `reads:` (L6) yet never consulted in the body — dangling audit metadata. |

## Why it's good

The skill earns its parallelism with a non-negotiable independence audit (L63) that aborts to sequential sprints rather than risk silent merge corruption, so the dangerous default is structurally foreclosed, not merely warned against. The gate-as-they-return loop (L114-140) binds the shared four-option contract from `lib/gate-contract.md` via `AskUserQuestion` and forces verification against actual worktree state (L121), so subagent self-report drift cannot leak into a merge.

## Top fixes

1. L181-185 — delete the Origin block; provenance is git's job, not the hot skill body. Cuts ~5 lines of pure sediment.
2. L29-32 — drop the duplicated locus table and point to `lib/skill-decision-tree.md` for the sprint-vs-team-orchestrate distinction; keep only the one-line conductor framing at L34.
3. L6 — either wire `lib/capability-probe.md` into a real pre-dispatch capability check or remove it from `reads:`; a declared-but-unread pointer is dangling metadata. With (1) and (2) this also pulls the body back toward the ~80-line budget.

## Behavioral cases

- trigger `run these 4 audit branches in parallel, they don't share files` -> expected process: Phase 0 intake + independence audit PASS, Phase 1 single-message N-Agent worktree dispatch (brief + hard rules per branch), Phase 2 gate-as-they-return via AskUserQuestion, Phase 3 synthesis + Inbox artifact, suggest /review, no auto-chain.
- anti-trigger `refactor this module then update its callers` -> should NOT fire (inter-branch dependency; routes to N sequential sprints / `/sprint` per L45, L177).
