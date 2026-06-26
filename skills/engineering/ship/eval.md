---
type: skill-eval
skill: ship
bucket: engineering
evaluated_skill_hash: 07fdfe80d8bdedfd43635c297e75ad4ecbc6b5b7
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — ship

**Verdict: SOLID.** A disciplined multi-mode close-verb: ordered, checkable git steps with a strong mode-dispatch table and clean progressive disclosure of the knowledge variant behind a pointer.

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L39 — mode dispatch table forces the same branch resolution every run; 11 numbered git steps run in fixed order. |
| Description / invocation | pass | L5 — "Multi-mode ship verb" front-loads the leading word; one trigger per branch (git / knowledge), reach clause to /handover (L8). |
| Completion criteria | weak | L74 — "do a quick sanity check against the diff" has no checkable done-state; same softness at L149 ("if it revealed something useful") invites premature completion / skipping. |
| Information hierarchy | pass | L183 — knowledge mode pushed entirely behind `@./modes/knowledge.md`, keeping SKILL.md's hot body the git path only. |
| Leading words | weak | L63 — "Pre-flight" anchors well, but L78/L97/L103 lean on generic section labels ("Scope Check", "Review Gate", "Commit") that restate rather than collapse into a pretrained anchor. |
| Pruning | weak | L167 — the "Common Rationalizations" table is mostly no-op persuasion the model already obeys; combined with frontmatter `forbids` (L28) and Step 6 (L113) it triples the "never push to main" rule. |
| Granularity | pass | L43 — knowledge variant split by invocation behind a pointer; git steps split by sequence to fight rush, each earning its cut. |
| pandastack conformance | weak | L33 — body runs 183 lines, well past the ~<80 budget; `name: ship` and firewall fields are valid and `lib/` ref (L155) resolves, but the length is not clearly earned over the rationalizations table. |

## Why it's good
The mode-dispatch table (L39-49) plus the path-sniff fallback (L46-50) make branch selection deterministic before any step runs, which is the root virtue here. The git path is a genuine ordered pipeline — pre-flight, scope check, review gate, commit, branch, push — each step naming concrete commands (`git pull`, `git diff --stat`, `git log origin/{main}..HEAD`) so "done vs not-done" is mostly observable. Knowledge mode is correctly held cold behind a single pointer, so the always-loaded body stays the common-case git flow.

## Top fixes
1. L74 / L149 — replace soft criteria ("quick sanity check", "if it revealed something useful") with a checkable gate (e.g. "if any matched pitfall touches a changed file, list it and require ack; else skip").
2. L167-177 — cut or compress the Common Rationalizations table; it is persuasion prose the agent already obeys and it duplicates the L27/L113 main-push rule. This is the cheapest path back under the length budget.
3. L113 — collapse the thrice-stated "never push to main" (frontmatter `forbids` L28, Step 6 L113, rationalization L176) to a single source of truth.

## Behavioral cases
- trigger `/ship` (no args) → expected process: git mode — read config, pre-flight (pull/test/diff/log/branch), scope + review gates, conventional commit, feature branch, push -u, gh pr create, return PR URL.
- anti-trigger `hand this unfinished build unit to Codex` → should NOT fire (routes to /handover — L8 explicitly disclaims this; /ship closes finished work, /handover delegates unfinished).
