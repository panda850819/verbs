---
date: 2026-07-24
type: brief
source: grill
topic: Verbs public operating model
tags: [brief, grill, documentation, skill-portfolio]
---

# Verbs public operating model

## Problem

A first-time engineer can see that Verbs contains skills, hooks, manifests, and
tests, but cannot quickly reconstruct the product's operating model:

- which engineering failure each skill exists to prevent;
- how work moves through the main flow and its situational on-ramps;
- where `wayfinder` and `handover` branch from the normal path;
- what each hook or gate enforces and where it stops execution;
- which document owns human explanation, machine routing, and catalog identity.

The information is split across `README.md`, `PHILOSOPHY.md`, `RESOLVER.md`,
`DISPATCH.md`, `manifest.toml`, and an older direction map. These surfaces have
already drifted in skill counts, versions, catalog coverage, and the scheduling
boundary.

## Original premise

Make Verbs as clear, continuous, and extensible as Matt Pocock's skill pack by
comparing Verbs with `mattpocock/skills`: understand the problems each pack
expects, the paths it recommends, why each skill exists, and which capabilities
Verbs should add, keep, defer, or cut.

## Revised premise (after grill)

Verbs already contains most of its execution and enforcement machinery. The
first deliverable is a two-layer public documentation contract:

- `README.md` gives a first-time engineer a 60-second, problem-first
  introduction to the failure modes, main flow, on-ramps, and hook/gate model.
- `RESOLVER.md` becomes the complete human-facing operating model: routing
  rationale, branch conditions, skill responsibilities, compositions, and
  disambiguation.

`DISPATCH.md` remains the machine-routing source, while `manifest.toml` remains
the product and skill-catalog source. Dynamic catalog content in `README.md` is
rendered by `scripts/verbs sync`; handwritten counts and copied version claims
are removed.

Matt's pack is evidence and a comparison baseline. Verbs keeps its own product
boundary and does not copy Matt's skill list or lifecycle mechanically.

## Alternatives considered

- A: README repair — rewrite only the homepage and generate its catalog —
  **Reject**
- B: README + RESOLVER operating model — split 60-second onboarding from the
  complete human model while retaining DISPATCH and manifest ownership —
  **Add**
- C: New `docs/OPERATING_MODEL.md` — introduce a third routing-related
  document — **Reject**

## Chosen approach

B — use the existing README and RESOLVER surfaces, with generated catalog
content, so each document has one audience and no additional operating-model
file competes for ownership.

Executable plan: `docs/plans/verbs-public-operating-model.md`

## Scope

In:

- define the four-source documentation contract:
  - README: first-visit product story and summary flow;
  - RESOLVER: complete human-facing operating model;
  - DISPATCH: machine routing;
  - manifest: product identity and skill catalog;
- rewrite README around failure modes and a conditional lifecycle;
- document normal flow and situational on-ramps;
- explain SessionStart, PreToolUse, and Stop hook boundaries by the failure each
  prevents;
- expand RESOLVER with rationale, composition, branch conditions, and exact
  disambiguation;
- generate the README skill table from `manifest.toml`;
- remove handwritten current counts and copied RESOLVER version claims;
- reconcile living documentation with the current scheduling/autonomous-driver
  boundary, while preserving historical decision artifacts as history;
- record portfolio decisions from this grill without implementing them.

Out:

- adding, removing, or changing runtime skills in this documentation slice;
- implementing `setup-verbs`, `domain-modeling`, `research`,
  `improve-codebase-architecture`, or `resolving-merge-conflicts`;
- removing `scripts/verbs init`;
- implementing tracker-native wayfinder;
- adding `.verbs.toml`;
- adding triage before its reopen condition;
- copying Matt's HTML architecture report or `never --abort` rule;
- changing hooks or their enforcement behavior.

## Seams

- `manifest.toml` is the source seam for skill name, tier, description,
  resources, composition, and product version.
- `scripts/verbs sync` is the generation seam for the README catalog and
  existing loader metadata.
- `scripts/verbs sync --check` proves generated documentation matches the
  manifest.
- `tests/verbs-sync.sh` covers deterministic generation.
- `tests/resolver-routes-test.py` proves RESOLVER exposes exactly the manifest
  skill surface.
- `scripts/lint-manifest-sync.sh` rejects stale living-document claims.
- `bash tests/run-all.sh` is the final repository acceptance path.

## Success signals

A first-time engineer who reads only `README.md` can:

1. state which common engineering failures Verbs addresses;
2. choose the correct first skill from a concrete situation;
3. explain the normal path and when `wayfinder` or `handover` branches;
4. distinguish skill guidance from hook/gate enforcement;
5. follow one link to the complete RESOLVER model.

The repository then proves:

- the README skill catalog equals `manifest.toml`;
- no handwritten current skill count or RESOLVER version can drift;
- RESOLVER covers every active skill exactly once in its catalog;
- all existing repository tests pass.

## Portfolio decisions

These are decisions for later work, not part of this documentation
implementation:

| Surface | Verdict | Reason / reopen condition |
|---|---|---|
| `setup-verbs` | ADD candidate | Configure per-repo issue tracker, context, artifact, test, release, and learning pointers through the existing `## verbs` block. |
| `domain-modeling` | ADD candidate | Maintain stable terms, definitions, and relationships in the project-configured `CONTEXT.md`; reusable by grill, wayfinder, and architecture work. |
| `research` | ADD candidate | Primary-source research leaves cited Markdown by default; `quick` returns chat-only output. |
| `triage` | DEFER | Reopen when the first external issue or PR creates a real raw-request intake surface. |
| `improve-codebase-architecture` | ADD candidate | Scan recent hot spots and rank architecture candidates before routing the selected candidate to grill. |
| `resolving-merge-conflicts` | ADD candidate | Preserve both sides' intent with a state snapshot, verification, and a safe-abort branch. |
| `scripts/verbs init` | CUT candidate | Duplicates README and `bootstrap.sh`; the name implies project initialization while it only prints install commands. |
| browser `qa` | KEEP | Provides live browser acceptance evidence; Matt's deprecated QA was a different issue-intake workflow. |

Portfolio changes begin only after this documentation slice ships. Each ADD or
CUT still requires its own issue, evidence, and normal Verbs delivery flow.

## Project configuration decision

Per-repo configuration extends the existing `## verbs` block in `AGENTS.md` or
`CLAUDE.md`. It may point to longer project documents while keeping the injected
block small. `.verbs.toml` reopens only when hooks or CLI code require reliable
machine parsing, nested or per-host configuration appears, natural-language
parsing causes a real error, or configuration materially increases cold-start
context.

`CONTEXT.md` contains stable domain terms, definitions, relationships, and
resolved ambiguities. Product and architecture decisions remain in briefs or
the repository's configured decision artifacts.

## Next skill (recommended)

Apply `lib/skill-decision-tree.md` 2-question test against the chosen approach:

```text
Shape: single-target-iterative
Reasoning: the documentation contract, generator seam, and drift tests require
active judgment and iteration in one foreground session.

Recommended skill:
  → /sprint verbs-public-operating-model
```

## Gotchas surfaced

- Matt's `wayfinder` is a situational on-ramp for work too large and foggy for
  one session; making it the universal spine would change the product.
- Matt's deprecated QA captured conversational bug reports into GitHub Issues;
  it does not replace Verbs browser QA.
- A generated README catalog should replace copied dynamic facts, while the
  problem-first narrative remains handwritten.
- RESOLVER and DISPATCH must not become two competing routing sources:
  RESOLVER explains why and how to choose; DISPATCH supplies the concise
  machine trigger table.
- Historical direction maps remain historical evidence. Living README and
  product-boundary claims must state current decisions only.
- The unrelated untracked `.claude/` directory in the current worktree belongs
  to Panda and remains untouched.

## Gate Log

- Stage 1 (load context): inspected current Verbs docs, manifest, hooks, tests,
  and full `mattpocock/skills` history through 2026-07-21.
- Stage 2 (premise challenge): 14 decisions, one reverse-premise push; no
  escape hatch.
- Stage 3 (alternatives): A Reject, B Add, C Reject.
- Stage 4 (premise refresh): original premise remains partially load-bearing;
  comparison became a Verbs-owned documentation contract.
- Stage 5 (output): brief saved to
  `docs/briefs/2026-07-24-verbs-public-operating-model.md`.

## OPEN_QUESTIONS

- Which current scheduling/autonomous-driver decision supersedes the
  contradictory living and historical claims?
- What order should the later ADD/CUT portfolio candidates follow after the
  documentation slice ships?
