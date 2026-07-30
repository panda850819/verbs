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
  **Contested since 2026-07-30**: `CHANGELOG.md` for v0.17.0 (#269) records the
  opposite, "keeping scheduling outside Verbs". Both are on record and they
  cannot both hold. Entry 5 opens by killing one of them.
- **Unattended permission envelope** — maintenance-class work (optimizations,
  bug fixes) up to PR; main development requires the human present; merge is
  always human.
- **Wayfinder targets the mattpocock model** — tracker-native maps (map issue,
  child decision tickets, native blocking, assignee = claim), replacing
  local-markdown-only.
  **Partially contradicted by what shipped**: `to-tickets` implements the map's
  blocking and child-ticket half, but forbids the claim half —
  `skills/productivity/to-tickets/SKILL.md:131-132` says "Do not assign, claim,
  branch for, or execute a frontier Issue." Entry 6 decides whether
  assignee-as-claim comes back.
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
- [Unattended runtime options](2026-07-13-verbs-v1-direction-map/02-unattended-runtime-options.md)
  — the enforcement layer is four hooks installed at host level, not in the
  repository; it travels fully only to local `claude -p`. Cloud routines have no
  plugin surface, `codex exec` skips hooks silently without persisted trust, and
  both `PreToolUse` guards match `Bash` only, so non-shell writes are invisible.

## Entries

### 1. Tracker mechanics inventory — `research` (AFK)
status: open, narrowed 2026-07-30 · blocked-by: none

Most of the original question was answered by implementation. `to-tickets`
already depends on native sub-issues and native `blocked by` dependencies
(`skills/productivity/to-tickets/SKILL.md:110-111`), keeps the body-convention
`## Parent` / `## Blocked by` fallback alongside them (`:88-113`), and
`setup-verbs` derives the tracker binding from the Git remote
(`skills/engineering/setup-verbs/SKILL.md:46-47`). Labels are untouched;
#265-#269 all carry none.

What remains, and all this entry now covers:

- Can frontier be a search query — `parent-issue:`, `blocked-by:`, `is:blocked`
  — instead of the O(n) per-child read-back `to-tickets` does today
  (`skills/productivity/to-tickets/SKILL.md:120-129`)?
- Does assignee-as-claim mean anything for a solo author?

One constraint worth carrying forward: on `gh 2.93.0` every native relation is
`gh api`-only. `gh issue view --json parent` returns `Unknown JSON field`, so
any host that can only reach `gh issue view` cannot see the graph.

### 2. Unattended runtime options — `research` (AFK)
status: closed (2026-07-30) · decision: [02-unattended-runtime-options](2026-07-13-verbs-v1-direction-map/02-unattended-runtime-options.md) · issue #274

### 3. Skill invocation matrix — `grilling` (HITL)
status: closed (2026-07-13) · decision: [03-skill-invocation-matrix](2026-07-13-verbs-v1-direction-map/03-skill-invocation-matrix.md) · issue #234

### 4. Wayfinder charting ownership — `grilling` (HITL)
status: open · blocked-by: none

Should wayfinder own its charting flow end to end (run the grilling inline,
create map + entries + blocking itself, like the original) instead of
delegating to `grill --brief` and stopping — the "轉接員" complaint from this
charting session. Output: composition decision for wayfinder/grill.

The terrain moved on 2026-07-30. #269 routes spec-sized `grill` closes into
`to-spec`, and `to-spec` / `to-tickets` are tracker-native, while `wayfinder`
is still markdown-only. So the question is no longer wayfinder-versus-grill;
it is where the line falls across four skills.

### 5. Redraw the scheduling ownership boundary — `grilling` (HITL)
status: open, unblocked 2026-07-30 · blocked-by: none (was
[2. Unattended runtime options](#2-unattended-runtime-options--research-afk),
closed)

Scheduling is now in scope — but what exactly does Verbs own: protocol only
(ticket shapes, claim/write-back contract), protocol + one reference trigger on
one host, or trigger implementations per host? Pick, and rewrite the
out-of-scope boundary text accordingly.

Precondition: settle the contradiction flagged under "Decisions so far" —
this map says scheduling moved into scope, `CHANGELOG.md` for v0.17.0 says it
stayed out. Kill one before picking a boundary.

Inputs are in
[02-unattended-runtime-options](2026-07-13-verbs-v1-direction-map/02-unattended-runtime-options.md).
Note in particular that cloud routines and the GitHub Action each already
enforce a harder native PR ceiling than the Verbs ticket gate does, which bears
on whether Verbs should own a trigger at all.

### 6. Tracker-native wayfinder trial — `prototype` (HITL)
status: open · blocked-by: [1. Tracker mechanics inventory](#1-tracker-mechanics-inventory--research-afk)
(narrowed, not closed)

Move THIS map onto GitHub Issues and work one entry there. The reaction to the
real artifact (does frontier-by-query beat the markdown file; is claim-by-
assignee livable solo) is the decision input for how far tracker-native goes.

#272 already exercised the mechanics on a real graph — #265 carries #266-#269
as native sub-issues and #269 carries #267-#268 as native `blocked by`. What is
untested is exactly the two questions above, which is also all that remains of
entry 1.

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
status: open, unblocked since 2026-07-16 · blocked-by:
[10. Close pilot evidence gaps](#10-close-pilot-evidence-gaps--task-afk),
closed

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
