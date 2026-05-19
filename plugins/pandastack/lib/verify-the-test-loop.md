# lib/verify-the-test-loop.md — The test loop must be trustworthy before the bug is

> Shared module. Loaded by `sprint` (Stage 5/6), `eng-lead`, `careful`.
> An untrustworthy build/test loop manufactures phantom bugs: you debug
> code that never ran, on an environment that keeps changing under you.
> This module makes "is what I'm testing actually what I built, in a
> stable environment?" a gate, not an afterthought.
>
> Origin: murmur Sprint 5 (2026-05). ~Days lost debugging audio on a
> binary frozen 4 days stale (`xcodebuild` "BUILD SUCCEEDED" + a deploy
> script that grabbed the wrong artifact), while TCC churn changed the
> environment every cycle, while patching 4 variants of the wrong API.
> Every failure mode below is from that one session.

## When to load

Any time a human (or a flaky external system) is the test harness: a
build the user must launch, a deploy someone manually exercises, a
repro that needs a device. Load at `sprint` Stage 5 before declaring
SHIPPED on manually-validated work; load in `eng-lead` whenever a fix
will be verified by someone re-running something.

## Rule 1 — Deploy-proof gate (hard gate)

**Before asking a human to manually test a built/deployed artifact, prove
the artifact embeds this change.** No proof → do not ask them to test;
the bug to fix is the pipeline, not the code.

Minimum proof (pick what the stack allows, strongest first):

- **Content marker**: grep the *deployed* binary/bundle/image for a
  string/symbol/constant unique to this change (add a temporary one if
  needed). Absent ⇒ stale, stop.
- **Source-not-newer-than-artifact**: no source file is newer than the
  built artifact (`find <src> -newer <artifact>`). Any hit ⇒ stale build.
- **Deterministic path**: build to and deploy from a *pinned* path, never
  a `find … | head -1` / "latest in some cache" guess. Regenerated
  projects + incremental builders silently no-op — prefer `clean build`.
- **Identity stable**: if the OS keys trust/permissions on code identity
  (TCC, signing), the deployed artifact's identity is constant across
  rebuilds (stable cert, not adhoc/ephemeral).

The single highest-leverage tell observed: **"the instrumentation I
added isn't visible in the user's output."** Treat that as a pipeline
alarm — STOP and verify the loop — not as a fluke to theorise around.

## Rule 2 — Trust the substrate before the data

When test results are **contradictory, surprising, or "a sure thing got
worse,"** the first hypothesis is the environment, not the code:

1. Is the artifact fresh (Rule 1)?
2. Is the environment stable across iterations (same inputs, no
   permission/cache/identity/clock drift contaminating runs)?
3. Only once (1) and (2) are proven: theorise about the code.

Conclusions drawn on an unverified substrate are void — say so and
re-baseline; do not carry them forward as "confirmed."

## Rule 3 — Harden the harness before iterating

If the debug loop needs **repeated human round-trips** (re-grant, relaunch,
re-test), the **first iteration's deliverable is a cheap, trustworthy loop
— not a bug fix**: one-shot deterministic deploy, eliminated environmental
variables, deploy-proof baked in, stale-guard that fails loud. Paying this
once is cheaper than N contaminated human round-trips. Skipping it is the
most expensive shortcut in this module's origin story.

## Rule 4 — After 3 same-shape failures, the loop or the abstraction is the bug

Extends the generic 3-strike rule. If **3 fixes target the same failure
shape** (same error code / identical symptom signature), a 4th variant of
the same approach is statistical noise. Mandatory stop, in order:

1. Re-run Rule 1 + Rule 2 — is this a phantom (stale/contaminated)?
2. If the loop is trustworthy and it still fails the same way: the
   **abstraction/API is wrong**, not the parameters. Escalate to
   "different approach / different primitive," NOT "same approach,
   tuned." Name the abstraction being abandoned.

"Escalation" that stays inside the failing abstraction (a 4th lifecycle
variant of the same engine) is not escalation — it is strike 4.

## Anti-patterns

- ❌ "BUILD SUCCEEDED, so the user is testing my change" — success proves
  the compiler ran, not that the artifact under test is the one you built
- ❌ Theorising about code while test results are self-contradictory —
  substrate first
- ❌ "My added log/marker didn't show up, weird — anyway, back to the bug"
- ❌ Treating a human round-trip as free — each contaminated cycle is the
  expensive unit; harden the loop first
- ❌ Calling a 4th variant of the same failing approach an "escalation"
- ❌ Carrying forward conclusions drawn on an unverified binary/env
