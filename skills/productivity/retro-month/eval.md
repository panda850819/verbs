---
type: skill-eval
skill: retro-month
bucket: productivity
evaluated_skill_hash: 2c943729c43076cebba14bf4f3615e5303ac3897
evaluated_at: 2026-06-30
rubric: writing-great-skills@1.0.0
---

# Eval — retro-month

**Verdict: SOLID.** A hard-anchored one-question interview with a completion floor that survives every branch, now made distribution-safe via env-var indirection and brain-less write guards without disturbing the process spine.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L13 — the fixed three-phase spine (auto-scan → interview → write) pins the same _process_ every run regardless of the output it produces; the engine is shared so Claude/Codex/Hermes converge. |
| Description / invocation | weak | L3 — front-loads "Interactive monthly retro" and stays out of the body, but carries three trigger phrasings for one branch ("/retro-month", "monthly retro", "monthly review"); the two NL forms are synonyms renaming one branch and should collapse (same call the sibling retro-week eval made). |
| Completion criteria | pass | L66 — "A run that produced only the scan with no goal-alignment answers is not done" is a checkable, every-branch (scan-only / 短版) floor that forces the legwork and blocks premature completion. |
| Information hierarchy | pass | L35 — engine block detail + weekly-retro reference commands pushed behind `lib/scan-blocks.md`; the full output template behind `lib/retro-template.md` (L114), leaving the steps hot and the reference cold. |
| Leading words | pass | L130 — "append + supersede over delete + rewrite" borrows a pretrained version-control anchor to compact the memory-update discipline in a few tokens; "drift" (L75) and "commodity" (L94) anchor likewise. |
| Pruning | weak | L132 — the scan-only/短版 completion floor is restated a third time here after L62 and the canonical L66; one meaning in three places, on top of a 124-line body (rubric guideline ~<80). |
| Granularity | pass | L94 — 2b-v is split out as an always-ask atomic layer distinct from the conditional 2b-ii–iv, and the 短版 path (L132) still forces 2b-i; each sequence split earns its load against premature completion. |
| pandastack conformance | weak | L110 — the brain-less write guard (`if [ -d "$BRAIN" ] … else docs/retros/monthly`) and the `$CLAUDE_PLUGIN_ROOT` engine fallback (L23) are correct distribution-safe robustness, frontmatter is valid and both `lib/` refs resolve; weak only on the 124-line body over the ~80 guideline. |

## Why it's good
The interview engine is the load-bearing strength: one-question-at-a-time with a hard completion floor (L66) that even scan-only and 短版 runs cannot short-circuit, verbatim capture including "想不到/沒有" (L98), and a never-invent rule (L114) make a genuinely stochastic strategic conversation reproducible. The path de-personalization is a clean robustness win, not a defect: `${PANDASTACK_BRAIN:-…}` defaults (L48, L109), a `$CLAUDE_PLUGIN_ROOT` engine path with a checkout fallback (L22-23), and a write guard that falls back to `docs/retros/monthly/` so a brain-less install never fabricates the author's tree (L110). The append+supersede memory discipline (L130) protects project memory from lossy rewrites.

## Top fixes
1. L3 — collapse "monthly retro" / "monthly review" into one trigger, or justify why both NL phrasings are needed; as written they rename a single branch.
2. L62 / L66 / L132 — keep the scan-only completion floor in one canonical place (L66) and have L62 and L132 point back to it instead of re-stating the rule.
3. L116-122 — push the Step 3b mechanical update checklist behind a `lib/` reference to pull the body back toward ~80 lines without losing the interview spine.

## Behavioral cases
- trigger `/retro-month` → expected process: run `retro-scan.sh month` via `$CLAUDE_PLUGIN_ROOT` or the checkout fallback (L22-24), print the compressed scan block, ask "掃完了。要開始月度 interview 嗎？" (L37), then one-question-at-a-time interview through 2b-i…2b-v, then write `$OUT_DIR/$YEAR-$MONTH.md` (brain if present, else `docs/retros/monthly/`).
- trigger `monthly review` → expected process: same three-phase flow; if a Hermes cron already wrote the prep, locate it via `ls -t` over `$BRAIN/inbox/retros` (L49) and read instead of re-scanning.
- anti-trigger `weekly retro` → should NOT fire (routes to retro-week; 7-day vs 30-day window, weekly output dir).
- anti-trigger `stress test this idea` → should NOT fire (routes to grill / office-hours; fuzzy-idea intake, not a periodic retro).
