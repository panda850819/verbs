---
type: skill-eval
skill: advisor
bucket: engineering
evaluated_skill_hash: a1e0238cab55ca430be0ceaf69a1597f44f7736e
evaluated_at: 2026-07-10
rubric: writing-great-skills@1.1.0
---

# Eval — advisor

**Verdict: STRONG.** A 93-line, opinionated cross-model consult primitive whose load-bearing assets are a fail-loud guard and explicit, transport-tested model anchors. It probes every transport required by the selected mode, never inherits runtime model or permission defaults, and ends both default and panel paths on checkable handoff artifacts.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L38-47 — Step 0 seat-locate is a deterministic env check (`CLAUDECODE=1` → Claude seat, else Codex seat), Step 1 is a deterministic `command -v` gate; the direction is derived, never hardcoded, so every run takes the same shape regardless of which runtime invokes it. |
| Description / invocation | pass | L4 — front-loads the load-bearing-judgment trigger ("design fork", "a plan before you commit", "second opinion", "red-team this", "多角度審") and reciprocates boundaries: NOT code-diff review (`review`), NOT sending build work out (`handover`), NOT self-interview (`grill`). |
| Completion criteria | pass | L77 — the default path is done only when the outside view is returned as outside-voice and remains unincorporated; the panel path separately stops after the gated list (L93). |
| Information hierarchy | pass | L26 — the Routing Boundary and four numbered steps stay hot; volatile model, effort, version, and guard choices live in `lib/model-anchors.md` (L65-67), while per-finding mechanics remain behind `lib/gate-contract.md` (L91). |
| Leading words | pass | L47 — strong coined anchors carry the behaviour: "fail loud, never silently self-review", "judgment stays local, NOT self-reviewed", "A self-issued second opinion is not a second opinion", "Cross-model is the point" (L64), and "Keep every lone-critic finding" (L68). |
| Pruning | pass | whole file — 93 lines, above the ~80 guideline; the extra lines earn their load by checking the complete mode-specific role set plus fail-loud version and permission guards while volatile values stay in one shared reference. |
| Native parity | pass | L47 — names the native competitor directly: the model answering the judgment itself, or spawning a same-model critic. The delta is cross-MODEL decorrelation, and the skill refuses the native fallback loudly ("do not fake decorrelation by asking the same model") instead of silently degrading to it. |
| Granularity | pass | L51/L60 — the default single-consult vs `--panel` blind-critique split earns its load: one is a narrow read for a fork, the other a decorrelated panel for an expensive-if-wrong plan; the panel is explicitly frequency-gated, not a gratuitous mode. |
| pandastack conformance | pass | frontmatter — `name` = folder (`advisor`), required fields present (`name`/`description`/`user-invocable: false`); the `lib/gate-contract.md` pointer resolves repo-root (same as `review`); advisory `reads`/`writes`/`forbids`/`domain` declared; paired with `handover` as inbound/outbound halves without overlapping its exec role. |

## Why it's good
The asset is the anti-fake-decorrelation guard. The failure mode a cross-model consult must never hit is "the binary wasn't reachable so I quietly asked the same model and called it a second opinion" — that produces false confidence, the worst outcome. The skill hard-stops on that (L48), and an anchored-call failure cannot retry through an unpinned default (L50-52). Zero-config seat detection (L41) means the same skill works from either runtime without a mode flag, while `lib/model-anchors.md` keeps transport-tested model choices out of the skill body. `--panel` retains mutual blindness, lone findings, and per-finding gates while adding cross-model decorrelation.

## Top fixes
1. L4-7 — the model-facing description remains dense; a future pruning pass could shorten examples without weakening the trigger boundary.
2. L48-57 — minimum-version parsing is described as a process rather than a shared shell helper; extract one only if multiple real hosts mis-parse versions.
3. L86-88 — panel composition now has explicit role keys; keep it at three roles unless observed usage proves another critic earns the cost.

## Behavioral cases
- trigger `I'm about to commit to this schema design — am I sure?` -> expected process: recognise a load-bearing, expensive-if-wrong fork -> Step 0 locate seat (`CLAUDECODE=1` → Claude) -> Step 1 `command -v codex` -> Step 2 load `advisor.openai`, invoke a narrow pinned `codex exec` call with the fork + minimal context -> return the outside view as outside-voice, caller decides; never auto-incorporate.
- trigger `red-team this replatform plan before I start` -> expected process: expensive-if-wrong plan -> Step 3 `--panel` with `advisor.panel.fast` + `advisor.openai` + optional `advisor.panel.deep`, distinct lenses, keep every lone finding, per-finding gate; stop after the gated list.
- anti-trigger `review my branch before the PR` -> should NOT fire (routes to `review`, code-diff review; advisor is judgment consult, not diff review).
- anti-trigger `finish building these three files` -> should NOT fire (routes to `handover`, which sends mechanical build work OUT to Codex; advisor pulls judgment IN, never executes).
- degrade case `Codex seat, claude not on PATH` -> Step 1 prints `ADVISOR: no cross-model binary on PATH (claude) — judgment stays local, NOT self-reviewed` and stops; does not ask GPT to critique its own output.
