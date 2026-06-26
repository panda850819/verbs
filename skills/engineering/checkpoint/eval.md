---
type: skill-eval
skill: checkpoint
bucket: engineering
evaluated_skill_hash: 9c7f8273ccde701552576e70cc9746b0957931f4
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — checkpoint

**Verdict: SOLID.** A tightly-scoped save/resume verb whose templated artifact and embedded "reference, don't duplicate" rule give it a genuinely predictable process across runs.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L23-29 — fixed gather-state command block makes every Save run the same process regardless of project |
| Description / invocation | weak | L4 — "Save or resume" front-loads only 2 of 3 branches; the `list` branch (L18, L108) is invisible to invocation |
| Completion criteria | weak | L106 — "Delete the checkpoint file after successful resume" has no checkable definition of "successful"; deletion is irreversible |
| Information hierarchy | pass | L69-73 — the reference rule ("Reference, don't duplicate") is co-located inside the Save step it governs, not floated to a distant section |
| Leading words | weak | L21 — "Detect Command" is a generic procedural header doing no pretrained-concept anchoring; the verb dispatch carries no leading word |
| Pruning | weak | L70-73 — the "A checkpoint that restates a plan drifts" elaboration restates the imperative one line above it; near-no-op prose |
| Granularity | pass | L21-118 — Save/Resume/List kept as three sequenced steps in one skill, correctly NOT split (no independent leading word, sequence is short) |
| pandastack conformance | pass | L1-7 — frontmatter has both required fields (`name` matches folder, `description`); per SKILL-FRONTMATTER.md §Required/§Optional `version`/`type` are optional (`type` defaults to `skill`) and their absence lints as pass, matching 4 other meta skills (init, retro-month, retro-week, using-pandastack) |

## Why it's good
The skill's strength is determinism through templates: the gather-state shell block (L23-29) and the verbatim checkpoint-file template (L33-67) leave almost nothing to model improvisation, so two agents checkpointing the same branch produce structurally identical artifacts. The "Reference, don't duplicate" rule (L69-73) and the secret-redaction guard (L75-76) are co-located inside the Save step they constrain, which is correct information hierarchy. Scope is honest and narrow — it is a save/resume verb and resists growing into a session manager.

## Top fixes
1. L4 — description omits the `list` branch and the focus-arg variant; add a trigger so model-invocation can reach all three branches, not just save/resume.
2. L106 — define "successful resume" before the destructive delete (e.g. "after the RESUMING block prints"); an unmet-but-assumed success deletes the only state record. Consider archiving over deleting.
3. L94 — Resume step 2 ("check all checkpoints and list them") duplicates the List step (L108-118); fold it into a call to List rather than re-describing the listing inline. Minor, not a split-worthy granularity break.

## Behavioral cases
- trigger `/checkpoint "ship the auth refactor"` → expected process: run the L23-29 gather block, write the L33-67 template to `docs/checkpoints/{branch}-{date}.md` with Remaining/Suggested-Skills/Resume-Hint tilted toward the focus arg, append project-state if a project page exists, print the L84 confirmation.
- anti-trigger `save this fact about Bob to the brain` → should NOT fire (routes to `ingest` / brain-ops; "save" here means a brain page, not a git working-state snapshot).
