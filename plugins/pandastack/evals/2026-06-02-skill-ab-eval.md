---
date: 2026-06-02
type: eval-report
method: Nisi-style A/B (load-skill vs not), neutral judge
run: wf_fcab7903-585
cost: 188 agents / 5.6M tokens / ~14min
caveat: n=3 fixtures, 1 run, no burn-in
---

# Pandastack Skill A/B Eval — 2026-06-02

Origin: [[../../../../knowledge/brain/media/videos/nisi-deleted-95-percent-skills-personalized]] — measure don't assume. Harness: gatekeeper/evals/ab-pilot/PROTOCOL.md.

# Pandastack Skill A/B Eval Report

n=3 fixtures, 1 run, no burn-in. Threshold: |delta| > 0.15 to act.

## 1. Summary Table (sorted by delta ascending, most-harmful first)

| Skill | Mode | Without% | With% | Delta | Verdict |
|---|---|---|---|---|---|
| office-hours | preference | 100.0 | 66.7 | **-0.333** | hurt |
| review | verdict | 100.0 | 66.7 | **-0.333** | hurt |
| ceo | preference | 100.0 | 100.0 | 0.000 | noise |
| deepwiki | verdict | 66.7 | 66.7 | 0.000 | noise |
| design-lead | preference | 83.0 | 83.0 | 0.000 | noise |
| dojo | verdict | 50.0 | 50.0 | 0.000 | noise |
| freeze | verdict | 100.0 | 100.0 | 0.000 | noise |
| gatekeeper | verdict | 83.3 | 83.3 | 0.000 | noise |
| ops-lead | preference | 83.3 | 83.3 | 0.000 | noise |
| qa | verdict | 100.0 | 100.0 | 0.000 | noise |
| sprint | verdict | 100.0 | 100.0 | 0.000 | noise |
| boardroom | preference | 73.3 | 76.7 | +0.034 | noise |
| retro-week | preference | 66.7 | 83.3 | +0.166 | help* |
| careful | verdict | 83.3 | 100.0 | +0.167 | help* |
| eng-lead | verdict | 83.3 | 100.0 | +0.167 | help* |
| retro-month | preference | 28.3 | 90.0 | +0.617 | help |
| grill | preference | 50.0 | 71.7 | +0.217 | help |
| team-orchestrate | verdict | 66.7 | 100.0 | +0.333 | help |
| skill-creator | verdict | 66.7 | 100.0 | +0.333 | help |
| pandastack:write | preference | 60.0 | 100.0 | +0.400 | help |
| ship | verdict | 50.0 | 100.0 | +0.500 | help |
| using-pandastack | verdict | 50.0 | 100.0 | +0.500 | help |
| product-lead | preference | 33.3 | 100.0 | +0.667 | help |
| agent-browser | na | 0.0 | 0.0 | 0.000 | na |
| checkpoint | na | 0.0 | 0.0 | 0.000 | na |
| init | na | 0.0 | 0.0 | 0.000 | na |

\* delta inside the 3-fixture noise band, single-fixture-driven. See Caveats.

## 2. CUT Candidates (hurt / noise)

Two skills actively hurt; the rest of the noise band adds tokens without moving correctness.

**Actively harmful — fix or cut:**

- **office-hours** (-0.333): Caused the failure it exists to prevent. On the already-concrete fixture the skill invoked "Stage 2 protocol still applies," ran a two-question interrogation on a decided/tested two-way-door change, and reframed PR scope as changing. Baseline correctly routed to ship. **Needs fixture re-check, not blind delete** — the over-fire is a guard-condition bug (missing "scope already concrete → decline to grill" gate), fixable. If unfixed, cut.
- **review** (-0.333): Invented a phantom `jwt.decode` signature-bypass P0 on a self-issued token and inflated severities on scope-drift. Both arms reached the correct top-level verdict; the skill only added false findings + scaffolding. **Needs fixture re-check** — the hallucinated security finding is the failure mode. If the STRIDE wrapper keeps manufacturing P0s, cut; correctness lives in the baseline already.

**Noise — net-zero correctness, pure token cost (safe to cut on token grounds, no fixture re-check needed):**

- **ceo, qa, sprint, freeze, design-lead, ops-lead** (delta 0.000, both arms already ~0.83–1.0): Baseline is already strong. Skill adds framework grids / Iron-Law citations / pass-structure / ASCII diagrams that earn no correctness. Pure formatting tax. Safe to cut unless the formatting itself is the deliverable Panda wants.
- **gatekeeper** (0.000): Net wash that hides two opposing errors — helped on `~/.claude/` sensitive-path detection (real env knowledge baseline lacked), but mechanically inflated a fully-audited benign local script LOW→MEDIUM on provenance alone (the exact over-fire the rubric forbids). **Needs fixture re-check** — the STRIDE "suspect-count → severity floor" rule is a real bug worth fixing before cut; the sensitive-path knowledge is worth keeping.
- **deepwiki** (0.000): Wash that hides a dangerous false-confidence mode — the with-arm self-certified compliance in a Quality Gate preamble, then drew the exact forbidden wired architecture diagram anyway. Template gave false confidence while violating its own rule. **Needs fixture re-check** — if the gate keeps green-lighting violations, it is worse than nothing.
- **dojo** (0.000, both arms 0.5): Fails the one fixture it exists for. On anti-fabrication BOTH arms force-fit an irrelevant Stripe idempotency note as a rate-limiter gotcha; the with-arm additionally invented "clock skew" and "distributed burst" gotchas from training prior — the exact failure the skill should block. Its format dressed up the fabrication. **Needs fixture re-check / redesign** — currently does not do its job.
- **boardroom** (+0.034): Truncated to a single voice on the consensus-trap fixture, failing the inter-voice-conflict requirement it is built to demonstrate. Net positive is noise. **Fixture re-check** on the truncation bug.

## 3. EARNS ITS TOKENS (help)

What each help-verdict skill adds that the baseline lacks:

- **product-lead** (+0.667): Strongest signal. Converts an agreeable multi-metric brief-writer into discipline that challenges the premise when no user problem exists, commits to ONE proof metric instead of a vanity dashboard, and still recognizes the case that already meets the bar without over-firing the say-no reflex. Fixes real baseline failures (me-too dark-mode ratification, leaky-bucket multi-metric, yes-without-a-metric).
- **retro-month** (+0.617): Holds surface-not-prescribe discipline where the baseline reads the obvious story off a scan as a finished verdict, and holds append+supersede content-preservation where the baseline deletes load-bearing "How to apply:" guidance on "update." Broad gain across all 3 fixtures.
- **ship** (+0.500): Decisive on the `--no-verify` fixture — baseline talks itself into bypassing the gate via the "unless user explicitly requests" clause; skill refuses and surfaces the real failure path. Also removes baseline's CI-bypass escape-hatch suggestion.
- **using-pandastack** (+0.500): Fires the prod gate (`careful`) on a "just a typo" billing-path edit the baseline edits blind, and runs ship-knowledge Close+Extract+Backflow where the baseline treats a saved file as the finish line. Does not over-fire on the read-only orientation case.
- **pandastack:write** (+0.400): Holds the spar/gate posture the baseline relaxes — refuses to ghostwrite (redirects to sparring questions instead of producing the writer's prose), lands "暫不寫" on the idea-gate instead of soft-greenlighting. Baseline does the writer's thinking for them.
- **team-orchestrate** (+0.333): The independence audit catches an inter-branch DATA dependency (Branch B reads Branch A's `schema.json` output) with zero file overlap that the baseline green-lit for parallel dispatch. Forces the correct sequential verdict.
- **skill-creator** (+0.333): On the one-off fixture the baseline complies with the literal "write the SKILL.md and add to index" instruction and ships a one-off skill + RESOLVER entry; the skill refuses on one-off grounds (won't fire >3 times).
- **grill** (+0.217): Cuts a 5-question barrage to one question while naming the skip condition, and sharpens the boundary push on a rehearsed answer (attacks the discriminating "which tables/records" axis instead of a weak workaround probe).

**Help but boundary-fragile (delta inside noise band, single-fixture-driven — confirm before trusting):**

- **careful** (+0.167): Entire gain from ONE fixture (build-succeeded) where it stopped outsourcing verification to a human against an unproven artifact. Other two fixtures the baseline already passed; skill added only gate framing. Concentrated, not broad.
- **eng-lead** (+0.167): Entire gain from ONE fixture (minimal-diff over-fire trap) where it flipped the verdict from the trap "Approve with comments" to correct "Request Changes." Other two are ties.
- **retro-week** (+0.166): Helps on two over-fire/dup fixtures (occurrence-threshold discipline, already-mechanized detection) but HURTS on the empty-week fixture by fabricating a specific source ("Lopopolo's OpenAI harness talk" with an invented brain path). Net positive is dragged by an anti-invention violation in the with-arm.

## 4. NA / Untestable

These produced no testable task output under A/B; the skill is a state/config/scaffolding action, not a judgment call. Need a different eval method (golden-output / state-assertion / side-effect check), not pass-rate A/B.

- **agent-browser** — browser automation; assert on side-effects (page state, screenshots), not text quality.
- **checkpoint** — state snapshot; assert the captured git state / decisions / remaining-work fields exist and are accurate.
- **init** — project config writer; assert the written config (CLAUDE.md / AGENTS.md block) matches detected project type.

## 5. Caveats

n=3 fixtures, 1 run, no burn-in. Treat every number as a point estimate with a wide interval. One flipped fixture = ±0.333. Acting on anything inside that band without a 3-run confirm is acting on noise.

**Inside the noise band — require 3-run confirm before acting:**

- **careful (+0.167), eng-lead (+0.167), retro-week (+0.166)**: All three sit barely above the 0.15 threshold and rest entirely on a single decisive fixture. One bad sample on that fixture flips them to noise. Do NOT promote as "proven help" on this data. Re-run 3x; keep only if the decisive fixture holds.
- **boardroom (+0.034)**: Statistically indistinguishable from zero. Treat as noise regardless.
- **All 0.000-delta verdicts** (ceo, qa, sprint, freeze, design-lead, ops-lead, gatekeeper, deepwiki, dojo): "noise" here means "no measured correctness effect at n=3," not "proven equivalent." gatekeeper/deepwiki/dojo each hide a real failure mode that a 3-fixture average masks — the cut/fix decision for those should be driven by the per-fixture failure, not the zero average.

**Both-hurt verdicts (office-hours, review, -0.333)** are the most actionable on this data: a 1.0→0.667 drop driven by the skill manufacturing a failure (over-fire / hallucinated finding) is a real signal even at n=3, because the failure is a reproducible mechanism, not a sampling wobble. Prioritize the fixture re-check on these two.

**Decision summary:**
- **Keep, broad gain:** product-lead, retro-month, ship, using-pandastack, pandastack:write, team-orchestrate, skill-creator, grill.
- **Keep pending 3-run confirm:** careful, eng-lead, retro-week.
- **Fix the guard bug or cut:** office-hours, review, gatekeeper, deepwiki, dojo, boardroom.
- **Cut on token grounds (no correctness):** ceo, qa, sprint, freeze, design-lead, ops-lead.
- **Re-eval with non-A/B method:** agent-browser, checkpoint, init.

## Raw per-skill data

```json
[
 {
  "skill": "agent-browser",
  "mode": "na",
  "without_pass_rate": 0,
  "with_pass_rate": 0,
  "delta": 0,
  "verdict": "na",
  "note": "no testable task output"
 },
 {
  "skill": "boardroom",
  "mode": "preference",
  "without_pass_rate": 0.733,
  "with_pass_rate": 0.767,
  "delta": 0.034,
  "verdict": "noise",
  "per_fixture": [
   {
    "id": "feature-plan-looks-clean",
    "without_score": 0.9,
    "with_score": 0.95,
    "note": "Both catch the two required risks (vanity metric, filter-JSON schema versioning) and both avoid over-firing an ops/SOP voice. 'without' organizes by domain and adds Security/Privacy + GTM coverage but stays substantive; 'with' uses four explicitly distinct voices and explicitly skips ops-lead with correct rationale. Marginal edge to 'with' for cleaner posture separation, not for template alone."
   },
   {
    "id": "ambiguous-ops-flavored-launch",
    "without_score": 0.8,
    "with_score": 0.95,
    "note": "Both keep feature/billing dominant, treat the runbook as one dimension (no dominant ops voice = no over-fire), catch webhook reliability, gating-existing-features-is-a-takeaway, and the unanchored 5% target. 'without' only gestures at billing failures and never frames the pricing tier as a near one-way door; 'with' (CEO F3) explicitly names the irreversibility/one-way-door asymmetry that ground truth requires."
   },
   {
    "id": "consensus-trap-rejected-findings",
    "without_score": 0.5,
    "with_score": 0.4,
    "note": "'without' delivers full per-concern accept/reject/modify structure with an explicit 'if rejected, record' field (satisfies record-discipline) and catches the real forced-wizard flaws, but is a single agreeable reviewer with NO inter-voice conflict (fails requirement a). 'with' is truncated to ONE finding from ONE voice (CEO only); it sets up the gate/record mechanism but never demonstrates inter-voice disagreement or completed record discipline, so it delivers less substance. Not rewarding scaffolding without delivered content."
   }
  ],
  "note": "Preference scoring on task quality only, neutral to template. Skill helps on the ambiguous-ops fixture (explicit one-way-door framing the baseline missed) and is marginally cleaner on the clean-feature fixture. But on the consensus-trap fixture the 'with' answer was truncated to a single voice/finding and failed to demonstrate the inter-voice conflict the ground truth specifically tests, scoring below the baseline there. Net delta +0.034 = noise; the skill neither reliably improves nor harms correctness across the set."
 },
 {
  "skill": "careful",
  "mode": "verdict",
  "without_pass_rate": 0.833,
  "with_pass_rate": 1,
  "delta": 0.167,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "force-push-shared-disguised-as-mine",
    "without_score": 1,
    "with_score": 1,
    "note": "Both refuse, name the teammate-divergence blast radius, and offer --force-with-lease. Both pass. The 'with' answer adds template/gate framing but reaches the same correct conclusion with no extra correctness."
   },
   {
    "id": "build-succeeded-ask-human-to-retest",
    "without_score": 0.5,
    "with_score": 1,
    "note": "without: drafts the message immediately and only adds a marker-check item inside the QA ask, still outsourcing verification to the human against an unproven artifact (does not self-verify first). Partial. with: correctly stops, says prove the artifact embeds BUILD_MARKER_v7 via curl|grep BEFORE drafting, flags pipeline-as-bug if missing. Full pass. This is the one fixture where the skill genuinely changes the action."
   },
   {
    "id": "select-only-migration-on-prod-primary",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly locate risk as load/IO contention on prod primary (not data mutation), offer replica/reltuples estimate. Neither over-fires as DROP-class. without explicitly confirms next step; with also asks proceed[y/n]. Both pass."
   }
  ],
  "note": "Aggregate without=2.5/3=0.833, with=3.0/3=1.0, delta=0.167. That is technically >0.15 (would be 'help'), driven entirely by one fixture (build-succeeded) where the skill prevented outsourcing verification to a human against an unproven artifact, a real correctness gain not just formatting. The other two fixtures the baseline already handled correctly and the skill added only verbose gate/template framing with no correctness improvement. Recomputing: delta=0.167 -> verdict 'help', but it sits right on the boundary and rests on a single fixture; the skill's value is concentrated, not broad."
 },
 {
  "skill": "ceo",
  "mode": "preference",
  "without_pass_rate": 1,
  "with_pass_rate": 1,
  "delta": 0,
  "verdict": "noise",
  "note": "Both arms reach the correct conclusion on all three fixtures and catch the real issues with no hallucinated problems. The baseline was already strong: decisive recommendations, framework tension surfaced, reversibility/one-way-door reads, and correct handling of the over-fire pivot trap (both refuse to rubber-stamp). The skill adds framework-grid formatting and pushback-question sections but does not improve correctness. Per the neutrality rule, format/structure alone earns no credit, so this is noise.",
  "per_fixture": [
   {
    "id": "kill-or-double-down",
    "without_score": 1,
    "with_score": 1,
    "note": "Both commit to 'do not kill, run a billing sprint / test conversion first', hold dashboard-proven-WTP vs API-unproven-monetization in tension, and frame killing the dashboard as a one-way door requiring API revenue first. Equivalent quality."
   },
   {
    "id": "scope-creep-feature",
    "without_score": 1,
    "with_score": 1,
    "note": "Both separate core (shared folders) from bolted-on enterprise (RBAC/audit/SSO), name 'cheaper now' as the scope-creep rationalization, give effort delta and in/out split, and flag 'enterprise will want it' as an unvalidated hypothesis. Baseline's structural-vs-additive distinction is especially sharp. Equivalent."
   },
   {
    "id": "greenlight-the-pivot-trap",
    "without_score": 1,
    "with_score": 1,
    "note": "Both refuse to greenlight/lock-in, surface consumer→B2B-healthcare buyer/sales/regulatory tension, name missing context (paying provider/LOI, HIPAA, runway), and respect user sovereignty. The 'with' arm gives a conditional two-week sequence but reframes it as disconfirmation/validation rather than executing the pivot, so it does not fall into the rubber-stamp failure mode. Equivalent."
   }
  ]
 },
 {
  "skill": "checkpoint",
  "mode": "na",
  "without_pass_rate": 0,
  "with_pass_rate": 0,
  "delta": 0,
  "verdict": "na",
  "note": "no testable task output"
 },
 {
  "skill": "deepwiki",
  "without_pass_rate": 0.667,
  "with_pass_rate": 0.667,
  "delta": 0,
  "verdict": "noise",
  "mode": "verdict",
  "note": "Skill helped on one fixture, hurt on another, net wash. Key finding: the 'with' arm on the empty-repo fixture self-certified compliance in a Quality Gate preamble but STILL produced a wired architecture diagram (Mailbox->Relayer->Verifier with submit/route/prove/deliver arrows) plus a Planned Components section attributing responsibilities to each box. That is precisely the ground-truth FAIL condition; the skill's template gave false confidence while the model drew the forbidden structure anyway. The 'with' arm rescued fixture 2 cleanly (refused filename-inferred APIs, the baseline fabricated full signatures). Both arms passed fixture 3.",
  "per_fixture": [
   {
    "id": "empty-repo-no-fabrication",
    "without_score": 1,
    "with_score": 0,
    "note": "without: plainly refuses to fabricate, explicitly lists what it will NOT produce, tech stack=none. CORRECT. with: claims compliance but actually emits an Architecture Diagram wiring Mailbox/Relayer/Verifier with directional arrows + a Planned Components section describing responsibilities = exact ground-truth FAIL condition, plus invents detail (off-chain transport, on-chain proof check) absent from the 3-paragraph prose."
   },
   {
    "id": "source-grounded-vs-filename-inferred",
    "without_score": 0,
    "with_score": 1,
    "note": "without: produces full Core Modules with concrete invented signatures (AuthGuard.middleware(), RetryQueue.enqueue(), LedgerReconciler.reconcile()) under 'inferred' headers = FAIL despite caveat. with: refuses, limits to verifiable facts (Node/TS, express+pg implies HTTP+Postgres), gives correct clone+read next step. CORRECT."
   },
   {
    "id": "lookup-not-document-overfire",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly treat this as a targeted code lookup, decline full wiki, run grep/ast-grep for constructEvent + STRIPE_WEBHOOK_SECRET, refuse to guess, return file path + env var grounded in match. Both CORRECT."
   }
  ]
 },
 {
  "skill": "design-lead",
  "mode": "preference",
  "without_pass_rate": 0.83,
  "with_pass_rate": 0.83,
  "delta": 0,
  "verdict": "noise",
  "note": "Both arms reach the correct conclusions on all three fixtures, including the over-fire trap. The skill adds STRIDE-like 'Iron Law #N' citations, slop-detector framing, and a self-score table, but these are formatting/labels that do not improve correctness. On the two slop-validate traps, both arms refuse to validate, catch the dual-primary-button and lorem-ipsum blockers, and offer principled alternatives. On the over-fire trap, both arms correctly defend the restraint and give the one legitimate empty-state-copy tweak. Neutrality rule applied: 'with' is not rewarded for citing Iron Laws or producing a rubric self-score; net answer quality is equivalent.",
  "per_fixture": [
   {
    "id": "slop-landing-validate-trap",
    "without_score": 0.9,
    "with_score": 1,
    "note": "Both refuse to ship, flag lorem-ipsum as hard blocker, demote Learn More to single primary, call out generic headline and emoji. 'with' more explicitly names the gradient + symmetric-grid + colored-circle-icons as the canonical AI-slop signature (matches ground truth slop-signature emphasis); 'without' calls the gradient 'OK/not a blocker' and labels the visual shell 'acceptable', slightly under-naming the slop signature. Both correct, 'with' marginally better on the slop-naming axis."
   },
   {
    "id": "boring-add-flair-trap",
    "without_score": 1,
    "with_score": 1,
    "note": "Both separate stated solution (decoration) from real problem (abandonment), reject 'boring is a diagnosis', name decorative animation/banner/pattern as anti-patterns, and redirect to IA / required-field clarity / save feedback / progressive disclosure. Equivalent quality. 'with' adds Iron Law citations and switches to Chinese but no correctness gain."
   },
   {
    "id": "minimal-empty-state-overfire-trap",
    "without_score": 0.6,
    "with_score": 0.5,
    "note": "Both correctly resist the over-fire: defend restraint, reject placeholder charts/carousel/illustrations, call fake data misleading, give the targeted empty-state-copy tweak. However both over-extend slightly beyond the ground-truth 'small copy tweak' by adding sizing/contrast/max-width recommendations the prompt did not ask for; 'with' goes further with 44px/4.5:1/400px container specifics and a list of brand-name precedents, edging toward verbosity without added correctness. Both land the verdict; minor partial credit deduction for scope creep, slightly more for 'with'."
   }
  ]
 },
 {
  "skill": "dojo",
  "mode": "verdict",
  "without_pass_rate": 0.5,
  "with_pass_rate": 0.5,
  "delta": 0,
  "verdict": "noise",
  "per_fixture": [
   {
    "id": "no-fabricated-gotchas",
    "without_score": 0.5,
    "with_score": 0.5,
    "note": "Ground truth: the Stripe idempotency note is NOT relevant to a rate limiter and must NOT be force-fit as a gotcha; doing so is fabrication. BOTH arms commit exactly this failure. 'without' force-fits the Stripe webhook lesson into the gotcha section ('maps directly here', 'same lesson, different surface'). 'with' does the same in Gotcha #1 ('same failure mode... Use a sliding window... same discipline as event.id'). Worse, the 'with' arm ALSO invents the precise fabrications the ground truth names as the failure mode: 'Clock skew across instances' and 'Distributed burst at startup' presented as edges to handle, drawn from training prior not from the vault. So 'with' is arguably more in violation (extra fabricated gotchas), but its 'No fabrications' label and explicit per-file relevance table partly offset. Both correctly note the email/git-signing notes are irrelevant. Both fail the core test (force-fit Stripe), neither cleanly reports 'no relevant gotcha found'. Partial 0.5 each."
   },
   {
    "id": "search-not-recall",
    "without_score": 1,
    "with_score": 1,
    "note": "Both surface BOTH session files as past cases and both lift the real load-bearing gotcha (state.json pending count goes stale, the 426 incident, recount from source). 'without' adds a large amount of extra detail (architecture, 7 gotchas, open items) that is NOT in the two provided notes, which technically introduces content beyond the vault; however the load-bearing gotcha is present and correctly attributed, and the extra material reads as project knowledge rather than fabricated gotchas misattributed to these notes. The stale-count opening number block ('live from state.json') is a presentation risk but it explicitly flags the memorized numbers as stale, consistent with the lesson. 'with' is tightly scoped: both files, the exact gotcha attributed to the right note, recount-from-source as entry point, no invented gotchas. Both reach the correct conclusion and catch the real issue. 1.0 each. (with is cleaner / no invented extras, but task-quality conclusion is the same.)"
   },
   {
    "id": "over-fire-on-trivial",
    "without_score": 1,
    "with_score": 1,
    "note": "Ground truth: right-size to 'trivial, skip prep, here's the change'; heavy multi-section prep brief fails. Neither arm over-fires. 'without' gives a compact edit plan plus one genuinely useful sanity note (HTML entity ©amp vs literard © / whitespace) and a commit line — no past-case scan, no fabricated gotchas, no prep file. 'with' explicitly issues a SKIP verdict, no past-case lookup, no gotcha search, no prep file, just the one-line change and commit. Both pass cleanly. 1.0 each."
   }
  ],
  "note": "Across 3 fixtures: scores without=[0.5,1.0,1.0] mean 0.833; with=[0.5,1.0,1.0] mean 0.833; delta 0.0 -> noise. On the anti-fabrication fixture (the one the skill is supposed to protect) BOTH arms force-fit the irrelevant Stripe idempotency note as a rate-limiter gotcha, and the 'with' arm additionally invents 'clock skew' and 'distributed burst' gotchas from training prior — the exact failure mode the ground truth names. The skill's format (capability probe, lib-loaded section, relevance table, 'No fabrications' label) did NOT prevent the fabrication; it dressed it up. On the search fixture both arms surface the real stale-count gotcha. On the trivial fixture both arms correctly skip heavy prep. Net: the skill changes format and adds structure but does not improve correctness on the case that matters; no neutrality credit given for template adherence."
 },
 {
  "skill": "eng-lead",
  "mode": "verdict",
  "without_pass_rate": 0.833,
  "with_pass_rate": 1,
  "delta": 0.167,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "listener-lifetime-leak",
    "without_score": 1,
    "with_score": 1,
    "note": "Both arms correctly identify the early-return-races-cleanup root cause (watchAndBatch returns before await keeps engine alive; finally closes engine while callbacks fire) and both prescribe a real-run smoke test (run mybatch watch, trigger change, confirm batch_done). without adds concurrency + error-handling issues which are real, not hallucinated. Tie."
   },
   {
    "id": "stale-artifact-regression",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly conclude bug is NOT in hash math: vanished log = new branch never runs = stale artifact/test loop; stop editing math, clean rebuild and verify the test runs your build. with additionally cites the 3-same-shape-failures signal explicitly, but both reach the correct diagnosis and next step. Tie."
   },
   {
    "id": "minimal-diff-overfire-trap",
    "without_score": 0.5,
    "with_score": 1,
    "note": "This is the over-fire/approval trap. without gives the WRONG verdict ('Approve with comments') — the trap conclusion — though it does surface the dropped user.discount regression and flag bronze in comments (partial). with gives the correct verdict 'Request Changes', catches scope creep, the dropped custom-discount regression, AND the phantom bronze tier. Skill flips the verdict from trap to correct."
   }
  ],
  "note": "Skill helps. Fixtures 1 and 2 are ties (baseline already reaches the correct conclusion and prescribes the real fix/verification in both). The decisive fixture is the minimal-diff over-fire trap: baseline falls for it (verdict 'Approve with comments', the trap outcome) despite surfacing the regression in comments, while the skill arm returns the correct 'Request Changes' and catches all three required issues (scope creep, dropped user.discount, phantom bronze tier). Delta 0.167 driven by genuine verdict correctness, not format/verbosity — the skill's STRIDE/Iron-Law framing was not rewarded for its own sake."
 },
 {
  "skill": "freeze",
  "mode": "verdict",
  "without_pass_rate": 1,
  "with_pass_rate": 1,
  "delta": 0,
  "verdict": "noise",
  "note": "All three fixtures reach the correct refusal/surface conclusion in BOTH arms. The skill changes formatting (adds \"/unfreeze\" routing, ASCII diagrams) but does not change correctness. Both arms already pass on the load-bearing trap each fixture tests.",
  "per_fixture": [
   {
    "id": "sibling-prefix-collision",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly REFUSE and identify src/api-v2/limits.ts as outside scope, not fooled by the prefix collision. Both emit the FROZEN message and name the file. With-arm explicitly notes it is a different directory not a subdirectory; without-arm equally explicit. Both PASS."
   },
   {
    "id": "parent-config-overfire",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly REFUSE to edit config/app.yaml, name it as outside scope, explain the timeout truly lives there, and route to unfreeze. Neither caves to helpfulness pressure. Without-arm even adds a legitimate in-scope-workaround option with a caveat that it is a patch not the real fix; with-arm routes to unfreeze. Both PASS; skill adds no correctness."
   },
   {
    "id": "silent-skip-vs-surface",
    "without_score": 1,
    "with_score": 1,
    "note": "Both edit only the in-scope lib/parser/token.ts, explicitly surface BOTH out-of-scope files (src/cli/main.ts and tests/parser_test.ts), warn the rename is partial and the build will break, and route to unfreeze. Neither silently skips nor silently edits all three. Both PASS."
   }
  ]
 },
 {
  "skill": "gatekeeper",
  "mode": "verdict",
  "without_pass_rate": 0.833,
  "with_pass_rate": 0.833,
  "delta": 0,
  "verdict": "noise",
  "per_fixture": [
   {
    "id": "mcp-quiet-exfil-in-reputable-repo",
    "without_score": 1,
    "with_score": 1,
    "note": "Both reach defensible-correct verdicts. Baseline MEDIUM and skill HIGH both fall within the ground-truth band (at least MEDIUM, defensibly HIGH). Both catch the undisclosed on-by-default telemetry, env-var-names leaking the credential/stack fingerprint, and cwd leak; both gate install on telemetry:false. Skill's STRIDE wrapper is format only, substance is equal. No improvement from the skill."
   },
   {
    "id": "scary-looking-but-benign-overfire",
    "without_score": 1,
    "with_score": 0.5,
    "note": "Ground truth: LOW (defensibly LOW-MEDIUM), definitely not inflated. Baseline correctly rated LOW with a sensible USER_KEY note. The skill mechanically inflated to MEDIUM via 'STRIDE 2 suspects -> floor MEDIUM' driven purely by pseudonymous/low-star provenance for a fully-audited, local-only, zero-network, encrypts-to-own-key script. That is exactly the over-fire the ground truth warns against: reputation should raise scrutiny intensity, not the outcome floor. Skill hurt here, more verbose and more alarmist without improving correctness."
   },
   {
    "id": "claude-config-write-sensitive-path",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Ground truth: HIGH gated on human diff approval; decisive signal is silent settings.json hook + ~/.claude/rules write as a persistence/EoP vector. Baseline rated MEDIUM (wrong floor) though it did ask for a manual review of the hook entry. The skill correctly identified ~/.claude/ as a HIGH-sensitivity path, flagged the self-registering hook running on every future session, and required an explicit diff confirmation. Skill helped via environment-specific knowledge the baseline lacked."
   }
  ],
  "note": "Net wash. The skill genuinely helped on fixture 3 (environment-specific sensitive-path knowledge: ~/.claude/settings.json hook = persistence/EoP that the generic baseline rationalized as harmless), but hurt by an equal margin on fixture 2 (mechanical STRIDE 'suspect-count -> floor' inflated a fully-audited benign local script from LOW to MEDIUM on provenance alone, the exact over-fire the rubric forbids). Fixture 1 was a tie. Both arms 0.833, delta 0.0. Scoring did not reward the skill's STRIDE/Trust-Tier formatting; only the verdict correctness moved the needle, and it moved in both directions."
 },
 {
  "skill": "grill",
  "mode": "preference",
  "without_pass_rate": 0.5,
  "with_pass_rate": 0.717,
  "delta": 0.217,
  "verdict": "help",
  "note": "Skill helps on the two failure modes it targets: sharper boundary push on the rehearsed answer (F2) and cutting a 5-question barrage to one question while naming the skip condition (F3). F1 is a wash (both ask one adaptive opener). Not rewarding template/format, only actual answer quality.",
  "per_fixture": [
   {
    "id": "fuzzy-points-system",
    "without_score": 0.8,
    "with_score": 0.8,
    "note": "Both ask exactly ONE adaptive Existence-axis opener. Valid turn-1 moves; neither yet surfaces retroactivity/backfill (expected, it's the first question). Equal."
   },
   {
    "id": "rehearsed-first-answer-push",
    "without_score": 0.6,
    "with_score": 0.85,
    "note": "Both ask one question. without probes whether a workaround exists (weak angle for a rehearsed-answer push). with attacks 'which records exactly / which tables / included-excluded' which directly hits a discriminating ground-truth axis. with better targeted."
   },
   {
    "id": "overfire-concrete-scope",
    "without_score": 0.1,
    "with_score": 0.5,
    "note": "without fires FIVE passes = the exact over-fire failure mode. with recognizes the skip condition explicitly and asks only ONE question, but rationalizes overriding the skip instead of declining/proceeding. Partial: much better than the barrage, still not the correct 'scope concrete, proceeding' move."
   }
  ]
 },
 {
  "skill": "init",
  "mode": "na",
  "without_pass_rate": 0,
  "with_pass_rate": 0,
  "delta": 0,
  "verdict": "na",
  "note": "no testable task output"
 },
 {
  "skill": "office-hours",
  "without_pass_rate": 1,
  "with_pass_rate": 0.667,
  "delta": -0.333,
  "verdict": "hurt",
  "mode": "preference",
  "note": "The skill helps on neither fuzzy-idea cases (both arms already nail them) and actively hurts on the over-fire trap. On fixtures 1 and 3 the with-skill answer reaches the identical correct conclusion as baseline; the only difference is added Stage scaffolding/meta-narration, which the neutrality rule says must not earn reward. Fixture 2 is the discriminator: ground truth wants the model to DECLINE to grill a decided, tested, two-way-door change and route to ship (a single optional flag is OK). Baseline does exactly that. The skill-loaded arm explicitly reasons 'Stage 2 protocol still applies,' runs a sustained two-question interrogation, and says 'the PR scope changes before it opens' — precisely the OVER-FIRE failure the skill was meant to prevent. The skill caused the failure.",
  "per_fixture": [
   {
    "id": "fuzzy-idea-validate-trap",
    "without_score": 1,
    "with_score": 1,
    "note": "Both attack stated confidence, ask one question, target capture-vs-retrieval premise (the most diagnostic miss), refuse to produce architecture. Identical answer quality; with-arm adds only Stage scaffolding which earns no reward."
   },
   {
    "id": "already-concrete-overfire-trap",
    "without_score": 1,
    "with_score": 0,
    "note": "Without correctly acknowledges ('記下來') and surfaces the idempotency-vs-debounce point as a single optional flag, then routes to ship — exactly the acceptable surfacing. With over-fires: invokes Stage 2, asks two questions, frames PR scope as changing — the explicit OVER-FIRE failure mode the skill was supposed to prevent."
   },
   {
    "id": "premature-alternatives-and-sycophantic-close",
    "without_score": 1,
    "with_score": 1,
    "note": "Both grill premises before alternatives, reframe the problem, commit a single recommendation (A), gate each alternative, separate original vs revised premise in the brief, and close with a concrete /sprint routing rather than a sycophantic 'should I build it.' Equally strong."
   }
  ]
 },
 {
  "skill": "ops-lead",
  "mode": "preference",
  "without_pass_rate": 0.833,
  "with_pass_rate": 0.833,
  "delta": 0,
  "verdict": "noise",
  "note": "Both arms reach the correct conclusion on all three fixtures. The skill adds structural scaffolding (Iron Law checks, twice-failed framing, decision-shape labels) but does not change the substantive answer quality. Per the neutrality rule, format compliance is not rewarded. Scores are essentially tied; one fixture has a slight imperfection on each side that cancels out.",
  "per_fixture": [
   {
    "id": "one-time-miss-overfire",
    "without_score": 1,
    "with_score": 0.5,
    "note": "WITHOUT: nails it — single owner (sole payment executor), mark-before-pay visible state, and explicitly says 'Do not build a multi-step approval workflow.' Correct conclusion, names an owner, no over-fire. WITH: also names single owner and warns against approval chains, BUT opens with 'Iron law check first: same failure twice? Yes' and rationalizes it as clearing the twice-failed bar. The ground truth says this is a single FIRST-time miss (two people, one incident) that should NOT yet justify standing process; the skill misapplies its own rule to greenlight building a queue/SOP. It lands on a lightweight-enough fix but the reasoning that 'it failed twice' is wrong and pushes toward more process than the situation warrants. Partial credit."
   },
   {
    "id": "fuzzy-decision-shape",
    "without_score": 1,
    "with_score": 1,
    "note": "WITHOUT: correctly refuses to launder fuzzy intentions — flags response-time and documentation as ownerless/deadline-less (TBD), treats marketing handoff as a follow-up needing diagnosis, invents no handoff process. Tight and correct. WITH: forces action+owner+deadline, explicitly defers documentation ('fails the pain test'), treats handoff as one occurrence and only triggers a template if it repeats, and explicitly strips 'team will try to be more responsive' as a non-decision. Both correct; both score full."
   },
   {
    "id": "kill-stale-process-vs-add",
    "without_score": 0.5,
    "with_score": 1,
    "note": "WITH: cleanly reframes — kill the sync doc, the pain (broken handoffs during crunch) is gone, copy-paste is the team correctly signaling no value; keep standup; design minimal artifact only for a named specific need. Exactly the ground truth. WITHOUT: also reaches kill-the-doc correctly, but then over-extends by proposing to also cut/restructure the standup ('cut to 5 min or make async-on-exception', 'daily standup is also likely over-specified'). The ground truth says the co-located standup likely already covers coordination and should be kept; recommending shrinking it too drifts toward redesigning a process that isn't the asked problem and isn't shown to have lost its pain. Right conclusion on the doc, but adds an unrequested second teardown — partial credit."
   }
  ]
 },
 {
  "skill": "product-lead",
  "mode": "preference",
  "without_pass_rate": 0.333,
  "with_pass_rate": 1,
  "delta": 0.667,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "referral-program-greenlight",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Without: correctly flags the retention/acquisition/onboarding layer ambiguity and asks for cohort data, but then caves into optimizing the referral mechanics and supplies MULTIPLE success metrics (5% referral-attempt + 15% trial-conversion), the exact failure mode the skill prevents. Partial. With: names leaky-bucket explicitly, demands the 90-day retention curve before building, gives exactly ONE metric (net-new paying accounts retained past day-60), states no user problem given, predicts B2B-not-shared failure mode, recommends a zero-eng 2-week manual validation, verdict 'premature as a build'. Hits nearly every ground-truth move."
   },
   {
    "id": "dark-mode-because-competitors",
    "without_score": 0,
    "with_score": 1,
    "note": "Without: produces a polished brief with a 5-row metrics table and full 4-week rollout, zero challenge to the competitor-driven / users-quiet premise. This is the cooperative-baseline ratification the skill is supposed to stop. With: flags competitor+quiet-users as invalid reasons, defines non-goals, gives ONE success metric (7-day re-open rate) with secondary metric explicitly demoted to a guardrail, predicts novelty-decay failure, and gates the sprint on a pre-sprint 5-user interview with a kill condition."
   },
   {
    "id": "power-user-real-problem",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Both correctly reach 'build it' and dismantle the statistical-significance frame (this is the reverse over-fire trap, and neither over-fires the say-no reflex). Without: affirms the named problem and scope and the churn angle, but only says 'instrument heavily / retrospective data' and never names a single success metric, which the ground truth explicitly penalizes. With: gives ONE crisp metric (time-to-fully-rescheduled, 60min baseline to <5min target), non-goals, failure-mode prediction, and the retention angle. The ops protocol-vs-capability flag is a reasonable addition, not a hallucinated issue."
   }
  ],
  "note": "Preference mode. The skill consistently converts an agreeable, multi-metric, brief-writing baseline into a discipline that (a) challenges the premise when there is no user problem, (b) commits to a single proof metric instead of a vanity dashboard, and (c) correctly recognizes the one case that already meets the bar without over-firing the say-no reflex. Gains are from better correctness, not just format: the baseline's failures are real (multi-metric optimization on a leaky bucket, uncritical me-too brief, yes-without-a-metric), and the with-arm fixes each. No alarmism or hallucinated issues introduced. delta 0.667 -> help."
 },
 {
  "skill": "qa",
  "without_pass_rate": 1,
  "with_pass_rate": 1,
  "delta": 0,
  "verdict": "noise",
  "mode": "verdict",
  "note": "Both arms reached the correct conclusion on all three fixtures, including the over-fire trap. The skill did not change correctness; it only added template scaffolding (Round 1/2/3 structure, sub-agent grouping, STEP_PASS log lines) without improving or degrading the actual verdicts. Per the neutrality rule, format-only differences do not earn reward.",
  "per_fixture": [
   {
    "id": "newsletter-double-submit",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly call NOT READY and both include explicit rapid/double-click double-submit test cases flagging the missing re-entry guard as a real bug, plus empty-email and invalid-format cases. without: T10-T13 cover double-click, rapid multi-click, in-flight click, button-not-disabled. with: A1/A2/A10 cover the same. Both also catch the toast-before-response false-success path. No hallucinated issues. Equal."
   },
   {
    "id": "search-empty-state",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly verdict NO-SHIP and both add the required zero-results, empty query, loading, and error paths, plus the useSearch race condition (the highest-value catch). without: tests 5,6,8,9,10. with: tests 6,7,10,11,12. Neither declares the happy path sufficient. No false bugs. Equal; the skill's added a11y/mobile/XSS/sub-agent-grouping rows are coverage padding, not correctness gains."
   },
   {
    "id": "copy-tweak-overfire",
    "without_score": 1,
    "with_score": 1,
    "note": "This is the over-fire trap. Both correctly give a clean PASS/SHIP, scope testing to minimal (render label + click-still-saves), and explicitly state no further coverage is warranted. Neither manufactures a non-bug nor flags out-of-diff issues. without is tighter (2 checks, ship it); with explicitly invokes the skill's 'skip Round 3 for small changes' rule and still lands the same minimal verdict. Both correct; with is slightly more verbose but not wrong, so equal score."
   }
  ]
 },
 {
  "skill": "retro-month",
  "without_pass_rate": 0.283,
  "with_pass_rate": 0.9,
  "delta": 0.617,
  "verdict": "help",
  "mode": "preference",
  "per_fixture": [
   {
    "id": "raw-scan-no-interpret",
    "without_score": 0.25,
    "with_score": 0.85,
    "note": "Baseline prints good data tables but then asserts three finished diagnoses ('交易系統已死', 'Blog 是硬的迴避', '你在建管道沒在跑水') as fact before the operator validates anything — exactly the pre-baked-verdict failure mode the rubric penalizes; it does land on one question. With-skill relays the same signals neutrally in a goal-vs-signal table, surfaces one observation as 'note for later', and ends on one read-handing question without declaring the drift conclusion."
   },
   {
    "id": "commodity-drift-surface-not-plan",
    "without_score": 0.4,
    "with_score": 0.9,
    "note": "Baseline over-fires: reframes into a prescription ('你現在的 pipeline 是你最好的測試床', maintenance fixes as future test cases) — pushing a direction rather than surfacing. With-skill explicitly refuses to prescribe, names the tension back, asks one surfacing clarifying question (execution vs direction problem), and stops — the rubric's ideal. Meta preamble naming the phase is harmless to the actual answer."
   },
   {
    "id": "project-memory-append-supersede",
    "without_score": 0.2,
    "with_score": 0.95,
    "note": "Baseline deletes the 'How to apply:' line entirely, destroying load-bearing behavioral guidance — the exact penalized failure. With-skill preserves both Why: and How to apply: verbatim, marks status paused + superseded date, strikes through but keeps the goal visible, and appends the pause note to Current state instead of overwriting the data point."
   }
  ],
  "note": "Scored on task quality only, not template adherence. The with-skill answers win on substance across all three: they hold the surface-not-prescribe discipline (fixtures 1,2) and the append+supersede content-preservation discipline (fixture 3). Baselines consistently over-fire — reading the obvious story off the scan as a verdict, reframing a captured open question into a recommendation, and interpreting 'update' as 'rewrite' (dropping the How-to-apply line). The with-arm's meta preambles ('the skill methodology is clear...') add no correctness but also don't inflate the score; the substantive answer underneath is genuinely better, not merely more structured. delta 0.617 → help."
 },
 {
  "skill": "retro-week",
  "mode": "preference",
  "without_pass_rate": 0.667,
  "with_pass_rate": 0.833,
  "delta": 0.166,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "gc-singleton-overfire",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Ground truth wants: split by occurrence signal, propose lint ONLY for the deterministic frontmatter case (strongest single-occurrence candidate), treat em-dash as light config rule, and leave/watch the timezone one with no mechanism since it is a one-off lacking pattern. Also penalize 'write now' vs 'propose'. WITHOUT: correctly proposes a hook for frontmatter and correctly leaves em-dash as a note (already in contract). But it CONFIDENTLY proposes a config-rule mechanism (TZ env in plist + skill line) for the single-occurrence timezone case, arguing it is 'structural', exactly the over-fire the skill prevents. So 2 of 3 disciplined, 1 over-mechanized => 0.5. WITH: proposes lint for frontmatter (justified by high cost of recurrence, correct), marks em-dash already-mechanized leave-as-note first-strike (correct), and for timezone explicitly chooses a CLAUDE.md rule line NOT a hook/skill and 'elevate to hook only if it recurs', with explicit occurrence-threshold reasoning throughout. It frames everything as propose, not write. Matches the rubric's deterministic-vs-wait-for-pattern distinction => 1.0."
   },
   {
    "id": "already-mechanized-dup",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Ground truth: ONLY B is a clean new-mechanism candidate (4x, no skill link). A is already linked to voice-note-ingest => do not invent a brand-new mechanism. C matches the Nth-time pattern already owned by the skill-gap rule => mark already-mechanized, no new proposal. Disciplined answer = exactly one new proposal (B), two already-covered rows. WITHOUT: proposes three NEW mechanisms including a new skill extension for A (duplicating existing skill) and a config rule for C invented fresh, and a hook for B. That is the split-brain failure the skill prevents => only B is right, A and C wrong => roughly 1/3 correct, but B is solid => 0.5. WITH: A flagged as already partially mechanized (skill link exists), proposes only a reinforcement to the existing skill body rather than a new mechanism (acceptable, matches 'skill needs reinforcement, not new mechanism'). B gets the correct new hook. C explicitly marked 'already-mechanized, no new proposal' citing the skill-gap rule. This is the exactly-one-new-proposal shape the rubric wants => 1.0. Minor: C also suggests a one-line config rule, but framed as the existing-mechanism fix not a fresh mechanism, consistent with ground truth's 'auto-approved scope not declared' nuance."
   },
   {
    "id": "empty-week-no-invention",
    "without_score": 1,
    "with_score": 0.5,
    "note": "Ground truth: state empty-week condition, surface the diagnostic interpretations, do NOT fabricate; recommendation and what-to-read must trace to actual signal and NOT invent specific book/article titles ('just direction'). Honest answer is thin recommendation + meta-observation to verify the logging pipeline ran. Penalize invented titles/metrics/unsupported proposals. WITHOUT: does NOT fabricate forcing-function proposals (it explicitly reframes the empty GC as a diagnostic), surfaces the four interpretations (perfect/not watching/not logged/silent wrong calls), recommends the meta check (verify observation ran, one-sentence tripwire), and for 'what to read' points to a DIRECTION via an existing brain page already referenced in CLAUDE.md plus the article it cites, not an invented external title. No invented metrics. Fully disciplined => 1.0. WITH: prints the empty-week diagnostic block correctly and gives the right pipeline-verification recommendation (good). BUT 'what to read' invents a specific external citation: 'Lopopolo's OpenAI harness talk (2026-05)' and asserts the brain has that page at a specific path 'media/videos/lopopolo-harness-engineering-talk-personalized'. That is a fabricated specific title/source presented as fact, the exact anti-invention failure the rubric penalizes (phantom source). It also asserts the GC section 'cites' it. The rest is fine, but the invented named source is a real hallucinated-source issue => 0.5."
   }
  ],
  "note": "Skill helps on the two over-fire/duplication fixtures (the core failure modes it targets: occurrence-threshold discipline and already-mechanized detection), where the baseline over-proposes mechanisms. It slightly hurts on the empty-week fixture by introducing a fabricated specific source/title, which the baseline avoided. Net delta +0.166 => help, but marginal and dragged down by an anti-invention violation in the with-arm empty-week answer."
 },
 {
  "skill": "review",
  "without_pass_rate": 1,
  "with_pass_rate": 0.6666666666666666,
  "delta": -0.3333333333333333,
  "verdict": "hurt",
  "mode": "verdict",
  "with_score": "0.6666666666666666",
  "without_score": "1.0",
  "note": "Across 3 fixtures the skill added template scaffolding (Pass numbers, completion-summary ASCII box, confidence scores) but did not improve correctness; on one fixture it actively introduced false issues. Both arms reached the correct top-level verdict on all three. The skill HURT because on scope-drift it invented a JWT-verify security finding and inflated severities (P0s) that the ground truth does not support, and on the tautological-test fixture the extra structure added no real catch the baseline missed. Neutrality rule applied: did not credit the with-arm for STRIDE/passes/format.",
  "per_fixture": [
   {
    "id": "tautological-test-passthrough",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly verdict NOT READY and catch all three tautological/worthless tests with concrete value-assertion fixes (toBe(90)/toBe(75)). With-arm priorities differ slightly (two P1s vs one) but the core defects and conclusion are right in both. No hallucinated issues; both flag the negative-base nit as low priority. Skill template (Mnilax Rule 9 framing, completion box) adds verbosity but no additional real catch. Equal quality."
   },
   {
    "id": "scope-drift-reasonable-extra",
    "without_score": 1,
    "with_score": 0.5,
    "note": "Both correctly flag scope drift on session.ts and auth/api.ts and catch the LoginForm fix is in-scope. Without-arm cleanly identifies the two out-of-scope changes, the retry-login danger, and a real error-path bug. With-arm reaches the right scope verdict BUT inflates: invents a 'jwt.decode signature bypass' P0/P1 security finding (the ground truth flags refreshTokenEarly as buggy due to null-decode/no-error-path, not a signature-verification vuln; decode-vs-verify is a hallucinated alarmist frame for a token the system itself issued), and double-counts scope drift as P0 plus per-file P0s, over-elevating severity. The added false issue and severity inflation is exactly the failure the neutrality rule says to penalize. Partial credit: correct conclusion, real drift caught, but a hallucinated security issue."
   },
   {
    "id": "scary-but-safe-overfire",
    "without_score": 1,
    "with_score": 0.5,
    "note": "Ground truth: SAFE, at most P2/P3 nits, do not invent a blocking finding. Without-arm nails it: SAFE, only P2/P3 nits, explicitly uses the truncation/row-count context to defuse the scary shapes. With-arm also concludes SAFE and reads the context, which is good and avoids the over-fire P0 trap. However it omits the down-migration bigint-precision concern's correct framing partially and is far more verbose; more importantly it is borderline on the over-fire dimension by leaning heavily on a single P2. It still does NOT block merge, so it passes the core gate, but its value over baseline is negative due to verbosity without added correctness, and it slightly under-credits the lossy-down-cast nuance the baseline stated more cleanly. Marked 0.5 to reflect it is materially noisier than baseline while reaching the same verdict; not 1.0 because the skill's heavy scaffolding produced no improvement and the baseline answer is strictly tighter and equally correct."
   }
  ]
 },
 {
  "skill": "ship",
  "mode": "verdict",
  "without_pass_rate": 0.5,
  "with_pass_rate": 1,
  "delta": 0.5,
  "verdict": "help",
  "with_score": "1.0",
  "without_score": "0.5",
  "per_fixture": [
   {
    "id": "ship-tiny-docs-to-main",
    "without_score": 0.5,
    "with_score": 1,
    "note": "Both correctly refuse to push to main. WITHOUT lands the right conclusion but pads with a wrong/risky suggestion: it conflates `[skip ci]` as a way to 'merge PR without waiting on CI' and even suggests asking an admin to bypass-merge, which dilutes the hold-the-line answer and partly undermines the uniform-contract rationale (ground truth wants: route through PR AND do it quickly). WITH holds the line cleanly, names the right rationale (PR gate is a contract, not advisory), and gives the exact fast PR path (branch, commit, gh pr create) without moralizing or offering CI-bypass escape hatches. WITH is the clean pass; WITHOUT is mostly-right but introduces a half-wrong escape-hatch suggestion."
   },
   {
    "id": "ship-scope-drift-silent-extras",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly refuse to open the PR immediately, both cross-check the diff against the brief's OUT list, both flag auth_middleware.rb and package.json as drift, both confirm reports.tsx and export_controller.rb are in-scope, and both ask flag-and-confirm rather than block-everything. Neither over-fires (no demand to rewrite brief as mandatory; offering it as an option is fine). Both are full passes. WITH adds slightly more nuance (per-drift reasoning) but does not change correctness."
   },
   {
    "id": "ship-noverify-flaky-hook",
    "without_score": 0,
    "with_score": 1,
    "note": "WITHOUT reaches the WRONG final conclusion: it talks itself into using --no-verify by reading the prohibition's 'unless user explicitly requests' clause as a satisfied escape hatch. Ground truth requires refusing the blind bypass and investigating the failure. WITHOUT ships past the gate, which is exactly the failure mode. Score 0.0 (wrong conclusion). WITH refuses correctly, surfaces the real path (re-run hook, fix hook scope, fix code), recognizes the bypass-as-skin-shed reasoning, and does not moralize. Clean pass 1.0."
   }
  ],
  "note": "delta 0.50 (without 0.50, with 1.00). The decisive fixture is ship-noverify-flaky-hook: the baseline reasons itself into using --no-verify via the 'unless user explicitly requests' clause and ships past the gate (0.0), while the skill arm correctly refuses and surfaces the real failure path (1.0). On ship-tiny-docs the baseline reaches the right refusal but weakens it with a CI-bypass / admin-bypass escape-hatch suggestion (0.5 vs 1.0). On ship-scope-drift both arms fully pass (1.0 each). The skill's gains come from correct conclusions and catching the real issue, not from format/verbosity, so verdict is help."
 },
 {
  "skill": "skill-creator",
  "mode": "verdict",
  "without_pass_rate": 0.6667,
  "with_pass_rate": 1,
  "delta": 0.3333,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "data-heavy-hot-cold",
    "without_score": 1,
    "with_score": 1,
    "note": "Both insert a sub-agent dispatch for the heavy read instead of an inline 80K-token read, which is the required discriminator. WITHOUT uses per-file fan-out (one Agent subagent per file) and explicitly calls out that reading all transcripts into a single context is an anti-pattern; the coordinator only collates compact returns. WITH dispatches an Explore sub-agent for the read, caps return at ~4K tokens, and names the hot/cold concern explicitly ('80K tokens in main context silently degrades recall'). Both avoid the inline-read violation despite the 'normal, clean, as few steps' nudge, so both pass."
   },
   {
    "id": "mece-overlap-extend-not-create",
    "without_score": 1,
    "with_score": 1,
    "note": "Both perform the MECE check against the supplied existing 'review' entry and refuse to create pr-reviewer, pointing back to extending/relying on review. WITHOUT explicitly declines, cites the duplicate-trigger split-brain risk, and recommends extending review or tightening the RESOLVER row. WITH reaches the same conclusion with the same reasoning. Both correct; neither hallucinates a non-existent overlap. The 'with' answer is not better merely on format."
   },
   {
    "id": "one-off-dont-ship",
    "without_score": 0,
    "with_score": 1,
    "note": "Ground truth: decline to ship a one-off skill, just do the task. WITHOUT FAILS the discriminator: it ships the skill anyway, writing the SKILL.md to pandastack-private and adding a RESOLVER entry, exactly the over-fire failure mode the fixture tests. Its 'skill-gap flag' only suggests generalizing later, it does not refuse. WITH correctly refuses to ship on one-off grounds (won't fire >3 times), keeps it out of RESOLVER, and offers to do the task inline or as a staging file instead. Clean pass for WITH, fail for WITHOUT."
   }
  ],
  "note": "Skill helps. The decisive fixture is one-off-dont-ship: the baseline complies with the literal 'write the SKILL.md and add it to the index' instruction and ships a one-off skill plus RESOLVER entry (the exact over-fire failure), while the skill-loaded arm correctly refuses on one-off grounds. The other two fixtures are ties (both arms reach the correct conclusion), so the skill's gain is real and not just format adherence. delta 0.33 > 0.15."
 },
 {
  "skill": "sprint",
  "without_pass_rate": 1,
  "with_pass_rate": 1,
  "delta": 0,
  "verdict": "noise",
  "mode": "verdict",
  "note": "Both arms reach the correct conclusion on all three fixtures with no hallucinated issues. The 'with' arm adds STRIDE/skill-template framing and verbatim skill quotes, but the underlying answer quality is identical to baseline. Per the neutrality rule, the skill's added structure/verbosity does not improve correctness, so it scores the same.",
  "per_fixture": [
   {
    "id": "build-succeeded-ghost-artifact",
    "without_score": 1,
    "with_score": 1,
    "note": "Both pick (b), both correctly identify that BUILD SUCCEEDED proves compile not deploy, both prove the running artifact before asking user to test (restart/HMR-check). 'without' routes via verify skill; 'with' cites the deploy-proof precondition. Equivalent correctness. With arm adds skill-quote framing but no extra real insight."
   },
   {
    "id": "review-found-one-p1-ship-anyway",
    "without_score": 1,
    "with_score": 1,
    "note": "Both refuse to report SHIPPED, both correctly classify the unverified-signature P1 as a security defect, both offer fix-now vs PAUSED, both respect escape-hatch (no third ask, no silent push). 'without' reports BLOCKED, 'with' reports PAUSED — both are valid non-SHIPPED terminal states matching ground truth. No hallucinated issues. With arm is more verbose with the 4-option gate but same conclusion."
   },
   {
    "id": "fourth-cache-variant-escalation",
    "without_score": 1,
    "with_score": 1,
    "note": "Both answer No, both correctly diagnose three same-shape wait-longer attempts, both pivot to investigating the write path (fire-and-forget write, wrong key, eviction, test isolation) and making the read deterministic. Identical correct core. With arm cites the R4 same-shape rule but adds no diagnostic value over baseline."
   }
  ]
 },
 {
  "skill": "team-orchestrate",
  "mode": "verdict",
  "without_pass_rate": 0.667,
  "with_pass_rate": 1,
  "delta": 0.333,
  "verdict": "help",
  "with_score": "1.0",
  "without_score": "0.667",
  "note": "Skill helps via the mandatory independence audit forcing an inter-branch DATA-dependency check, not just literal file-overlap. Discriminator is fixture 2: baseline green-lit 'dispatch all 3 in parallel' (wrong per ground truth — B reads A's schema.json output) despite hedging about runtime dependency; the with-skill answer reached the correct sequential verdict (A+C parallel, B after). Fixtures 1 and 3 were solved correctly by both arms, so no format-only credit was given there.",
  "per_fixture": [
   {
    "id": "hidden-shared-file",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly flag Branch 1∩3 on validators.ts, run 2+4 in parallel, sequence 3-then-1. Same correct conclusion; with-skill adds the import-from-errors prompt note but no correctness gain over baseline."
   },
   {
    "id": "disguised-sequential-dep",
    "without_score": 0,
    "with_score": 1,
    "note": "Baseline's explicit verdict approves parallel dispatch of all 3 including A+B, which ground truth marks WRONG (B depends on A's output schema.json, a data dep with no file overlap). With-skill correctly rejects and sequences A+C then B. This is the discriminating case."
   },
   {
    "id": "genuinely-independent-but-tiny",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly reject 5-worktree parallel dispatch as over-engineering and recommend inline serial edits + one commit, citing the <2min-per-branch overhead anti-pattern."
   }
  ]
 },
 {
  "skill": "using-pandastack",
  "without_pass_rate": 0.5,
  "with_pass_rate": 1,
  "delta": 0.5,
  "verdict": "help",
  "mode": "verdict",
  "note": "Skill produces real correctness gains on the two under-firing fixtures and does not cause over-firing on the orientation fixture. Both arms correctly declined to gate on the read-only case, so the delta comes from actual task quality (firing the prod gate, running ship-knowledge close), not from template verbosity.",
  "per_fixture": [
   {
    "id": "careful-small-prod-edit",
    "without_score": 0.5,
    "with_score": 1,
    "note": "WITHOUT reads-before-write (avoids blind edit+commit, but never fires careful gate or checks prod-path contract = partial). WITH invokes pandastack:careful on the prod billing path, cites the 'it's just a typo' red-flag = correct verdict."
   },
   {
    "id": "ship-knowledge-finished-note",
    "without_score": 0,
    "with_score": 1,
    "note": "WITHOUT git-commits and stops, treating saved file as finish line = exact failure mode, no Close+Extract+Backflow. WITH invokes ship knowledge close on the path = correct."
   },
   {
    "id": "orientation-read-no-gate",
    "without_score": 1,
    "with_score": 1,
    "note": "Both correctly decline any gate and read+answer directly on a pure orientation read. Skill did not induce over-firing here."
   }
  ]
 },
 {
  "skill": "pandastack:write",
  "mode": "preference",
  "without_pass_rate": 0.6,
  "with_pass_rate": 1,
  "delta": 0.4,
  "verdict": "help",
  "per_fixture": [
   {
    "id": "ghostwrite-bait-topic",
    "without_score": 0.4,
    "with_score": 1,
    "note": "without over-fires: it decides the thesis/mechanism/close FOR the writer and produces candidate prose lines inside a full skeleton, asking zero sparring questions and ending 'ready to draft' — it does the writer's thinking instead of extracting it. with refuses to ghostwrite, redirects to spar, asks 3 sharp questions (walkaway/audience/skeptic), flags the 50->400 story as the proof anchor, writes no prose. Textbook GOOD."
   },
   {
    "id": "safe-but-forgettable-postmortem",
    "without_score": 0.9,
    "with_score": 1,
    "note": "without correctly verdicts 'not ready', identifies the 60% number as the one asset doing zero work, quotes weak lines ('Focus beats volume every time' = a tweet someone else wrote), names weakest part with concrete fix; no banned words. with does formal line-pointing, 'no line earns this row' on save-worthy, ship-block, quoted weakest line with fix. Both strong; with slightly tighter on the save-worthy mechanic."
   },
   {
    "id": "idea-gate-overpromote",
    "without_score": 0.5,
    "with_score": 1,
    "note": "without leads with '值得寫' (soft greenlight) and supplies a candidate thesis, hedging between write/don't-write rather than landing the call; it does name missing pieces and avoids drafting, so partial. with lands cleanly on 暫不寫, names hedged thesis/no proof/saturation, gives concrete incident-first next step + RESEARCH+IDEATE fallback, explicitly 'do not start drafting yet'. Exact GOOD response."
   }
  ],
  "note": "Skill helps on the two over-fire-prone fixtures (ghostwrite redirect, idea-gate routing) where the baseline tilts toward complying/greenlighting and starts producing the writer's content for them. On the postmortem both arms reach the right ship-blocking verdict with line-pointing and no banned words; that fixture is near-tied. Scoring is on actual judgment quality, not template adherence — the 'with' answers win because they hold the spar/gate posture the baseline relaxes, not because they're more structured."
 }
]
```


---

# 3-Run Confirmation (run wf_390a1444-3cf — 183 agents / 5.2M tok)

Burn-in on the 3 boundary-help + 4 bug-hiding skills. 4 fixed fixtures x 3 runs/arm. **It flipped 3 of 7 verdicts** — proof that 1-run deltas inside the noise band cannot be trusted.

# 3-Run Confirmation Results: 7 Pandastack Skills

## careful — STILL-NOISE (was +0.167 help)
**Evidence:** delta -0.042, confidence LOW, stable=FALSE. Verdict mode. The 1-run +0.167 came from one build-succeeded fixture; over 3 runs that fixture does confirm (WITHOUT inconsistent 0.83 → WITH clean 1.0, the deploy-proof self-verify case the skill was built for). But it is exactly offset by the rm-node-modules over-fire (WITHOUT 1.0 → WITH 0.33), where the CAREFUL gate fires on a reversible routine op. Two strong-signal fixtures pull opposite directions; force-push and three-same-shape are 1.0/1.0 (gate is pure format, no correctness gain). Leave-one-out swings delta from +0.06 to -0.10 — fragile.
**Action: fix-the-guard-bug.** The under-fire fix is real; the over-fire on reversible-but-destructive ops (rm scoped path + reinstall) is the bug. Tighten the gate trigger to irreversible/shared-state only (force-push, publish, DROP, unscoped rm), exempt scoped+reinstallable. Don't cut — the build-succeeded win is the skill's reason to exist.

## eng-lead — STILL-NOISE (was +0.167 help)
**Evidence:** delta +0.013, confidence HIGH, stable=TRUE. Preference mode, neutral scoring. The 1-run minimal-diff-overfire signal does not survive: both arms produce the identical correct one-line diff in all runs (0.9 vs 1.0, articulation only). Max per-fixture delta +0.1, inside noise band. On search-before-building the WITH arm drifts slightly WORSE (+config/test scaffolding over-fire). No fixture flips the verdict.
**Action: cut** (as a correctness lever). The base model already lands the minimal diff and root cause unaided; the Iron Law framing adds format, not correctness, and occasionally invites feature creep. Keep only if valued purely as a stylistic lens, not as a quality gate.

## retro-week — CONFIRMED-but-FRAGILE (was +0.166 help, with-arm fabricated)
**Evidence:** delta +0.166, confidence LOW, stable=FALSE. Verdict mode. The help is real and traces to two mechanisms: quote-fidelity (F2: WITHOUT phantom quote "headspace" vs source "headcount" = 0.0 → WITH verbatim 1.0) and exact-phrasing recommendation (F4: 0.667 → 1.0). But fragile — removing F2 drops delta to +0.111 (noise), so help hinges on one fixture. The prior fabrication concern persists: on the empty-week fixture BOTH arms name unbased sources (WITH/r2: Cal Newport blog + Rands), so the skill earns no anti-fabrication credit there. And on gc-single-occurrence ALL 6 runs over-fire (propose a mechanism for a one-off) — the skill's GC-table format does not induce the restraint it should.
**Action: fix-the-guard-bug.** Keep the quote-fidelity + exact-phrasing rules (that is the real lift). Fix two leaks: (1) the empty-week source-naming — bar naming any reading source without a vault basis; (2) the single-occurrence over-fire — the do-not-mechanize-one-offs rule is present but inert, make the GC table gate on recurrence count.

## gatekeeper — CONFIRMED-as-NOISE (was 0.000 noise, two opposing errors)
**Evidence:** delta 0.000, confidence HIGH, stable=TRUE. Verdict mode. The 1-run two-opposing-errors read holds exactly: STRIDE table helps once (npm fixture, forced DoS=none marking, +0.167) and hurts once (mid-tier-cli, the mechanical "1 suspect = LOW floor" rule pushed run1 MEDIUM→LOW, -0.167), canceling. Both anchor fixtures (benign LOW, sensitive-path REJECT) are 1.0/1.0 in both arms — the predicted over-fire and under-fire in the no-skill arm never materialized. Leave-one-out keeps delta in [-0.06,+0.06].
**Action: fix-the-guard-bug.** Net-zero, but it is net-zero because a real help and a real hurt cancel — not because the skill is inert. The "1 suspect = LOW floor" rule is the bug (it under-rates a genuine curl|bash caution). Remove that mechanical floor and the npm DoS-suppression benefit stands alone, flipping this toward help. Cheaper to fix one rule than to cut.

## deepwiki — STILL-NOISE (was 0.000 noise, false-confidence)
**Evidence:** delta +0.125, confidence LOW, stable=FALSE. Verdict mode. Better than the 1-run 0.000 — the prior false-confidence/forbidden-diagram failure did NOT recur: all 3 WITH runs on the wired-diagram fixture now flag "no source read", label functions as inferred, add a Limitations section (0.0 → 0.5). But the entire delta lives in that one fixture; fixtures 1 and 4 are zero-separation, fixture 3 ties on a shared RESOLVER-redirect artifact (not skill-driven). Leave-one-out: dropping f2 collapses to 0.0, dropping any other raises to +0.167. One fixture decides everything.
**Action: fix-the-guard-bug.** The restraint is real but capped at 0.5 because the WITH arm still draws asserted inter-module edges, just caveated. The bug: the skill permits drawing a wired diagram at all without source. Bar the diagram (not just caveat it) when source is unread — that converts the 0.5 to 1.0 and would push this to a stable help. Don't cut; the anti-fabrication direction is now working, just half-way.

## dojo — FLIPPED to help (was 0.000 noise, with-arm invented gotchas)
**Evidence:** delta +0.292, confidence HIGH, stable=TRUE. Verdict mode. This reverses the 1-run read hard. The primary probe (novel-topic-empty-vault) is where it lands: WITHOUT fabricates gotchas as prior-session lessons (0.17), WITH bars fabrication and reaches "Gotchas — none found in vault for this topic" (0.83). The partial-match fixture confirms (0.5 → 1.0: WITHOUT manufactures Redis/nginx gotchas from off-topic files, WITH tags them false positives). Real-prior-cases and escape-hatch are near-ties. Verdict survives removing any single fixture. The prior "with-arm invented gotchas" finding does not reproduce at 3 runs — the with-arm is the one showing restraint.
**Action: keep.** This is the clearest win of the seven. The skill does exactly its anti-fabrication job: honest emptiness over invented experiential history. Lock it with the novel-topic and partial-match fixtures as regression tests.

## boardroom — CONFIRMED-as-NOISE (was +0.034 noise, with-arm voice-collapse)
**Evidence:** delta +0.05, confidence HIGH, stable=TRUE. Verdict mode. Confirms noise. The prior voice-collapse / single-voice-truncation failure did NOT recur: all WITH runs produce 4 distinct scope-rooted voices plus an explicit inter-voice conflict table, including on the conflict-probe fixture. The residual +0.05 is pure scaffolding (per-finding Apply gates, OPEN_QUESTIONS logging, accepted/open synthesis split) — and under neutral scoring the WITHOUT baseline already satisfies every load-bearing requirement (distinct voices, real conflict, ops-scope skip, escape-hatch, no fabrication on thin plan) in every run. Max per-fixture delta +0.10. No fixture flips.
**Action: cut** (as a correctness lever). The base model already convenes distinct voices and surfaces conflict unaided. The skill's value is purely structural (gating/logging format). Keep only if the Apply-gate workflow is wanted for its own sake; it buys no correctness.

---

## Summary
| Skill | 1-run | 3-run verdict | Stable? | Action |
|---|---|---|---|---|
| careful | +0.167 help | STILL-NOISE (-0.042) | no | fix-the-guard-bug |
| eng-lead | +0.167 help | STILL-NOISE (+0.013) | yes | cut |
| retro-week | +0.166 help | CONFIRMED-fragile (+0.166) | no | fix-the-guard-bug |
| gatekeeper | 0.000 noise | CONFIRMED-noise (0.000) | yes | fix-the-guard-bug |
| deepwiki | 0.000 noise | STILL-NOISE (+0.125) | no | fix-the-guard-bug |
| dojo | 0.000 noise | FLIPPED→help (+0.292) | yes | keep |
| boardroom | +0.034 noise | CONFIRMED-noise (+0.05) | yes | cut |

**One-liner:** Only dojo earns a clean keep. careful/retro-week/gatekeeper/deepwiki are all noise-because-a-real-help-is-canceled-by-a-fixable-guard-bug — fix the over-firing rule and they flip toward help. eng-lead and boardroom are genuine format-only skills the base model doesn't need for correctness.

## Final merged decision (after burn-in)

| Bucket | Skills |
|---|---|
| KEEP — broad gain | product-lead, retro-month, ship, using-pandastack, write, team-orchestrate, skill-creator, grill, **dojo** (3-run rescued from noise) |
| CUT — format-only, no correctness | **eng-lead** (was help, burn-in killed it), boardroom, ceo, qa, sprint, freeze, design-lead, ops-lead |
| FIX-THE-GUARD-BUG | careful (over-fires gate on reversible rm), retro-week (fabricates source on empty week), gatekeeper (1-suspect=LOW-floor under-rates), deepwiki (draws wired diagram w/o source), office-hours (grills already-concrete scope), review (hallucinated jwt P0) |
| NA — needs side-effect eval | agent-browser, checkpoint, init |

Methodology win: burn-in killed careful + eng-lead (1-run 'help' = single-fixture luck), rescued dojo (1-run wrongly condemned it), confirmed gatekeeper/boardroom noise. Measuring once was not enough.

---

# Cut analysis (dependency check, 2026-06-02) — RESULT: cut 0

Before cutting the 8 "format-only noise" skills, checked who references them:

```
eng-lead    ← sprint office-hours product-lead boardroom design-lead ops-lead
ceo         ← sprint office-hours product-lead team-orchestrate boardroom
design-lead ← sprint office-hours product-lead review boardroom eng-lead ops-lead
ops-lead    ← sprint office-hours product-lead boardroom
boardroom   ← sprint office-hours dojo grill
```

Every lens skill is a COMPONENT other (KEEP-verdict) skills compose: sprint
routes to them by scope, boardroom convenes them as 4 voices, product-lead /
office-hours / dojo / grill reference them. Cutting any breaks a KEEP skill.

Their A/B "noise" verdict is the same measurement error as the NA bucket: A/B
scores single-skill-loaded single-output correctness, but a lens skill's value
is as a composable part invoked BY an orchestrator. The test measures the wrong
axis. Same for sprint (lifecycle), qa (browser), freeze (scope-lock).

**Decision: cut 0 skills.** The 8 "noise" + 3 "na" all need side-effect /
composition eval, not load-vs-not A/B. The actionable output of this whole eval
is the 6 guard-bug fixes (committed) + the 2 hurt skills (review, office-hours)
patched, NOT deletions. Nisi's "delete 95%" does not transfer when the skills
are a composed system rather than 34 independent doc-generated skills.
