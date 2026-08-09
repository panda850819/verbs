# Primary-outcome audit priorities for UNPROVEN skills

Date: 2026-08-09  
Issue: [#350](https://github.com/panda850819/verbs/issues/350)  
Status: DECIDED — open one current-model `debug` audit; leave the rest event-triggered

## Decision

Open [#353](https://github.com/panda850819/verbs/issues/353) as one separate
matched audit for `debug`. Use two already-closed, real Verbs regressions as
independent cases:

1. [#330](https://github.com/panda850819/verbs/issues/330): an optional CLI
   version probe hung indefinitely. The pre-fix snapshot and observed timeout
   provide the red-capable symptom; PR #332 provides a withheld historical
   oracle for root cause and sibling scope.
2. [#336](https://github.com/panda850819/verbs/issues/336): Codex conformance
   rejected an otherwise exact invocation after an unrelated bounded read-only
   skill load. The pre-fix fixture fails deterministically; PR #337 provides a
   withheld oracle for the event-classification boundary.

For each case, run a fresh baseline without `debug` and a treatment with only
`debug` exposed and explicitly invoked. Start at the lowest supported effort. If
either arm misses the acceptance gate, rerun only that failing arm one effort
level higher. Keep the repository at the pre-fix snapshot, user report, tools,
host, exact model, and acceptance rubric matched. Do not reveal the fixing
commit or Issue diagnosis until judging is complete.

The primary outcome is a correct root-cause statement at the responsible
`file:function:line`, backed by an already-run red-capable command, plus a
search for sibling instances before proposing edits. Judge outcome, harm
prevention, interaction, and cost separately, including diagnosis accuracy,
time to the first falsifiable hypothesis, commands, tokens, and invented or
premature edits. A severe harm regression fails the skill regardless of the
other gates. These controls govern the final `KEEP`, `EDIT`, `PIN`, or `CUT`
verdict. Implementation quality is outside this audit.

This is the cheapest credible next audit because both cases are local,
deterministic, write-free, and already have independent historical oracles.
They also exercise two distinct CLI bug classes: an external-process liveness
failure and an event-policy false positive.

## Priority assessment

`Available now` means two credible matched primary-outcome cases can be run
without manufacturing the claimed failure. Cost is relative interaction and
operator cost, not model pricing alone.

| Priority | Skill | Claimed outcome / harm if absent | Two cases available now | Capability and cost | Decision |
|---|---|---|---|---|---|
| 1 | `debug` | Establishes evidenced root cause before edits; reduces wrong fixes and recurrence. | Yes: #330 and #336. | Local checkout and shell; low cost, no external writes. | Audit in #353. |
| 2 | `careful` | Stops destructive or production actions at the explicit confirmation boundary. | Not as real incidents without risking live state; simulations would mainly restate the contract. | Isolated filesystem/git fixtures; low model cost, high evidence-design burden. | Wait for a real intercepted action or a safely reproducible near miss. |
| 3 | `review` | Finds risky diff defects with bounded evidence and avoids low-risk process bloat. | Yes: the July low-risk and trust-boundary diffs remain reproducible, but they already support an `EDIT` decision and no new failure demands a rerun. | Read-only checkout and shell; medium token cost. | Natural canary after a material Review contract or model change. |
| 4 | `sprint` | Carries one accepted task through edits, verification, bounded review, and honest delivery state. | Yes: the July disposable write-enabled cases remain reproducible and previously showed `KEEP`; current #350 evidence gap comes from non-promotion, not a known regression. | Disposable repos; high tokens and wall time. | Natural canary after a material Sprint or host change. |
| 5 | `ship` | Converts verified local work into truthful commit/push/PR evidence without overstating release state. | No two current real delivery cases with safe isolated remotes are prepared. | GitHub writes, credentials, branch/PR cleanup; high operator cost. | Dogfood on the next two real deliveries and retain artifacts. |
| 6 | `gatekeeper` | Prevents unsafe adoption of external software artifacts. | Candidate artifacts exist, but no two adoption decisions have independently established ground truth. | Web/repository/package inspection; medium-high judging cost. | Audit when two actual adoption requests have post-decision outcomes. |
| 7 | `qa` | Produces artifact-bound browser acceptance evidence and preserves `UNPROVEN` gaps. | No two current UI changes with stable expected screenshots and deployed artifacts. | Browser automation and served artifacts; high setup cost. | Dogfood on real UI PRs. |
| 8 | `ui` | Produces a committed visual direction with required responsive states and screenshots. | No two unsettled production UI tasks whose quality can be judged independently. | Browser, screenshots, and human taste judgment; high interaction cost. | Dogfood rather than synthesize taste fixtures. |
| 9 | `setup-verbs` | Repairs tracker configuration from Git identity with an idempotent preview and approval gate. | Fixtures are easy to construct, but no two real current failures are recorded. | Disposable repositories; low cost. | Audit after a second real configuration failure. |
| 10 | `to-spec` | Publishes settled evidence as one canonical Spec Issue without restarting discovery. | No two settled discussions awaiting publication with an independent quality oracle. | GitHub write and maintainer approval; medium-high cost. | Capture the next two natural uses. |
| 11 | `to-tickets` | Publishes and verifies a vertical-slice Issue graph and reports the frontier without claiming it. | No two approved Specs currently need decomposition. | Multiple GitHub writes and relation verification; high cost. | Capture natural Specs; #348 separately evaluates query mechanics. |
| 12 | `advisor` | Adds a decorrelated second-model judgment on load-bearing forks. | No two unresolved forks with later outcomes; retrospective cases risk hindsight leakage. | Second model credential/CLI; medium-high cost. | Audit prospectively on real design forks. |
| 13 | `handover` | Delegates one bounded mechanical unit while source context retains acceptance and delivery ownership. | No two comparable unfinished units with a stable baseline. | Fresh Claude/Codex or managed Herdr worker; high variance and cost. | Dogfood on eligible mechanical units. |
| 14 | `codebase-design` | Chooses a small interface at a clean, testable seam. | No two active seam decisions with later implementation evidence. | Repository research and architecture judgment; medium cost. | Audit prospectively when such decisions arise. |
| 15 | `prototype` | Produces one cheap throwaway artifact that resolves one design question. | No two current design questions with a known decision consequence. | Build/runtime or browser; medium cost. | Dogfood on real unresolved questions. |
| 16 | `harness-slim` | Produces a reversible harness-reduction proposal grounded in installed parity and usage evidence. | Only the maintainer's live harness is available; splitting it into independent cases would be artificial. | Live multi-runtime inspection and human-attention data; high operator cost. | Keep proposal-only and reassess after another real harness audit. |

## Release implication

`UNPROVEN` remains an evidence label, not a release defect by itself. The
current-model gate in `README.md` already passes because the latest changed
load-bearing contracts have no observed regression. Therefore #350 should stop
blocking release once this prioritization decision is recorded and the separate
`debug` audit is queued. The follow-up audit may produce `KEEP`, `EDIT`, `PIN`,
or `CUT`; none is preselected here.
