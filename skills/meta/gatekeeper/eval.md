---
type: skill-eval
skill: gatekeeper
bucket: meta
evaluated_skill_hash: b8aa98191abc516aa774ff7ba57c0cb9f51dad0f
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — gatekeeper

**Verdict: SOLID.** Leading virtue is a hard, predictable router: a mandatory STRIDE Step 0 (L29) classifies every artifact identically before routing to one of seven cold branches, and the new "Gate completion" clause (L54) closes the premature-stop hole. Costs points on a description that clusters synonym triggers onto one branch (L6) and a residual optional-tool stub (L137).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L29 — "Step 0: STRIDE Classification (mandatory)" forces classify-before-route on every artifact; the 7-step classifier protocol (L44-50) plus the floor-only ratchet (L49) run identically regardless of artifact type, so the process is the same every run. |
| Description / invocation | weak | L6 — the natural-language triggers anchor only 3 of the 7 routes ("is this safe to install" → skill-mcp, "check this repo" → repository, "看這個協議的中央化風險" → defi-protocol), leaving url-document / onchain / product-service / message-share without an invocation anchor, and "trust check" restates the skill's own identity rather than naming a trigger. |
| Completion criteria | pass | L54-56 — "Gate completion" defines a checkable end-state: a routed Step-1+ report carrying a risk rating, plus a human-decision line for 🔴/⛔, and explicitly rules out the STRIDE-table-alone stop the structure could otherwise invite. |
| Information hierarchy | pass | L52 — the illustrative worked example and the why-before-routing essay are extracted to lib/stride-rationale.md behind a pointer; what stays hot (routing table L21-27, STRIDE taxonomy L33-40, risk/trust scoring tables) is consulted every run, so disclosure is progressive and co-located by need. |
| Leading words | pass | L29 — "STRIDE" is a strong pretrained threat-model anchor doing real invocation+execution work; the L33-40 table reuses the canonical Spoofing/Tampering/Repudiation/… names rather than inventing labels, so each row anchors to pretrained meaning. |
| Pruning | weak | L135-138 — "Available tools for on-chain checks" pairs a generic "Block explorers via WebFetch" line with "A protocol-specific alert-triage skill, if your private overlay supplies one (optional)"; the optional-overlay clause is hedge sediment naming no concrete contract and is the one passage not earning its load. |
| Granularity | pass | L52 — the single lib/ split (stride-rationale.md, 22 lines of example + rationale) earns its load: it is the one block that is pure illustration; every other section is a per-run dispatch or scoring table that must stay hot, so the split count is minimal and justified. |
| pandastack conformance | pass | L2 — frontmatter name=gatekeeper matches folder skills/meta/gatekeeper; body is 137 lines but earns it (seven routing branches + STRIDE + risk + trust + template tables are all per-run reference, essay correctly cold in lib/); all 17 pointers verified to resolve on disk. |

## Why it's good

The router is genuinely predictable: STRIDE Step 0 is mandatory and runs the same 7-step protocol on every artifact before any branch-specific work, and the floor-only ratchet (L49) guarantees the classifier can raise scrutiny but never downgrade a higher independent rating. The repair since the prior eval landed where it mattered — the worked example and rationale essay moved to lib/ (L52), and "Gate completion" (L54-56) now names a checkable end-state so the agent cannot stop at a STRIDE table and call the gate done. Every hot section is a table the agent consults during a run, so the 137 lines read as reference density rather than sprawl.

## Top fixes

1. L6 — give each route a natural-language trigger: the description anchors only 3 of the 7 routes, so add leading anchors for the four unanchored routes (url-document / onchain / product-service / message-share); drop "trust check", which renames the skill rather than triggering a branch.
2. L135-138 — cut or harden the optional-tool stub: "if your private overlay supplies one (optional)" is hedge sediment with no decidable action; either name the concrete tool contract or move the note to lib/, leaving only the sensitive-path floor (L128-133) hot.
3. L7 vs _meta.json — reconcile metadata: frontmatter version 0.3.0 vs _meta.json 0.1.1, and the _meta.json description still omits the DeFi-protocol branch; not a SKILL.md body defect but it will mislead the manifest.

## Behavioral cases

- trigger `看這個協議的中央化風險` -> expected process: STRIDE Step 0 classify (L29), then route to reviews/defi-protocol.md (multi-contract governance/admin scope, L25) not onchain.md, emit templates/report-defi-protocol.md with Privileged Surface + Timelock + Verdict, human-decision line if 🔴/⛔.
- anti-trigger `review my code before I push this PR` -> should NOT fire (routes to pandastack:review / code-review — an internally authored diff, not an external untrusted artifact crossing the trust boundary).
