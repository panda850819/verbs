# Canned loop kickoffs (hardened)

Copy-paste `/loop` bodies for bounded coding loops, with the circuit-breaker baked
into the kickoff text. Use these for the loop you run by hand (`/loop`); a
`no_agent` cron does not need a breaker (zero LLM, structurally cannot retry-spiral).

The breaker is the five `Stop early` conditions, not infra: a hard iteration cap,
no-progress detection, scope guard, decision-gap stop, and an anti-fake-green rule.
They guard the two named failure modes of autonomous loops — runaway spend
(retry-retry-retry) and false completion ("done is a claim, not proof").

## Test / Build / CI Until Green

```
/loop
Start a Test-Until-Green loop.
Goal: <outcome, e.g. murmur WER eval passes on airpods-baseline>
Max iterations: 6                                  # hard cap (circuit-breaker)
Between iterations run: <check cmd, e.g. murmur wer-eval --set airpods-baseline --json>
Exit when: the check above exits 0
Stop early and REPORT (do not keep trying) if:     # the breaker
  - the check output is identical 2 iterations in a row (no progress)
  - a fix would touch anything outside <scope>
  - a fix needs a decision not in the task (-> needs human)
Step 1: run the check; on failure fix the smallest root cause; repeat.
Give a one-line status each pass. Never weaken the check to make it pass.
```

Swap the `Goal` / `Between iterations run` / `<scope>` lines per task. For a
production build use `npm run build` (exit 0); for coverage add a threshold to the
exit condition; for CI use `gh run list --branch $(git branch --show-current)
--limit 1` and exit when the latest run is green.

## Why max-iterations + no-progress, not just an exit condition

An exit condition alone never fires if the agent is stuck (the check keeps failing
the same way). The iteration cap bounds spend; the no-progress check bounds wasted
loops; together they stop a stuck loop from burning the budget and from "agreeing
with itself" past the point where a human should look.
