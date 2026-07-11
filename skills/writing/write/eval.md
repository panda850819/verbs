---
type: skill-eval
skill: write
bucket: writing
evaluated_skill_hash: 7cc5c21c8dd6e43f4429f5a77a85bbb88ed704bc
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — write

**Verdict: SOLID.** The skill makes authorship boundaries executable and measurable: anti-ghostwriting routing at L39, candidate-only reference extraction at L134, enforced cold dispatch for >5K-token distillation at L141, and annotation-based editing that preserves user voice.

Grounding sample: L13 — "AI touches HOW you say it, never WHAT you say or WHY"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L29 — structured signal-to-mode table with eight distinct routes (Spar/Structure/Edit/Ref/Distill/English/Postmortem/Idea Gate) eliminates ambiguity; each mode carries concrete completion criteria and drift checks. |
| Description / invocation | weak | L4 — description bundles mode names, aliases, legacy migration details, and exclusions into one dense trigger string; could compress into simpler leading phrase with anti-triggers separated. |
| Completion criteria | pass | L125–136 — Reference mode states a four-step output contract: extract, analyze, emit a candidate, and confirm whether the host supplied a destination. |
| Information hierarchy | pass | L52, L141 — progressively discloses heavy reference loads: sparring pattern scan at L52 dispatches a sub-agent for ~8K tokens; Distill at L141 dispatches a read-only sub-agent above 5K tokens and keeps hot synthesis on digest only. |
| Leading words | pass | L15 — three concrete roles ("sparring partner, structure coach, and slop detector") anchor execution; reinforced by core principle at L13 (HOW/WHAT/WHY boundary). |
| Pruning | weak | L52 and L103 — the same ~8K article-pattern sub-agent scan and return contract is specified in both Spar and Edit; a shared pointer would reduce drift in an already-dense body. |
| Native parity | pass | L39 — names the default model ghostwriting reflex, replaces it with specific Spar redirect, preserves author's thesis before any prose generation — delta from native that merits the skill. |
| Granularity | pass | L48–212 — eight modes share voice resolution and anti-slop contracts but split by execution path; each branch occupies distinct input state and completion criteria, justifying the split. |
| Panda Verbs conformance | pass | L4 (alias frontmatter), L134 (read-only library semantics), L141 (hot/cold dispatch enforced), L298 (output validation reference) — all conformance checks verified and explicit. |

## Why it's good

The skill operationalizes the core HOW/WHAT/WHY boundary: it forbids ghostwriting (L39 redirect), forbids invented sentences in Structure (L81), forbids clean rewrites in Edit (L296), and requires exact line citations in Postmortem (L187). Reference emits a candidate only and never mutates the bundled `references/article-patterns.md` (L134); a host/project may persist candidates to its own store. Distill dispatches a read-only sub-agent for inputs exceeding 5K tokens (L141), keeping synthesis deterministic on pre-digested sources. Completion criteria are checkable, not vague: "every heading enumerated" not "reviewed the structure."

## Top fixes

1. L4 — compress description from dense trigger string into lead phrase + separate anti-trigger table; keep host-profile fallback and legacy alias but remove mode-name synonyms already in body.
2. L52/L103 — move the article-pattern cold-scan contract to one reference and keep only mode-specific use of its returned entry inline.

## Behavioral cases

- trigger `/write ref` with URL → extract pattern, emit candidate in entry shape (L134), confirm candidate + host destination (L137). Host may store candidate; bundled library remains read-only.
- trigger `/write distill` with >5K tokens → dispatch read-only sub-agent at L141 for source-keyed evidence digest; hot agent synthesizes only that digest.
- trigger `/write edit` with structured Chinese draft → resolve optional host profile (L23), load conditional references by trigger signals (L92–99), annotate changes with `>` + `→` (L122), self-score per quality-rubric.md (L89), run output validation (L298).
- trigger `/write spar` with raw topic → dispatch sub-agent for pattern scan (L52), ask 2–3 sparring questions (L53), output outline only (L56: self-check paragraph length ≤2 sentences).
- anti-trigger "de-AI this text" / "make it sound human" → should NOT fire; generic humanization outside contract.
- anti-trigger "final pass on investment memo" → should NOT fire; investment/IC memo final-pass cleanup explicitly excluded (L4).
