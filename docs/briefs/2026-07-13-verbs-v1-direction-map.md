# Decision map — Verbs v1.0 direction

> **Historical decision record.** Superseded as a living roadmap on 2026-08-06
> by [`README.md#Roadmap`](../../README.md#roadmap) after the v0.21 skills-only
> reset. Preserve the decisions below as evidence, but do not claim or execute
> this file's open entries as current work. GitHub Issues are the executable
> queue.

Charted: 2026-07-13, via the then-current `grill --brief` wayfinder exit.
Originally worked one entry per session.

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
  session), across ≥2 repos, ≥5 of them fired by a **host-native** scheduler
  (GitHub Actions, a `claude schedule` routine) rather than a manually started
  session, with 0 boundary violations (touched non-maintenance scope, or
  bypassed the PR path). Verbs supplies the ticket contract those runs read and
  write, never the scheduler — that contract is what this gate tests. Revised
  2026-07-30 with entry 5.
  Revised again 2026-07-31 with entry 7: "0 boundary violations" counts the
  **server-enforced** boundaries only — no direct push to `main`, no diff
  outside the declared ticket scope, no edit to `hooks/`, `.github/`, or
  `manifest.toml`. Merge is NOT among them. On a user-owned repository the agent
  runs as admin and can merge its own PR; that boundary is a human
  responsibility, not a measured one. Do not restore an unprovable clause here.
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
- **Scheduling / autonomous drivers stay OUT of Verbs scope** — reversed
  2026-07-30, entry 5. The 2026-07-13 charting decision to pull them in was
  never implemented, and the shipped product decided the other way twice:
  `README.md:115-116` (Product boundary) and `README.md:262-263` (v1.0 cut
  criteria) both name scheduling and autonomous drivers as out of scope, and
  the v0.17.0 CHANGELOG (#269) reaffirms it. What Verbs owns instead is the
  ticket-side contract an externally scheduled agent reads and writes; entry 7
  defines it. Decision:
  [2026-07-30-scheduling-ownership-boundary](2026-07-30-scheduling-ownership-boundary.md).
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
status: closed (2026-07-31) · decision:
[04-wayfinder-charting-ownership](2026-07-13-verbs-v1-direction-map/04-wayfinder-charting-ownership.md)
· issue #281

The entry named the wrong skill. `wayfinder` is thin at charting because `grill`
is fat: the interview protocol is bundled with forced alternatives, premise
refresh, and a routing gate that writes maps and calls `to-spec`, so a skill
that wants only the interview must invoke all of it and stop at someone else's
gate. The reference model inverts this — `mattpocock/skills` keeps `grilling` as
the primitive and makes `grill-me`, `grill-with-docs`, and `wayfinder` thin
entry points that compose it.

Decision: extract the interview protocol from `grill` into its own primitive;
`grill` and `wayfinder` each compose it. This also dissolves the escalation
question — a skill taking over mid-effort re-enters the primitive without
re-interviewing, so `grill` no longer needs map-writing as an escape hatch.

The restructuring is spec-sized and does not happen in #281; it gets a canonical
Spec Issue. Deliberately NOT bundled with the tracker move, which is entry 6.

### 5. Redraw the scheduling ownership boundary — `grilling` (HITL)
status: closed by reversal (2026-07-30) · decision:
[2026-07-30-scheduling-ownership-boundary](2026-07-30-scheduling-ownership-boundary.md)
· issue #277

The entry's premise did not survive. It assumed scheduling had entered scope
and only the line needed drawing; the shipped `README.md` says the opposite in
two places and nothing was ever implemented. There is no boundary to redraw.

Verbs owns no scheduler, trigger, or driver. It owns the ticket-side contract
an externally scheduled agent reads and writes — what a claimable ticket looks
like, what claiming means, what gets written back, where the PR ceiling is
asserted. Defining that contract is entry 7, which does not die with this
entry: unattended is not the same as scheduled.

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
status: closed (2026-07-31) · decision:
[07-unattended-guardrail-mechanism](2026-07-13-verbs-v1-direction-map/07-unattended-guardrail-mechanism.md)
· issue #279

The three candidate mechanisms in the original text were the wrong frame. A
guard, an allowlist, and a branch rule all fail identically, because the agent
holds the credential that outranks them: on a user-owned repository repo admin
is the ceiling, and merge and push are both `Contents: write`, so no token scope
says "may open a PR, may not merge".

Decision: the merge gate stays soft and is documented as soft; every boundary
beneath it moves server-side, out of any session's reach — `enforce_admins` on,
a PR-required ruleset with no bypass actor, a file-path ruleset over `hooks/`,
`.github/`, and `manifest.toml`, and a `pull_request_target` check binding each
PR to a maintenance-labelled Issue and its declared scope. Verbs-side, the
envelope moves into the `sprint` and `ship` skill bodies, plus a label scheme,
claim protocol, and write-back format. Settings and the CI check are follow-on
`sprint` work, not part of #279.

Rejected on cost, not mechanism: a fork lane (needs an org — GitHub will not
fork a repository into its own owner's account) and required approvals with no
bypass actor (a solo author cannot approve their own PR, so it gates the author
too).

The claim protocol needs `assignees`, which `to-tickets` currently forbids
(`skills/productivity/to-tickets/SKILL.md:131-132`). Entry 6 owns that conflict.

Original text follows, retained because the frame it names is what the decision
rejects.

Make the permission envelope enforceable, not prose: how an unattended session
is constrained to maintenance-class tickets and the PR ceiling (labels +
PreToolUse guard? allowlist? branch rules). Deliverable: the mechanism decision
and its enforcement point; implementation itself hands off to sprint.

Re-scoped 2026-07-30 with entry 5: this covers **unattended, not scheduled**.
An unattended session can be manually fired, so the envelope must hold
regardless of what starts it. Entry 5's reversal also hands this entry the
ticket-side contract to define, since that contract is now the whole of what
Verbs owns on this line.

The sharpest constraint is in
[02-unattended-runtime-options](2026-07-13-verbs-v1-direction-map/02-unattended-runtime-options.md):
`claude schedule` cloud routines have no plugin surface, so none of the four
Verbs hooks fire there. In that lane the ticket contract is the only
enforcement that exists — a PreToolUse-guard answer cannot reach it.

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
