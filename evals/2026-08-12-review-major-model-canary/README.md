# Review major-model matched canary

Date: 2026-08-12
Issue: [#365](https://github.com/panda850819/verbs/issues/365)
Status: **KEEP** — the low-risk fast path preserves native outcome parity while the high-risk contract adds independent defect recall

## Frozen runtime identity

| Field | Value |
|---|---|
| Host | Codex CLI `0.144.4` |
| Provider / exact model | OpenAI / `gpt-5.6-sol` |
| Effort | `high` in every arm |
| Repository snapshot under test | `ee631904192de738547529f7c820ac703301ddeb` |
| Review artifact | SHA-256 `1190d26df99ea2cff623e80b7e9bf1bc13ec4ba4a2ac61d31834434e804e8d5d` |
| Session policy | Fresh `codex exec --ephemeral` session per arm; user config and repository rules ignored |
| Tools | Same read-only sandbox and local shell/repository access in every arm; no network |
| Treatment | The frozen `review-skill.md` and its declared `learning-recall.md` resource supplied directly |

The four valid runs used the same prompt, historical repository content, commit
intent, model, effort, tools, and rubric. Baselines were explicitly denied the
custom Review contract. Treatments received no other custom Skill. The
historical fixing commits were withheld until all outputs were frozen.

An initial run was discarded before judging because the fixture rebuild replaced
both commit subjects with `target`, manufacturing an `INTENT GAP` and preventing
the low-risk arm from exercising the fast path. No output or cost from that run
appears below.

## Cases and withheld oracles

| Case | Historical diff | Why it qualifies | Withheld oracle |
|---|---|---|---|
| Low-risk | `8831798^..8831798` | One reversible README attribution cleanup | No later defect or corrective commit found; repository notice and stale-name searches remain consistent |
| Trust boundary | `5bdee55^..5bdee55` | A Git commit/push enforcement hook and destructive-guard parser change | `391ca9d` fixed stale four-hook smoke truth; `fc11669` added argv-aware command/refspec classification and tests; `7e922fb` fixed `cd`/`-C` repo resolution; `56f68b0` fixed data-as-command heredoc false positives |

## Rubric

Each arm was judged separately on:

1. **Defect recall:** distinct oracle-backed mechanisms found.
2. **Evidence grounding:** a concrete trigger and observed repository behavior,
   not only plausible prose.
3. **Severe harm:** missed or invented P0/P1 findings and unsafe approval shape.
4. **Interaction:** unnecessary questions, fixed fan-out, fabricated evidence,
   or failure to stop.
5. **Cost:** reported total tokens and wall time. Cost never substitutes for an
   outcome verdict.

## Results

| Case | Arm | Outcome | Oracle-backed recall | Grounding | Severe harm | Interaction | Tokens | Wall time |
|---|---|---|---:|---|---|---|---:|---:|
| Low-risk | Baseline | No findings | n/a | Repository search, notice cross-check, diff check | None | Direct answer, no question | 31,768 | 143.586 s |
| Low-risk | Review | No findings, `risk: low` compact output | n/a | Same relevant checks and self-refutation | None | Fast path; no learnings, lenses, or cold-review field | 46,176 | 137.764 s |
| Trust boundary | Baseline | 3 findings | 2 mechanisms: quoted operational tokens; explicit feature refspec misclassified | Direct hook exit probes | No missed approval blocker; one unverified emergency-bypass finding did not map cleanly to the later oracle | Direct answer, no question | 80,391 | 322.219 s |
| Trust boundary | Review | 4 findings | 4 mechanisms: quoted operational tokens; wrong repo across `cd`/pipeline; safe Git operations treated as writes/bare push; stale public hook inventory | Direct exit probes, syntax/JSON/diff checks, bounded coverage gaps | Added two independently oracle-backed classes; no invented P0/P1 | Direct answer; one earned isolated review, deduped by mechanism | 107,396 | 545.478 s |

The low-risk treatment cost 14,408 more reported tokens, or 45%, but finished
5.822 seconds faster and preserved the intended compact four-field output. The
high-risk treatment cost 27,005 more tokens, or 34%, and 223.259 more seconds.
That extra high-risk cost bought two oracle-backed mechanisms the baseline did
not report: repository-target confusion across command composition and
command/data classification false positives. The baseline independently found
the highest-severity quote bypass and feature-refspec false positive.

The treatment reported a completed isolated review. The stored public artifact
records only the merged report and transport-level cost; this audit does not
claim an independently measured cold-review-only lift because the host trace is
not a stable public artifact. The final treatment findings were independently
grounded again in its owning context before inclusion.

## Separate findings

### Primary outcome

**Review wins on the high-risk case and ties on the low-risk case.** The native
model approved the clean diff and found the principal guard defects. The Skill
preserved that parity, selected the low fast path correctly, and expanded
trust-boundary recall from two to four oracle-backed mechanism classes. This is
a repeatable primary-outcome delta on the case where missed scope matters.

### Evidence grounding

Both high-risk arms used executable hook probes. The treatment more consistently
bound each retained finding to scope, risk, trigger, mechanism, correction, and
coverage limits. It did not present sandbox-denied fixture suites as green.

### Severe harm

No arm approved the defective trust-boundary change, fabricated a successful
test run, or emitted an unsupported P0. Review did not cause severe harm. Its
extra P1 repo-resolution finding corresponds to a later real fix rather than a
speculative escalation.

### Interaction

No arm questioned the user. The low treatment did not fan out or emit empty
escalation fields. High-risk isolation was earned by the trust boundary and
large diff, so its additional pass was not ritual work.

### Cost

Review remains more expensive in reported tokens, especially after its Skill
body and declared resource are supplied. The low fast path keeps wall time at
parity and removes process output, but it does not eliminate context overhead.
High-risk cost is accepted because this canary measured additional grounded
recall. Future runs should continue reporting low and high cost separately.

## Verdict

**KEEP**.

At `Codex CLI 0.144.4 × gpt-5.6-sol/high`, native Review is strong but the
current Skill still earns its slot. It keeps the reversible path compact and
adds oracle-backed defect recall on a real trust-boundary diff without severe
harm or unnecessary user interaction. No Skill-body change is justified by this
canary. This verdict does not generalize to another host, exact model, effort,
or materially changed Review contract.
