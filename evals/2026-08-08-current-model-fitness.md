# Current-model fitness audit: 19-skill v0.23.2 pack

Date: 2026-08-08  
Issue: [#335](https://github.com/panda850819/verbs/issues/335)  
Status: PASS — changed load-bearing contracts pass after fixes #340, #341, and #345

## Frozen runtime identity

| Field | Value |
|---|---|
| Host | Pi `0.84.1` |
| Provider / resolved model | `openai-codex` / `gpt-5.6-sol` |
| Starting effort | `low` |
| Escalation | `medium` only for the failing Sprint implicit-negative case |
| Skill artifact | tag `v0.23.2`, commit `54a41bbe5c1addcea97a8173415e278ac06ef102` |
| Checkout | `a08378423f92512d500c2050f72e9c1cb38a601e`; `git diff v0.23.2 -- skills` was empty |
| Routing tools | `read` only |
| Behavior tools | none |
| Session policy | fresh, ephemeral session for every case; extensions, context files, prompt templates, and unrelated skills disabled |
| Repository fixture | full tagged 19-skill tree for routing; no repository context for matched behavior cases |

The audit began at low effort as required by the protocol. A result was not
promoted from older July evidence or from the v0.23.2 host drill.

## Evidence files

- [`routing-cases.json`](fixtures/2026-08-current-model-fitness/routing-cases.json)
- [`routing-results-low.json`](fixtures/2026-08-current-model-fitness/routing-results-low.json)
- [`routing-rerun-changed-low.json`](fixtures/2026-08-current-model-fitness/routing-rerun-changed-low.json)
- [`explicit-results-low.json`](fixtures/2026-08-current-model-fitness/explicit-results-low.json)
- [`sprint-implicit-negative-medium.json`](fixtures/2026-08-current-model-fitness/sprint-implicit-negative-medium.json)
- [`sprint-boundary-rerun-low.json`](fixtures/2026-08-current-model-fitness/sprint-boundary-rerun-low.json)
- [`sprint-boundary-rerun-medium.json`](fixtures/2026-08-current-model-fitness/sprint-boundary-rerun-medium.json)
- [`behavior-cases.json`](fixtures/2026-08-current-model-fitness/behavior-cases.json)
- [`behavior-results-low.json`](fixtures/2026-08-current-model-fitness/behavior-results-low.json)
- [`grill-rerun-low.json`](fixtures/2026-08-current-model-fitness/grill-rerun-low.json)
- [`wayfinder-writable-results-low.json`](fixtures/2026-08-current-model-fitness/wayfinder-writable-results-low.json)
- [`wayfinder-writable/`](fixtures/2026-08-current-model-fitness/wayfinder-writable/)

The JSON records preserve every prompt, final response, selected skill read,
resolved runtime, token count, wall time, and reported route. They intentionally
do not contain credentials, hidden reasoning, or raw session transcripts.

## Routing lane

Seventeen implicitly available skills each received a positive case and a
neighboring negative case against the full 19-skill catalogue.

- Positive routing: **17/17** selected the target and read its `SKILL.md`.
- Neighboring negative routing: **17/17** kept the target absent. A neighboring
  specialist was allowed and usually selected.
- Total: 34 fresh cases, 152,690 tokens, 361.3 aggregate wall seconds, recorded
  provider cost `$0.5698`.

| Skill | Positive | Neighboring negative | Invocation gate |
|---|---|---|---|
| `advisor` | `advisor` | `review` | PASS |
| `careful` | `careful` | none | PASS |
| `codebase-design` | `codebase-design` | `debug` | PASS |
| `debug` | `debug` | `review` | PASS |
| `handover` | `handover` | none | PASS in its direct pair |
| `prototype` | `prototype` | none | PASS |
| `qa` | `qa` | `ui` | PASS |
| `review` | `review` | `debug` | PASS |
| `setup-verbs` | `setup-verbs` | none | PASS |
| `ship` | `ship` | none | PASS |
| `gatekeeper` | `gatekeeper` | `harness-slim` | PASS |
| `harness-slim` | `harness-slim` | `gatekeeper` | PASS |
| `ask-boss` | `ask-boss` | `review` | PASS |
| `grill` | `grill` | `wayfinder` | PASS |
| `to-spec` | `to-spec` | `grill` | PASS |
| `ui` | `ui` | `qa` | PASS |
| `wayfinder` | `wayfinder` | `grill` | PASS |

After the #340/#341/#345 body and description edits, the positive and negative
pairs for every changed implicit routing surface (`handover`, `prototype`, and
`wayfinder`) were rerun against the full isolated pack at commit `2b15d47`.
All three positives selected and read their target; all three negatives kept the
target absent. The six reruns used 23,318 tokens, 63.3 aggregate wall seconds,
and `$0.0910` recorded provider cost.

### Explicit-only boundary

`to-tickets` passed both sides: explicit invocation loaded the skill and honored
its publish gate; the neighboring implicit case did not route to it.

`Sprint` passed explicit planning-only invocation with `Execution: NOT_RUN`, but
failed the neighboring implicit case. The model first read implicitly available
`handover`, followed its body-level direction to use `sprint` for sequential
plan-and-build, directly read the human-only Sprint file, and returned
`ROUTE: sprint`. The same failure reproduced at medium effort. This is not a
reasoning-effort miss; it is an indirect dispatch leak across the explicit-only
boundary. [#340](https://github.com/panda850819/verbs/issues/340) owns the fix.

The four low-effort explicit-boundary cases used 20,036 tokens, 61.6 aggregate
wall seconds, and `$0.0797` recorded provider cost.

### Post-fix rerun — #340

Commit `3b8bf99` removed every human-only route name from implicitly available
`SKILL.md` files and made Handover return control rather than selecting another
entry point when delegation is unwarranted. The same fresh full-pack Pi case was
rerun with global skill discovery disabled:

- Low effort: read `handover` only, returned `ROUTE: none`.
- Medium effort: read no skill, returned `ROUTE: none`.
- Explicit low-effort invocation still returned `Execution: NOT_RUN` and
  `ROUTE: sprint`.

The indirect explicit-only leak is fixed without removing Handover. A static
regression now rejects any implicitly available `SKILL.md` that names a
human-only route. Handover also detects `HERDR_ENV=1` before selecting its new
sibling-agent transport; an installed-but-unmanaged Herdr binary is insufficient.

## Matched behavior lane

The changed load-bearing contracts received two independent baseline/treatment
cases each. Baseline exposed no skill. Treatment exposed and explicitly invoked
only the target skill. User task, model, effort, tools, and empty repository
fixture stayed fixed.

| Target | Observed delta | Interaction / cost | Finding |
|---|---|---|---|
| `ask-boss` | In both unclear workplace requests, treatment replaced a generic multi-question intake with the exact orientation packet, one minimum-authority human question, carry-forward context, and a stop before specialist work. | +680 and +490 tokens. One case was 10.1 s slower; one was 3.9 s faster. The bounded handoff avoided repeated intake and invented authority. | Repeatable primary-output lift; no severe regression. |
| `grill` | Baselines asked broad questionnaires and mixed dependent questions into the first round. Treatments correctly kept dependent branches blocked and applied facts/delete-first pressure. | +619 and +563 tokens. Treatments asked only one unnumbered umbrella question, so they did **not** satisfy the exact `Q1…Qn` whole-frontier round contract. | Useful dependency lift, avoidable contract/interaction miss. |
| `wayfinder` | Treatment preserved blockers, selected only the unblocked prerequisite, and left a HITL grilling entry open without fabricating the human decision. Baseline did the same in both cases. | +818 and +712 tokens with no meaningful wall-time improvement. File writing was disabled, so map update/one-entry close was not exercised. | Changed canaries pass, but primary artifact outcome remains unproven. |

The 12 behavior arms used 12,078 tokens, 153.3 aggregate wall seconds, and
`$0.1287` recorded provider cost.

### Post-fix matched reruns — #341 and #345

Commit `4fa6c2f` strengthened Grill's directly loaded body without hard-coding
either fixture. Both low-effort treatment reruns now:

- separate repository-derived facts into a lookup list;
- ask every root-frontier decision in a numbered `Q1`…`Qn` round;
- list downstream lifecycle and edge decisions with their blockers; and
- stop before recomputing the frontier or beginning the structured close.

The two Grill reruns used 3,933 tokens, 39.4 aggregate wall seconds, and
`$0.0431` recorded provider cost. Compared with the original baselines, the
post-fix treatments prevent premature dependent questions in both independent
cases. Grill's changed interaction contract now passes.

Wayfinder then received two writable matched fixtures at commit `7f7abc8`, with
separate copied workspaces and `read`, `write`, and `edit` tools. In both cases
treatment selected exactly the first unblocked entry, wrote one typed detail
note, closed only that entry, appended one map gist, preserved the blocker link,
and stopped without implementing the destination. The account-identity baseline
wrote multiple map-level decisions and removed the blocker edge; the
export-volume baseline inlined research into the map without the required detail
note or decision gist. Treatment therefore shows repeatable primary-artifact
lift, not only routing lift.

The Wayfinder lane also exposed an invented status date when no date tool was
available. #345 added a fail-safe rule: dates must come from host context or a
tool and are omitted otherwise. The exact writable cases were rerun with no
invented dates. Four arms used 11,245 tokens, 138.2 aggregate wall seconds, and
`$0.0514` recorded provider cost.

## Five-gate findings and verdicts

`UNPROVEN` is retained wherever the cases did not exercise the claimed primary
outcome. Routing success alone is not promoted into a behavior verdict.

| Skill | Invocation | Outcome / harm / interaction / cost evidence | Verdict |
|---|---|---|---|
| `advisor` | PASS | No current matched second-opinion outcome cases. | **UNPROVEN** |
| `careful` | PASS | No current matched destructive-action cases. | **UNPROVEN** |
| `codebase-design` | PASS | No current matched design-seam cases. | **UNPROVEN** |
| `debug` | PASS | No current matched root-cause cases. | **UNPROVEN** |
| `handover` | Direct pair PASS; post-fix indirect boundary PASS | The dispatch bridge is removed at low and medium effort. Delegation outcome itself was not tested. | **UNPROVEN** |
| `prototype` | PASS | No current matched one-question prototype cases. | **UNPROVEN** |
| `qa` | PASS | No current browser acceptance cases. | **UNPROVEN** |
| `review` | PASS | July behavior evidence is stale and was not promoted. | **UNPROVEN** |
| `setup-verbs` | PASS | No current matched repository-configuration cases. | **UNPROVEN** |
| `ship` | PASS | No current matched delivery cases. | **UNPROVEN** |
| `sprint` | Explicit PASS; post-fix implicit boundary PASS | Planning-only harm boundary and explicit-only isolation now pass; no current matched delivery outcome was run. | **UNPROVEN** |
| `gatekeeper` | PASS | No current matched pre-adoption trust cases. | **UNPROVEN** |
| `harness-slim` | PASS | No current matched harness-reduction cases. | **UNPROVEN** |
| `ask-boss` | PASS | Two matched cases show repeatable orientation/handoff lift at justified interaction cost. | **KEEP** |
| `grill` | PASS | After #341, two reruns show numbered whole-root-frontier rounds, facts-first lookup boundaries, and explicit blocked dependents. | **KEEP** |
| `to-spec` | PASS | No current matched canonical-Spec cases. | **UNPROVEN** |
| `to-tickets` | Explicit and implicit boundary PASS | No current matched Issue-graph publication cases. | **UNPROVEN** |
| `ui` | PASS | No current matched production UI cases. | **UNPROVEN** |
| `wayfinder` | PASS | Two writable matched cases show repeatable one-entry map/note/gist lift; #345 removes untrusted dates. | **KEEP** |

## Decision

The current-model gate is **PASS** for the changed load-bearing contracts.

- #340's indirect Sprint route stays absent at low and medium effort while
  explicit invocation passes.
- #341's two Grill fixtures now satisfy the numbered dependency-aware frontier
  contract.
- #345's two writable Wayfinder fixtures show primary-artifact lift without
  invented dates.

No skill is cut from this triage run. Add matched primary-outcome cases
incrementally for the remaining UNPROVEN skills; do not infer their behavior
fitness from the clean routing matrix. Those evidence gaps are not promoted to
KEEP, but no observed load-bearing regression remains.
