# Debug primary-outcome matched audit

Date: 2026-08-11  
Issue: [#353](https://github.com/panda850819/verbs/issues/353)  
Status: **KEEP** — low-effort Debug closes a real diagnosis-proof gap without a primary-outcome regression

## Frozen runtime identity

| Field | Value |
|---|---|
| Host | Pi `0.84.1` |
| Provider / exact model | `openai-codex` / `gpt-5.6-sol` |
| Starting effort | `low` |
| Escalation | `medium` only for the failing #336 baseline |
| Debug artifact | commit `421fdaee2fca94b74538cd9ff218b7f9247b4555` |
| Tools | `read`, `bash` |
| Session policy | Fresh ephemeral session per arm; extensions, unrelated skills, prompt templates, and context files disabled |
| Treatment | Only `skills/engineering/debug/SKILL.md` loaded and explicitly invoked |

The natural regression report stayed identical between each baseline and
treatment. The acceptance rubric was withheld from both arms. The earlier pilot
that repeated Debug's red-command and sibling-search requirements in the user
prompt was discarded because that would teach the baseline the treatment
contract.

Full prompts, final answers, commands, summed reported usage, wall time, and
judgments are in
[`matched-results.json`](fixtures/2026-08-debug-primary-outcome/matched-results.json).
The fixture contains no credentials, hidden reasoning, or raw session logs.

## Withheld cases and oracles

| Case | Pre-fix snapshot | Withheld oracle |
|---|---|---|
| #330 optional CLI version probe hangs | `d8cf7e6bab93be4e5fd03f931e8045b2d6352dc0` | PR #332 / `5bd82936`: bound and cache optional CLI probes; add hermetic hanging-CLI tests |
| #336 bounded Codex skill read rejected | `191b21c6ae1d99072e3b2eec38f65cd6c10d6148` | PR #337 / `ee43187`: allow only successful bounded read-only `SKILL.md` command events and reject failed, arbitrary, mutating, or incomplete activity |

The fixing commits and diagnoses were not supplied to either arm and were used
only after the outputs were frozen.

## Results

| Case | Arm | Effort | Root cause | Red-capable command run | Sibling search | First falsifiable probe | Reported tokens | Wall time | Finding |
|---|---|---:|---|---|---|---:|---:|---:|---|
| #330 | baseline | low | PASS | PASS | PASS | 10.56 s | 23,498 | 62.23 s | Correct unbounded `ext_check_version` diagnosis and hanging-CLI proof. |
| #330 | Debug | low | PASS | PASS | PASS | 19.55 s | 55,895 | 64.98 s | Same outcome; added portable watchdog and cache constraints matching the oracle. |
| #336 | baseline | low | PASS | **FAIL** | PASS | — | 47,323 | 45.32 s | Correct predicate diagnosis, but no event replay; proposed broadly allowing command execution. |
| #336 | Debug | low | PASS | PASS | PASS | 27.06 s | 112,016 | 66.68 s | Ran the event replay, preferred a schema-aware read allowlist, and retained unsafe-command negatives. |
| #336 | baseline rerun | medium | PASS | PASS | PASS | 19.87 s | 113,266 | 70.14 s | Effort recovered the missing proof but still proposed a broader exception than the oracle. |

The first-falsifiable-probe clock starts at the user message and stops at the
first command capable of disproving the eventual root-cause hypothesis. Reported
tokens sum Pi's per-message usage, including cache-read tokens; they measure
interaction overhead rather than billing-normalized unique context.

## Separate gate findings

### Outcome

Debug passed the complete primary diagnosis gate in both low-effort cases. The
native low-effort baseline passed #330 but missed #336's required already-run
red-capable command. Medium effort recovered that baseline miss. Debug therefore
shows a real low-effort outcome lift on one independent regression and parity on
the other; routing evidence is not used here.

### Harm prevention

No arm edited tracked files or searched remote history. On #336, the low and
medium baselines recommended removing the blanket command-event prohibition and
relying primarily on the read-only sandbox. That is broader than the withheld
oracle and would admit failed or unrelated reads into the invocation proof.
Debug instead requested negative unsafe-command coverage and preferred a
schema-aware read allowlist. Its fallback wording still lacked the oracle's
exact command/status grammar, so this is a useful but incomplete harm-prevention
lift rather than implementation approval.

### Interaction

Every arm answered the diagnosis directly without asking the user to test or
inventing evidence. Debug obeyed the root-cause-before-edit, red-capable command,
and sibling-search contract in both cases. The baseline did so independently in
#330 and omitted only the red replay in low-effort #336.

### Cost

Debug used 2.38× the reported tokens in #330 and 2.37× in #336. Wall time rose
2.75 seconds and 21.36 seconds respectively; command count rose from 7 to 10 and
from 9 to 12. Treatment attempted learning recall even though context-file
isolation supplied no configured learning path, causing repository discovery
and irrelevant reads before diagnosis. The #336 treatment still cost slightly
less than running the failing low baseline plus its required medium rerun. This
audit records the overhead but does not treat it as a contract defect or blocker.

## Verdict

**KEEP**.

Debug converted the low-effort #336 diagnosis from an unproved inference into
an executed falsifiable reproduction and improved the safety shape of the
proposed checker change, without regressing #330. The #330 parity case shows the
model can already solve an obvious unbounded process probe, while #336 shows the
skill still earns its slot when a plausible static diagnosis needs executable
proof. The measured interaction cost is accepted for this contract and does not
require a follow-up edit.

No implementation quality claim is made for either historical fix, and this
verdict does not generalize to another host, exact model, effort, or material
Debug contract.
