---
type: skill-eval
skill: team-orchestrate
bucket: engineering
evaluated_skill_hash: 0cac3789d5158badfc1cbe40afbdca2838a1ecce
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — team-orchestrate

**Verdict: SOLID.** A deterministic conductor process whose mandatory independence audit hard-aborts on file overlap, forcing the same safe parallel-dispatch run every time; loses points on duplicated rules and a declared-but-unused probe ref.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L61 — the independence audit is `(mandatory)`; "If any two branches touch the same file, ABORT and route to N sequential sprints" makes the unsafe path non-optional, pinning the process. |
| Description / invocation | pass | L4 — front-loads the leading concept ("Conductor-driven parallel execution"), lists triggers, and carries an explicit skip clause routing sequential/single-track work to `sprint`. |
| Completion criteria | pass | L98 — "Subagent's self-reported result matches actual state (read worktree files, don't trust the report)" is a checkable done/not-done, not "reviewed". |
| Information hierarchy | pass | L100 — gate mechanics are deferred behind a `lib/gate-contract.md` context pointer; SKILL.md keeps only the four-outcome summary hot. |
| Leading words | pass | L32 — the "conductor" metaphor anchors execution behavior: "It dispatches, reviews returns, merges. It does NOT edit during dispatch." |
| Pruning | weak | L86 — re-states L67's "subagent does not read your `CLAUDE.md` / `AGENTS.md`, so inline…" clause; the independence rule also recurs at L36/L43/L61/L89/L141/L147, and the body runs 162 lines vs the ~<80 discipline. |
| Granularity | pass | L30 — clean by-invocation split from `/sprint`; the execution-locus table row draws the conductor-vs-in-session boundary that justifies a separate skill. |
| pandastack conformance | weak | L6 — `lib/capability-probe.md` is declared in `reads:` yet never invoked anywhere in the L23-162 body (dangling metadata), and the body is 162 lines vs ~80. (The #110 de-personalization at L67/L87 is itself a conformance win.) |

## Why it's good
The skill turns a high-blast-radius operation (N parallel writers) into a deterministic pipeline: a mandatory pre-dispatch independence audit (L61) that aborts to sequential sprints rather than risk silent merge corruption, single-message fan-out (L65), a gate-as-they-return loop that verifies against actual worktree state instead of self-report (L98), and a synthesis artifact (L133). The #110 de-personalization (L67, L87) swaps author-specific "Panda's voice / no Co-Authored-By" for portable "read your `CLAUDE.md` / `AGENTS.md`" wording, raising distribution-fitness without weakening the inline-the-rules instruction.

## Top fixes
1. L86 — collapse the duplicated "subagent does not read your CLAUDE.md / AGENTS.md" clause; it already appears at L67. State it once, at the Phase 1 hard-rules block.
2. L6 — either wire `lib/capability-probe.md` into a visible pre-dispatch probe step (every Layer-1 flow opens with it) or drop it from `reads:`; a declared-but-unmentioned pointer is dangling audit metadata.
3. L141/L146/L147 — three anti-patterns all re-encode "don't let branches share files"; fold into one, since L61 already enforces it. With (1) and (3) the body moves back toward the ~80-line budget.

## Behavioral cases
- trigger `fan out these 4 independent audit passes in parallel` → expected process: Phase 0 intake + independence audit (PASS), Phase 1 single-message N-Agent worktree dispatch, Phase 2 gate-as-they-return per `lib/gate-contract.md`, Phase 3 synthesis + `Inbox/team-orchestrate-*.md`, suggest `/review`, no auto-chain.
- anti-trigger `refactor this module then update its callers` → should NOT fire (inter-branch dependency; routes to N sequential `/sprint` per L43/L143).
