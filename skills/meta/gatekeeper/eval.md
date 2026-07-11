---
type: skill-eval
skill: gatekeeper
bucket: meta
evaluated_skill_hash: 9ef78dd73f27a7e4136acc94f1b8b81bfe95f434
evaluated_at: 2026-07-11
rubric: writing-great-skills@1.1.0
---

# Eval — gatekeeper

**Verdict: SOLID.** Its leading virtue is one mandatory STRIDE classifier feeding four explicit software-artifact review routes and standardized reports; the main construction gap is that native parity remains implicit.

Grounding sample: L56 — "The gate is done only when a routed review template"

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L29 — the mandatory `Step 0: STRIDE Classification` gives every route the same classify-first spine before domain-specific review. |
| Description / invocation | pass | L6 — the description names all four software branches: skill/MCP/package install, repository, URL/document, and product/service/API/SDK. |
| Completion criteria | pass | L56 — completion requires a routed Step 1+ report with a risk rating and, for HIGH/REJECT, a human-decision line; a STRIDE table alone explicitly does not finish the gate. |
| Information hierarchy | pass | L52 — the live classifier stays inline while the worked example and rationale are cold-loaded; route-specific checks, patterns, and report templates are likewise behind pointers. |
| Leading words | pass | L31 — `STRIDE` supplies established threat-model vocabulary and a six-category decomposition instead of locally invented labels. |
| Pruning | weak | L60 — the five universal-principle subsections repeat trust and execution cautions also implemented by the classifier, risk table, and routed reviews; the 130-line body would benefit from a deletion pass over repeated rationale. |
| Native parity | weak | L16 — `Every external input is untrusted until verified` states the stance but does not name the nearest native behavior, ad-hoc repository/document review, or the delta: mandatory STRIDE, four-route specialization, and standardized risk output. |
| Granularity | pass | L22 — four routes remain one skill because they share the same STRIDE, risk, trust, pattern-library, and report contract; only their domain checks split into review references. |
| Panda Verbs conformance | pass | L2 — `name: gatekeeper` matches the folder, hot/cold pointers resolve, and `aliases`, `license`, and `upstream` are permitted extension frontmatter rather than runtime security claims. |

## Why it's good

The classifier protocol is deterministic: every artifact receives category statuses, a floor-only risk ratchet, and findings carried into the routed report. The four routes are complete and software-specific, while the completion clause prevents a premature STRIDE-only answer. Extra provenance frontmatter is advisory metadata and does not conflict with the required Panda Verbs fields.

## Top fixes

1. L16 — name native parity directly: ordinary review can inspect one artifact, while Gatekeeper adds a mandatory cross-route STRIDE vocabulary, risk floor, and standardized human-decision boundary before adoption.
2. L60 — compress universal principles that restate classifier or risk-table behavior; retain only rules that change a routed review step.

## Behavioral cases

- trigger `is this MCP/package safe to install?` → run STRIDE Step 0, then `reviews/skill-mcp.md`, and emit the standardized skill report.
- trigger `check this GitHub repository` → run STRIDE Step 0, then `reviews/repository.md`, and emit the repository report.
- trigger `review this URL, Gist, or document` → run STRIDE Step 0, then `reviews/url-document.md`, including prompt-injection analysis.
- trigger `evaluate this software service, API, or SDK` → run STRIDE Step 0, then `reviews/product-service.md`, including permissions and data-flow analysis.
- anti-trigger `review my branch before commit` → should NOT fire; internally authored code-diff review routes to `review`.
