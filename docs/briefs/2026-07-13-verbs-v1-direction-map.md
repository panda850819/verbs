# Decision map — Verbs v1.0 direction

Charted: 2026-07-13, via `grill --brief` (wayfinder exit). Work with `wayfinder`,
one entry per session.

## Destination

Verbs v1.0: the engineering flow is complete under BOTH human triggering and
AI triggering — idea → issue → develop → review → ship runs end to end, and
work stays aligned to project-level goals through tracker-native decision maps
(the mattpocock wayfinder model: map = issue, decisions = child issues, the
tracker is the shared spine between human and AI).

**Acceptance gate (proposed 2026-07-13, validate through dogfooding, revisit
after ~4 weeks):**

- **G-A unattended maintenance line**: 10 unattended PRs merged (agent claimed
  a bug/optimization ticket, resolved it, opened the PR without a human in the
  session), across ≥2 repos, ≥5 of them fired by a scheduler rather than a
  manually started session, with 0 boundary violations (touched non-maintenance
  scope, or bypassed the PR path).
- **G-B alignment line**: 2 wayfinder maps complete the full cycle
  (charting → frontier empty → sprint delivery), ≥1 of them living entirely on
  the GitHub tracker.
- **G-C attended dev line**: 2 consecutive 0.x releases with no breaking rename
  of product name, selector, namespace, manifest schema, or install contract
  (carried over from the old v1.0 gate; personal-first compatible).
- **G-D quality floor**: hook truth-table tests, `verbs sync` determinism,
  `doctor --strict` parity, and the model-upgrade behavioral audit all green at
  cut.

## Notes

- Primary user is the author (personal-first, per #220/#221). Public-product
  certification stays rejected.
- Standing permission envelope (decided this charting): attended = full
  development; unattended = optimizations and bug fixes only, up to opening a
  PR; merge is always a human gate.
- Skills every session should consult: `grill`, `prototype`; the invocation
  matrix entry also touches `maintainer/SKILL-FRONTMATTER.md`.

## Decisions so far

- **v1.0 is a personal milestone, not a public-product gate** — 流程完善 for
  human + AI triggering, full engineering cycle, project-level goal alignment;
  the old three-external-users gate is dead (#220/#221 made this official).
- **Scheduling / autonomous drivers move INTO Verbs scope** — the old
  out-of-scope line "Verbs does not own scheduling, autonomous drivers" is
  overturned for v1.0; the exact new boundary is entry
  [Redraw the scheduling ownership boundary](#entries).
- **Unattended permission envelope** — maintenance-class work (optimizations,
  bug fixes) up to PR; main development requires the human present; merge is
  always human.
- **Wayfinder targets the mattpocock model** — tracker-native maps (map issue,
  child decision tickets, native blocking, assignee = claim), replacing
  local-markdown-only.
- **Acceptance gate G-A..G-D proposed** — author delegated the numbers; they
  are provisional until dogfooding pressure-tests them.
- [Skill invocation matrix](2026-07-13-verbs-v1-direction-map/03-skill-invocation-matrix.md)
  — all 14 skills dual-channel (`user-invocable: true`, no
  `disable-model-invocation`); root cause was inverted semantics in the
  frontmatter spec; fixed in #234.
- [Skill-model fitness audit](2026-07-13-verbs-v1-direction-map/08-skill-model-fitness-audit.md)
  — use paired field-grounded canaries keyed by host + exact model + effort;
  full sweeps are event-triggered, and ordinary releases audit only affected
  skills.
- [Priority skill-model pilot](2026-07-13-verbs-v1-direction-map/09-priority-skill-model-pilot.md)
  — `sol/low` routing passed 8/8; pilot verdicts are `grill` EDIT,
  `wayfinder` KEEP, `review` EDIT, and `sprint` UNPROVEN pending a real
  write-enabled lifecycle case.
- [Pilot evidence gaps](2026-07-13-verbs-v1-direction-map/10-close-pilot-evidence-gaps.md)
  — two real diffs confirm `review` EDIT and justify a low-risk fast path; two
  write-enabled cases promote `sprint` from UNPROVEN to KEEP for Codex CLI +
  `gpt-5.6-sol` + low effort.
- [Slim the low-risk review path](2026-07-13-verbs-v1-direction-map/12-slim-low-risk-review-path.md)
  — the real low-risk canary used about 43% fewer tokens with the same outcome;
  the trust-boundary canary retained executable evidence and cold review.

## Entries

### 1. Tracker mechanics inventory — `research` (AFK)
status: open · blocked-by: none

What do GitHub Issues natively give us for the wayfinder model: sub-issues /
parent-child, blocked-by relationships, labels, assignee-as-claim, frontier
queries — via `gh` CLI from Claude Code and Codex. What needs a body-convention
fallback. Cited finding; include what mattpocock's tracker doc specifies as
"Wayfinding operations".

### 2. Unattended runtime options — `research` (AFK)
status: open · blocked-by: none

Inventory the ways an unattended agent can run against the tracker: Claude Code
headless/scheduled (cron, `claude schedule` routines), `codex exec`, GitHub
Actions. Constraints per option: secrets exposure, sandboxing, cost, how the
ticket-gate hooks travel. Cited finding, no decision.

### 3. Skill invocation matrix — `grilling` (HITL)
status: closed (2026-07-13) · decision: [03-skill-invocation-matrix](2026-07-13-verbs-v1-direction-map/03-skill-invocation-matrix.md) · issue #234

### 4. Wayfinder charting ownership — `grilling` (HITL)
status: open · blocked-by: none

Should wayfinder own its charting flow end to end (run the grilling inline,
create map + entries + blocking itself, like the original) instead of
delegating to `grill --brief` and stopping — the "轉接員" complaint from this
charting session. Output: composition decision for wayfinder/grill.

### 5. Redraw the scheduling ownership boundary — `grilling` (HITL)
status: open · blocked-by: [2. Unattended runtime options](#2-unattended-runtime-options--research-afk)

Scheduling is now in scope — but what exactly does Verbs own: protocol only
(ticket shapes, claim/write-back contract), protocol + one reference trigger on
one host, or trigger implementations per host? Pick, and rewrite the
out-of-scope boundary text accordingly.

### 6. Tracker-native wayfinder trial — `prototype` (HITL)
status: open · blocked-by: [1. Tracker mechanics inventory](#1-tracker-mechanics-inventory--research-afk)

Move THIS map onto GitHub Issues and work one entry there. The reaction to the
real artifact (does frontier-by-query beat the markdown file; is claim-by-
assignee livable solo) is the decision input for how far tracker-native goes.

### 7. Unattended guardrail mechanism — `task` (AFK-leaning)
status: open · blocked-by: [5. Redraw the scheduling ownership boundary](#5-redraw-the-scheduling-ownership-boundary--grilling-hitl)

Make the permission envelope enforceable, not prose: how an unattended session
is constrained to maintenance-class tickets and the PR ceiling (labels +
PreToolUse guard? allowlist? branch rules). Deliverable: the mechanism decision
and its enforcement point; implementation itself hands off to sprint.

### 8. Skill-model fitness audit — `research` (AFK)
status: closed (2026-07-16) · decision: [08-skill-model-fitness-audit](2026-07-13-verbs-v1-direction-map/08-skill-model-fitness-audit.md)

Turn recent Matt Pocock field observations about model + effort, skill usage,
and workflow failures into a repeatable audit for whether each Verbs skill still
earns its slot on the current model. Compare that method with the existing
`current-model-recut` and define the evidence and cut/keep/edit gates. Output:
a cited decision note and follow-up entries for running the audit.

### 9. Priority skill-model pilot — `task` (AFK)
status: closed (2026-07-16) · blocked-by: [8. Skill-model fitness audit](#8-skill-model-fitness-audit--research-afk) · decision: [09-priority-skill-model-pilot](2026-07-13-verbs-v1-direction-map/09-priority-skill-model-pilot.md)

Run the canary triplet on `grill`, `wayfinder`, `review`, and `sprint` against
the exact current host/model/effort combinations, starting at the lowest useful
effort. Record paired evidence and assign KEEP / EDIT / PIN / CUT; the output is
a decision note, not an eval-harness implementation.

### 10. Close pilot evidence gaps — `task` (AFK)
status: closed (2026-07-16) · blocked-by: [9. Priority skill-model pilot](#9-priority-skill-model-pilot--task-afk) · decision: [10-close-pilot-evidence-gaps](2026-07-13-verbs-v1-direction-map/10-close-pilot-evidence-gaps.md)

Run `review` against two real repository diffs and run `sprint` inside a
disposable write-enabled repo through acceptance, bounded review, and its
no-remote delivery boundary. Output: decision-grade verdicts for `review` and
`sprint`, or a cited reason the audit method still cannot distinguish their
native and skill-added behavior.

### 11. Remaining skill-model matrix — `task` (AFK)
status: open · blocked-by: [10. Close pilot evidence gaps](#10-close-pilot-evidence-gaps--task-afk)

If the pilot's gates then produce stable decisions, apply the same audit to
`careful`, `gatekeeper`, `debug`, `ui`, `qa`, `codebase-design`, `prototype`,
`ship`, `advisor`, and `handover`. Stop and revise the method first if the pilot
cannot distinguish native parity, skill lift, and effort lift.

### 12. Slim the low-risk review path — `task` (AFK)
status: closed (2026-07-16) · blocked-by: [10. Close pilot evidence gaps](#10-close-pilot-evidence-gaps--task-afk) · decision: [12-slim-low-risk-review-path](2026-07-13-verbs-v1-direction-map/12-slim-low-risk-review-path.md) · issue #248

Implement and evaluate a low-risk fast path for `review`: preserve provenance,
one correctness pass, and self-refutation, but skip the full multi-pass envelope
unless the diff or repository context raises a risk trigger. Keep the current
trust-boundary behavior unchanged. Delivery runs through `sprint` from an
issue-keyed worktree.

## Not yet specified

- What the ATTENDED development path still lacks for 流程完善 — expect
  dogfooding to expose this; too dim to phrase as one question yet.
- Multi-host parity under unattended operation (does Codex get an unattended
  seat; does Hermes matter here at all).
- Goal alignment ABOVE a single repo — whether maps ever span repos, and what
  "project-level goals" look like when the project is a fleet.
- Whether G-A..G-D numbers survive contact with dogfooding.

## Out of scope

- **Public-product certification** (fresh-user smoke matrices, non-author
  install gates) — rejected 2026-07-12, `.out-of-scope/fresh-user-certification.md`;
  reopens only with real external users.
- **Hosted SaaS, vault-provider abstraction, persona layer, B-class vaultless
  mode** — standing rejections in `.out-of-scope/`, unchanged by this map.
- **Auto-merge of any category** — decided this charting: merge is always a
  human gate, even for low-risk maintenance PRs.
