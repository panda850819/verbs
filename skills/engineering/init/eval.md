---
type: skill-eval
skill: init
bucket: engineering
evaluated_skill_hash: cd7b017fdd5a34e39fc7b489c2bf3c4c016fe081
evaluated_at: 2026-07-03
rubric: writing-great-skills@1.1.0
---

# Eval — init

**Verdict: SOLID.** A tight single-branch bootstrap whose former soft back end is now a real verification gate (Step 5 greps the config block and stats the dirs, refusing to claim success otherwise); the only point left on the table is a description that still recaps body steps in HOT context.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L10 — `# Init` heads five named, ordered steps (`Step 1: Detect` … `Step 5: Verify`); one branch, no forks, identical process every run. |
| Description / invocation | weak | L6 — model-invocation is correct and the triggers are now quoted (`/init`, "initialize pandastack", "set up this project", L4-5), but L6-7 then restates body identity ("Detects project type, confirms detected values, writes pandastack config") — three step-recap verbs sitting in always-loaded context that the rubric flags as cuttable. |
| Completion criteria | pass | L62 — Step 5 verifies before asserting: `grep -q '^## pandastack'` on the target file (L63) and existence of the four `docs/learnings/*` + `docs/checkpoints` dirs (L64), with a hard "report what is missing and stop — do not claim initialized" (L66). Step 1 also carries a checkable done-state (L20) and a test-not-found miss path. The prior premature-completion FAIL is cured. |
| Information hierarchy | pass | L42 — config block inlined exactly where Step 3 writes it; flat, all-inline, no external pointer, correct for a ~66-line single-branch skill. Co-location held. |
| Leading words | pass | L60 — `Step 5: Verify` is a distinct pretrained anchor matching its job; the prior `Confirm`/`Confirm` collision with Step 2 (L22) is resolved, so each step name now anchors one purpose. |
| Pruning | pass | L66 — Step 5 now does load-bearing work (grep + dir checks gate the success string), so the former no-op print is gone; single source of truth, no sediment, every step earns its lines. |
| Native parity | weak | L38 — nearest native feature is manually choosing `CLAUDE.md`/`AGENTS.md` and writing config by hand; the delta is runtime-aware setup plus verification, but the skill does not name the manual baseline directly. |
| Granularity | pass | L60 — Step 5 earns its split as a by-sequence, anti-premature-completion cut: it withholds the "initialized" claim until the writes are observed, the exact split the rubric sanctions (writing-great-skills L50-51). Steps 1-4 are clean independent cuts. |
| pandastack conformance | pass | L2 — `name: init` equals the folder; 66 lines < ~80; no `lib/` refs to resolve; no >5K-token read, so hot/cold dispatch is not triggered; `version`/`type` are spec-optional. |

## Why it's good
The skill does one thing — a once-per-project bootstrap — with a deterministic Detect → Confirm → Write → mkdir → Verify spine that survives across runtimes (L37 handles the CLAUDE.md-vs-AGENTS.md split explicitly). The repair landed where it mattered: the old print-only finish is now a verification gate (L62-66) that observes the grep hit and the dir tree before reporting success, closing the premature-completion hole. The Step 2 AskUserQuestion gate (L22-34) still forces a human checkpoint between auto-detect and the irreversible append.

## Top fixes
1. **L6-7 — trim the body-recap from the description.** "Detects project type, confirms detected values, writes pandastack config to CLAUDE.md … or AGENTS.md" restates the step list that already lives in the body, paying context load every session for identity the index does not need. Keep the leading line + the three quoted triggers; drop the verb-recap (the runtime/file split already lives in Step 3, L37).
2. **L20 — pin Step 1's "not found" path to one observable token.** It already carries the value forward as "not found"; state the check explicitly (e.g. test command = a resolved string or the literal `not found`) so Step 5 has nothing ambiguous to verify against.

## Behavioral cases
- trigger `set up this project` -> expected process: Step 1 auto-detect (lang/test/branch/CI), present detected values via AskUserQuestion (Step 2), append the `## pandastack` block to CLAUDE.md or AGENTS.md (Step 3), mkdir the learnings/checkpoints tree (Step 4), then Step 5 grep + dir-stat verify before printing "initialized".
- anti-trigger `update the pandastack config` -> should NOT fire (init is once-per-project bootstrap, L4); reconfiguring an already-initialized repo is not this skill's job.
- anti-trigger `re-run review to refresh my learnings` -> should NOT fire; routes to `/review`, which is where Step 5's own closing line (L66) points the user post-init.
