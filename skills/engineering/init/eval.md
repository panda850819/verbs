---
type: skill-eval
skill: init
bucket: engineering
evaluated_skill_hash: 52974238711ec5757f487d5f64f5dbf8a12bfbbb
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — init

**Verdict: SOLID.** A short, single-branch bootstrap skill with a clean ordered Detect → Confirm → Write → mkdir spine that any runtime can execute the same way every run; the weak seam is the back end, where "Confirm" is overloaded and the final step prints success without verifying the write landed.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L11 — five named, ordered steps (`Step 1: Detect` …) give the same process each run; one branch, no forks to drift on. |
| Description / invocation | weak | L4 — front-loads "Use once per project to initialize pandastack" well, but the description is pure prose with no explicit trigger phrases (no `/init`, no "set up pandastack" quoted branch), so model-invocation rests on paraphrase match alone. |
| Completion criteria | fail | L59 — the skill ends by *printing* "pandastack initialized…", with no check that Step 3 appended the config block or Step 4's dirs exist; the closing step asserts done instead of verifying it — textbook premature-completion bait. |
| Information hierarchy | pass | L37 — config block inlined where Step 3 writes it; flat, all-inline, no external pointer, which is correct for a ~37-line single-branch skill (no progressive disclosure to earn). |
| Leading words | weak | L57 — "Step 5: Confirm" reuses the same bare imperative as L19 "Step 2: Confirm"; neither is a pretrained anchor, and the collision means two differently-purposed steps share one weak word. |
| Pruning | weak | L57 — Step 5 "Confirm" is a no-op step: it neither confirms nor verifies, it emits a fixed string, duplicating the "Confirm" label from L19 and barely earning its own step number. |
| Granularity | pass | L50 — Step 4 (mkdir) is a clean checkable cut; the five steps map to five distinct actions, none split gratuitously (Step 5 is the only borderline cut, flagged under pruning). |
| pandastack conformance | weak | L1 — frontmatter carries only `name` + `description`; spec-valid (both `version` and `type` are optional), but every well-formed meta sibling (skill-creator, gatekeeper) stamps `version`/`type`, so this reads as under-declared rather than wrong. |

## Why it's good
The skill is tight (59 lines, well under the ~80-line budget) and does exactly one thing: a once-per-project bootstrap with a deterministic Detect → Confirm → Write → mkdir order that survives across Claude Code and Codex runtimes (L35 handles the CLAUDE.md-vs-AGENTS.md split explicitly). The config block and AskUserQuestion mock are inlined at the point of use, so there is no progressive-disclosure overhead to mismanage. Predictability and information hierarchy are genuinely strong for a skill this small.

## Top fixes
1. **L59 — replace the print-only finish with a real completion criterion.** Make Step 5 verify: assert the `## pandastack` block exists in the target config file and the four `docs/learnings/*` + `docs/checkpoints` dirs were created, then print success. As written, a failed Step 3/4 still reports "initialized".
2. **L57 — rename or fold Step 5.** Two steps named "Confirm" (L19, L57) for different jobs is a leading-word collision; the final one is a no-op label. Either rename to "Verify" (and give it teeth per fix 1) or fold the success string into Step 4.
3. **L4 — add explicit trigger branches to the description.** Quote the invocation phrases (`/init`, "initialize pandastack", "set up this project") so model-invocation anchors on triggers, not paraphrase; optionally stamp `version`/`type` to match sibling conformance (L1).

## Behavioral cases
- trigger `set up pandastack in this repo` → expected process: run Step 1 auto-detect (lang/test/branch/CI), present detected values via AskUserQuestion (Step 2), append the config block to CLAUDE.md or AGENTS.md (Step 3), mkdir the learnings/checkpoints tree (Step 4), confirm.
- anti-trigger `re-run review to refresh my learnings` → should NOT fire (init is once-per-project bootstrap, L4); routes to `/review`, which is what Step 5's own closing line (L59) points the user at post-init.
