---
type: skill-eval
skill: advisor
bucket: engineering
evaluated_skill_hash: 8b07a04457472b640ad04ab211ab95866c75f3ec
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — advisor

**Verdict: STRONG.** Seat-filtered role selection, pinned transports, fail-loud decorrelation, and exact four-option decision gates now make both consult modes deterministic without granting the outside model execution authority.

Grounding sample: L99 — "use the exact per-finding gate from"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L52 — panel roles are selected from an explicit seat-specific pair before probing, so every run has a fixed opposite-family composition instead of a generic provider mix. |
| Description / invocation | weak | L7 — the hot description repeats load-bearing examples, provider-selection rationale, three trigger synonyms, and four anti-routes in one line; keep the two branches and anti-routes, but move selection rationale to the body. |
| Completion criteria | pass | L81 — the default branch ends only when an outside voice is returned unincorporated and decision ownership remains with the caller; the panel has its own explicit terminal list. |
| Information hierarchy | pass | L57 — volatile role, model, effort, minimum-version, and guard values remain in the shared anchor file while the skill owns selection and failure behavior. |
| Leading words | pass | L61 — "self-issued second opinion" compresses the core false-decorrelation failure into a memorable execution guard. |
| Pruning | pass | L51 — the default and panel branches are cleanly separated with a completion criterion for each, and the hot description now correctly states the exact two-role seat-filtered composition. |
| Native parity | pass | L61 — same-model self-review is named as the nearest default behavior, and the skill's delta is a pinned different-family transport that refuses silent fallback. |
| Granularity | pass | L86 — the panel stays inside the consult skill because it shares transport and caller-owned decisions, while the expensive-if-wrong threshold prevents a routine second workflow. |
| Verbs conformance | pass | L100 — the current gate reference resolves to lib/gate-contract.md with its exact `approve / edit / reject / skip` options; all seat-filtered role keys also exist in the current anchor table. |

## Why it's good

The default branch locates the seat, pins the opposite-family role, probes the transport, and returns a read-only outside view. The panel preserves family separation for both seats, keeps critics blind, retains lone findings, and leaves every application decision with the caller through the shared four-option gate contract.

## Top fixes

1. L100 — the gate now uses the exact `approve / edit / reject / skip` contract from lib/gate-contract.md, making all finding decisions explicit and reversible.
2. L52 — seat-filtered role composition guarantees that Claude seats consult OpenAI and Codex seats consult Anthropic, eliminating guesswork and self-review.

## Behavioral cases

- trigger `get a second opinion on this irreversible schema fork` → detect the seat, select the pinned opposite-family default role, probe its CLI, return one outside voice, and leave incorporation to the caller.
- trigger `--panel on this prepared migration plan` from a Claude seat → run the two OpenAI roles with distinct lenses; from a Codex seat, run the two Anthropic roles; gate every deduplicated finding with `approve / edit / reject / skip`.
- anti-trigger `review this branch before the PR` → should NOT fire; route to `review`.
- anti-trigger `finish these mechanical plan units` → should NOT fire; route execution-out work to `handover`.
- degrade case `the opposite transport binary is missing` → print the documented failure banner, keep judgment local, and do not substitute the current model or an unpinned default.
