---
type: skill-eval
skill: debug
bucket: engineering
evaluated_skill_hash: f5bacfad15498087c793a6cb31251b22d511b124
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — debug

**Verdict: SOLID.** The skill is a compact reflex override for debugging: root cause, red-capable proof, run-and-look, sibling sweep.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L17 — `## Override` holds the invariant gates that must happen before edit, diagnosis-done, fixed, and done. |
| Description / invocation | pass | L4 — front-loads "Systematic root-cause debugging" and enumerates error, crash, regression, flaky, and NOT-routing branches. |
| Completion criteria | pass | L22 — diagnosis now ends on an already-run red-capable command with seen output, which is a checkable done gate. |
| Information hierarchy | pass | L30 — deep bug-class lore stays behind `diagnosis.md`, keeping the hot skill body focused on overrides. |
| Leading words | pass | L22 — "red-capable command" is a compact operational label for a command that can prove the hypothesis wrong. |
| Pruning | pass | L14 — "This skill is not the method" prevents a generic debugging checklist and keeps only non-default behavior. |
| Native parity | pass | L14 — names the native competitor ("You already know how to debug") and the delta: reflex overrides under momentum. |
| Granularity | pass | L8 — anti-triggers route diff review and UI taste complaints to other skills, so debug stays right-sized. |
| pandastack conformance | pass | L32 — cold references live under `lib/`, frontmatter is valid, and the body stays below the ~80-line target. |

## Why it's good
The skill now has a stronger diagnosis completion gate without turning into a debugging method dump. The red-capable command criterion makes the end of diagnosis observable, while the existing lore pointer keeps bug-class tactics cold.

## Top fixes
1. L27 — tighten the sibling sweep into "name the signature grepped and hit count" so the final scan is as checkable as the red-capable command gate.
2. L37 — normalize `lib/learning-format.md` to the same `../../../lib/` reference style used by `learning-recall.md`.

## Behavioral cases
- trigger `以前是好的，現在這個 build 跑不通` → expected process: recall matching learnings if the cause is not obvious; name the root cause at `file:function:line`; prove diagnosis with a red-capable command already run; run-and-look before fixed; grep siblings.
- anti-trigger `review my diff before I open the PR` → should NOT fire (routes to `review`).
- anti-trigger `this button spacing looks off` → should NOT fire (routes to `ui`).
