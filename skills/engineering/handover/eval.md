---
type: skill-eval
skill: handover
bucket: engineering
evaluated_skill_hash: 33a953f1e0f912801d4c80a1cd53fa66f0beef62
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — handover

**Verdict: STRONG.** The hot Claude-only platform gate, seven-part preflight, pinned payload, and one-shot terminal classification now give sync and async handovers explicit ownership without invented cross-run state. Batch counter belongs only in sprint, not in handover's single result.

Grounding sample: L91 — "Stop when that one-shot table returns its"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L91 — every collected sync result flows through one referenced status table whose current actions are terminal and contain no undefined counter or persistent state. |
| Description / invocation | weak | L6 — the hot description carries sync mechanics, async mechanics, seat restrictions, use cases, and four exclusions; keep the two mode triggers and seat guard, then move transport detail to the body. |
| Completion criteria | pass | L92 — sync stops on an exhaustive one-shot `success`, `partial`, or `failed` result, while async separately ends after emitting its artifact and dispatch command. |
| Information hierarchy | pass | L77 — command shape, payload schema, sandbox escalation, and classification remain in the branch-specific invocation reference instead of being duplicated in the main flow. |
| Leading words | pass | L57 — "session occupancy" cleanly anchors the sync-versus-async distinction without conflating it with cost, model, or git ownership. |
| Pruning | pass | L34 — the skill now keeps one consistent Routing Boundary; the unfinished-versus-finished distinction does not repeat after the preceding exclusion list already routes closing work to `ship`. |
| Native parity | pass | L35 — raw `codex exec` is named as the nearest native path, and the payload contract, preflight, pinned model, sandbox gate, and terminal classification are the concrete delta. |
| Granularity | pass | L57 — sync and async share plan resolution, model selection, and payload construction; one skill is justified because their only mode axis is whether this turn remains occupied. |
| Panda Verbs conformance | pass | L77 — required and advisory frontmatter match current behavior, both references resolve, the long body is earned by two modes plus seven safety gates, and the result classification is one-shot with no batch counter. |

## Why it's good

The workflow fails closed on platform, recursion, CLI, version, repo, plan, and model anchor before dispatch. Sync preserves a clean baseline and source-host git ownership through one terminal result. Async writes one self-contained handoff and never spawns Codex or touches git. Neither mode carries a batch counter; that belongs to sprint's loop semantics only.

## Top fixes

1. L92 — the result classification is one-shot: success, partial, or failed. No batch counter or retry logic lives here; per-batch attempts belong in sprint's delegation loop, not in the single handover invocation.
2. L34 — collapse the unfinished-versus-finished explanation into the Routing Boundary so it has one source of truth without duplication.

## Behavioral cases

- trigger `/handover checkout-cleanup` from Claude Code with at least three mechanical plan units → run all seven gates, require a clean baseline, derive unfinished units from acceptance checks, invoke pinned Codex, classify one terminal result, and let only the source host commit a completed batch.
- trigger `/handover --async checkout-cleanup` → write one self-contained file under `docs/handoffs/`, print the version-checking direct dispatch command, and stop without spawning Codex or touching git.
- trigger `/handover checkout-cleanup` from a Codex seat → no-op immediately to avoid recursive delegation.
- anti-trigger `close this finished branch and open the PR` → should NOT fire; route to `ship`.
- anti-trigger `decide whether we should rewrite this architecture` → should NOT fire; route judgment to `advisor`.
