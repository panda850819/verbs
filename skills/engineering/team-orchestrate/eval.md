---
type: skill-eval
skill: team-orchestrate
bucket: engineering
evaluated_skill_hash: 6b943a6ca8445198f31825ae3f8b14b641ec9f98
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — team-orchestrate

**Verdict: SOLID.** The "conductor" leading word anchors a hard isolation invariant (dispatch, never edit), and a non-optional independence audit gates the dangerous N-writer operation before any subagent fires — the right virtue for a skill whose failure mode is silent merge corruption.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L51 — `## Protocol` runs the same fixed phases 0 → 0.5 → 1 → 2 → 3 every run, and the per-branch gate loop (verify → approve/edit/reject/skip) is identical across branches; the process is invariant even though outputs differ |
| Description / invocation | weak | L4 — "run these in parallel", "fan out", "N branches independent" are three near-synonym triggers for one branch (parallel-fanout); the spec says collapse synonyms that rename a single branch |
| Completion criteria | pass | L130 — the gate block forces "Scope match: PASS / FAIL" + "Verification: PASS / FAIL" before any merge, and L120 demands read-the-worktree proof over the self-report; checkable, not "looks done" |
| Information hierarchy | weak | L84 — steps 1-3 re-inline the `lib/persona-frame.md` "Inline-from-skill dispatch pattern" (the 6-section extraction) that the very same line already points at; should be a pointer, not a duplicated procedure |
| Leading words | weak | L96 — the model picker is soft free-text ("conductor picks per branch by task nature") that leans on default judgment rather than a crisp rule, and L137's "`git worktree add` merge" mislabels the merge verb; both blunt the otherwise sharp "conductor" anchor |
| Pruning | weak | L217 — the `## Origin` narration ("built early because the decision tree's parallel branch had no destination … two-strike doesn't apply") is changelog sediment that changes no runtime behaviour and helps push the body to 218 lines / ~110 prose, over the ~80 budget |
| Granularity | pass | L28 — the sprint-vs-team-orchestrate table splits by execution locus (main session executes vs N subagents at once), a genuine invocation boundary with a distinct leading word that earns its context load |
| pandastack conformance | weak | L17 — `capability_required` is an ad-hoc frontmatter key absent from SKILL-FRONTMATTER.md (allowed: "stacks may extend", but undocumented), and the `reads`/`writes`/`domain`/`classification` block (L5-16) is advisory-only metadata nothing enforces (firewall retired) — both are corpus-wide conventions (15 sibling skills carry the same block), so this is house-style drift, not a unique defect; `name` matches folder, all four `lib/` refs resolve, and the absent `version` field is in fact the engineering-bucket norm (none of init/sprint/ship/review/qa/handover carry one) so it is not a miss |

## Why it's good
The skill makes a genuinely dangerous operation (N parallel writers, silent merge corruption on file overlap) safe by front-loading a non-optional gate: the Phase 0 independence audit ABORTs before dispatch if any two branches share a file (L62), and "conductor does NOT edit during dispatch" (L33) protects worktree isolation. The verify-don't-trust gate ("read worktree files, don't trust the report", L120) is the correct defence against subagent self-report drift, and the When-to-use / When-to-skip pair (L36/L43) plus the contrast table (L28) make the route boundary against `/sprint` legible.

## Top fixes
1. L137 — `git worktree add` is the wrong verb in "On approve → `git worktree add` merge OR rebase branch into main"; `git worktree add` *creates* a worktree, it does not merge. Replace with the actual merge command (`git merge --no-ff <branch>` from main). This is a real execution bug, not a phrasing nit.
2. L84-87 — collapse the inlined steps 1-3 into the existing context pointer to `lib/persona-frame.md` § "Inline-from-skill dispatch pattern"; keep one source of truth, drop the duplicated 6-section procedure.
3. L216-218 — cut the `## Origin` section to a one-line changelog stub or move it to a CHANGELOG / commit trail; it is sediment the running agent never needs and a main driver of the over-budget body.

## Behavioral cases
- trigger `/team-orchestrate on these 4 independent audit branches, plan is approved` → expected process: Phase 0 intake numbers the branches and runs the independence audit (ABORT on any file overlap, L62), Phase 0.5 routes a persona per branch and waits for confirm (L79), Phase 1 dispatches all in one message with N worktree-isolated Agent calls (L88), Phase 2 gates each return with read-the-worktree verification (L120), Phase 3 writes the Inbox synthesis page (L156).
- anti-trigger `parallelize this — branch 2 needs branch 1's output` → should NOT fire (the inter-branch dependency fails the independence precondition); routes to N sequential `/sprint` runs per L44 / L199.
