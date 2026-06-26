---
name: review
description: |
  Use when asked to "review", "check my code", or before creating a PR.
reads:
  - repo: "**"
  - repo: CLAUDE.md
  - repo: AGENTS.md
  - repo: docs/briefs/**
  - repo: docs/learnings/**
  - cli: git
  - cli: grep
writes:
  - repo: "**"
  - cli: stdout
forbids:
  - cli: git push
  - cli: gh pr create
domain: shared
classification: hybrid
---

# Code Review

## Step 0: System Audit (fixed opener)

Before scoping the diff, audit branch state. Run these 5 commands. **Do not skip.**

```bash
git log --oneline -30
git diff origin/main --stat 2>/dev/null || git diff main --stat 2>/dev/null
git stash list
grep -rln "TODO\|FIXME\|HACK\|XXX" --include="*.md" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" --include="*.go" --include="*.rb" . 2>/dev/null | head -20
git log --since=30.days --name-only --format= 2>/dev/null | sort | uniq -c | sort -rn | head -10
```

Then read (if present): `CLAUDE.md`, `AGENTS.md`, `TODOS.md`.

Report findings in 5 bullets max:
- Branch state: ahead/behind/diverged
- Stashed work: count and topics (if any)
- TODO/FIXME hotspots in changed files
- Files touched most in past 30 days (architectural drift signal)
- Convention sources read (which CLAUDE.md / AGENTS.md / TODOS.md)

If output for any command is > 30 lines, summarize. Don't dump raw output into the review.

## Step 1: Scope

1. Read pstack config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses). Bind the path variables used below from it: `{main}` = configured main branch (default `main`), `{learnings_dir}` = configured learnings dir (default `docs/learnings`). Use these resolved values everywhere they appear.
2. Run `git branch --show-current`. If on the main branch, stop: "Nothing to review — you're on main."
3. Run `git diff origin/{main} --stat`. If no diff, stop.
4. Get the full diff: `git diff origin/{main}`

## Step 2: Load Learnings

Search `{learnings_dir}` for learnings related to the changed files:

```bash
# Search by file paths mentioned in the diff
grep -rl "relevant-file-path" {learnings_dir}/ 2>/dev/null

# Search by keywords from the diff (function names, patterns)
grep -rl "keyword" {learnings_dir}/ 2>/dev/null
```

Read matching files. For each match, note:
"Prior learning: [key] (confidence N/10, from [date])"

Apply confidence decay per `lib/confidence.md` rules. Skip learnings with effective confidence < 3.

## Step 3: Brief Alignment Check

If a brief exists for this branch (check `docs/briefs/` for a matching slug or date):

1. Read the brief's **Problem**, **Success Metric**, **Scope > In**, and **Scope > Out** sections.
2. **Drift check** — compare against the diff. Flag any changed files or features that fall outside the stated scope.
3. **Coverage check** — for each In-scope item and the Success Metric, verify the diff addresses it. Flag any in-scope item with no visible implementation.
4. Output:
   - "Brief: ON TRACK" if drift and coverage both clean.
   - "SCOPE DRIFT: [description]" for each out-of-scope change. Ask user to confirm or revert.
   - "COVERAGE GAP: [in-scope item with no matching change]" for each missing piece. Ask user to confirm intentional or flag as incomplete.

If no brief exists, skip this step silently.

## Step 4: Detect Diff Scope

Scan the diff file list to detect which conditional passes to activate:

```
SCOPE_MIGRATION  — files matching **/migrations/**, **/migrate*, **/*.sql with CREATE/ALTER/DROP
SCOPE_API        — files matching **/routes/**, **/controllers/**, **/api/**, **/handlers/**
SCOPE_AUTH       — files matching **/auth/**, **/middleware/**, or diff containing token/session/password/permission
SCOPE_INFRA      — files matching **/docker*, **/.github/**, **/terraform/**, **/k8s/**
```

Log detected scopes: "Scope signals: {list}" (or "none" if only base code changes).

## Step 5: Parallel Review

Launch review passes in parallel using `context: fork` (isolated subagents — results flow back, intermediate work stays out of main context). Each reviews the same diff with a different lens.

**Model routing** — when spawning each Agent, the orchestrator judges which model fits that lens by its demands: a mechanical pattern-match pass and a deep architectural-reasoning pass have different needs. Pass `model:` per pass based on that judgment; decide by task nature at dispatch time rather than from a fixed model-name table.

**Always-on passes (run every time):**

**Pass 1 — Correctness** (eng agent lens):
- Bugs that pass CI but break production
- Race conditions, N+1 queries, stale reads
- Missing error handling at system boundaries
- Test gaps for changed code paths
- **Test intent verification** (Mnilax Rule 9, adopted 2026-05-24): for each NEW or MODIFIED test, ask "if business logic flips, would this test catch it?" A test like `expect(getUserName()).toBe('John')` is worthless when the function `return 'John'` hardcoded — that asserts return shape, not business intent. Flag tests that pass on tautological assertions. Format: `[P1] file:line — test asserts shape but not intent — Fix: assert against derived/computed value, or add a test where business logic flip would fail`.

**Pass 2 — Security**:
- Injection (SQL, command, XSS)
- Auth/authz bypass
- Secrets in code or logs
- Unsafe deserialization, SSRF

**Grounding requirement (anti-hallucination, every finding, especially P0/P1):** each security finding MUST cite a concrete, attacker-reachable exploit path through the actual code — name who controls the input and trace how it reaches the sink. A dangerous-looking API name (e.g. `jwt.decode`, `eval`, `pickle.loads`) is NOT itself a finding. If the input is self-issued / internal / not attacker-controlled (e.g. a token the same service both issues and verifies), there is no exploit path — drop the finding entirely, do NOT downgrade it to a lower severity. No real exploit path named = not a finding. **Third outcome (don't silently drop a real-but-untraced vuln):** if controllability is UNRESOLVED — you could not establish the input is internal, but also could not fully trace the path within the review budget — surface it as a `needs-trace` flagged uncertainty, not a dropped finding. Drop only when affirmatively shown non-attacker-controlled; "I couldn't trace it" is not "there is no path."

**Pass 3 — Architecture**:
- Coupling that will hurt later
- Abstractions that don't earn their complexity
- API surface changes that break consumers
- Missing migrations or backwards-incompatible changes

**Conditional passes (only when scope detected):** for each `SCOPE_*` signal from Step 4 (and Pass 8 when the diff carries writing/design artifacts), run the matching pass from `skills/engineering/review/lib/conditional-passes.md`. Skip the file entirely when no scope signal fired.

Each pass outputs findings in the same format:
```
[P0-P3] (confidence: N/10) file:line — description
  Fix: what to do
  Action: AUTO-FIX | ASK
```

Merge all findings, deduplicate, sort by priority. If multiple passes flag the same file:line, boost confidence and mark "MULTI-PASS CONFIRMED".

**AUTO-FIX**: mechanical fixes (typos, missing null checks, obvious bugs). Apply directly.
**ASK**: judgment calls (architecture, design trade-offs). Batch all ASK items into one AskUserQuestion using the four-option gate contract (approve / edit / reject / skip). See `lib/gate-contract.md`.

If no issues found across all passes: "Review clean. No issues found."

## Step 6: Cold Review (Uncorrelated Context)

Spawn a fresh agent with `isolation: "worktree"` to review the same diff
with zero knowledge of why the code was written. This catches issues that
the in-session reviewer misses due to confirmation bias.

The cold reviewer receives ONLY:
- The raw diff (`git diff origin/{main}`)
- The project's `CLAUDE.md` and `AGENTS.md` if present (for conventions, not intent)
- This instruction: "Review this diff for bugs, security issues, and
  design problems. You have no context about why these changes were made.
  Report only findings with confidence >= 7/10. Format: [P0-P3] file:line — description."

DO NOT pass: the brief, the conversation history, the task description,
or any explanation of what the code is supposed to do.

Merge cold review findings with Step 5 findings:
- If cold reviewer flags something Step 5 missed → boost to P1 minimum,
  tag as "COLD-CATCH"
- If cold reviewer flags something Step 5 also caught → tag as
  "CROSS-CONFIRMED" (highest confidence)
- If cold reviewer flags something that Step 5 explicitly cleared →
  present both opinions to user, don't auto-resolve

## Step 6.5: Codex Adversarial Review (Cross-Model)

Run Codex as an independent adversarial reviewer. This adds a second model's
perspective (GPT) to Claude's review, catching blind spots from model-specific
reasoning patterns.

**Launch in parallel with Step 6.** Drive the installed `codex` CLI
(codex-cli) directly — there is no Node companion script. Probe first;
if `codex` is not on PATH, skip and note "Codex: unavailable (codex CLI
not on PATH)" in the completion box (honest degrade, never silent):

```bash
if command -v codex >/dev/null 2>&1; then
  git diff origin/{main} -- ':!docs' > /tmp/pstack-review.diff
  codex exec --skip-git-repo-check -c 'sandbox_mode="read-only"' \
    "You are an adversarial cross-model reviewer (GPT) on this PR diff (stdin).
Report ONLY real defects as: [P0|P1|P2|P3] file:line — issue — fix.
Terse, no preamble, no praise, max 8 findings. Prioritise concurrency /
data races, object lifetime & leaks, auth & permission gating, and
error-path correctness. Say 'clean: <file>' for files with no defect." \
    < /tmp/pstack-review.diff 2>&1 | tail -60
else
  echo "Codex: unavailable (codex CLI not on PATH)"
fi
```

`codex exec` is non-interactive and self-terminating; cap it with a
`timeout 360` if the harness needs a hard bound. Do NOT fall back to an
interactive `codex` invocation (it would hang the review).

**Outside Voice Integration Rule:** Codex findings are **informational only**. Each must be explicitly approved by the user before it lands in the final report or any follow-up commit. Cross-model consensus is a strong signal — surface it as such — but **do not auto-elevate** priority or confidence based on consensus alone.

**Merge Codex findings with Steps 5-6 findings:**
- Codex finding matches a Claude finding → tag as "CROSS-MODEL CONFIRMED". Display original Claude confidence + Codex confirmation. **Do not auto-boost** to maximum.
- Codex finding is novel (not caught by Claude) → tag as "CODEX-CATCH, suggested P{N}". The suggested priority is informational. **User approval required** before it enters the final report at that priority.
- Codex finding contradicts a Claude "clean" assessment → present both opinions to user, don't auto-resolve.

**Output format for Codex findings:**
```
[suggested P0-P3] (CODEX-CATCH, confidence: N%) file:line — description
  Fix: recommendation
  Apply to final report? [Y / N / edit]
```

`N` responses go to the Completion Summary's `OPEN_QUESTIONS` count, not discarded silently.

## Step 7: Write Learnings

After review completes (including cold review), evaluate whether any non-obvious pattern was discovered.

Test: "Would this save time in a future session on this codebase?"

If yes, check `{learnings_dir}` for existing learnings with similar key.
- If match exists: update `last_seen` and add new context.
- If no match: write new file to `{learnings_dir}/{category}/{slug}.md`

Use the format from `lib/learning-format.md`.

If nothing worth recording: skip silently. Not every review produces learnings.

## Step 7.5: Route caught flaws back to the skill (propose-only)

After Step 7, for each confirmed flaw, apply the propose-only flaw-routing rule in `lib/trigger-first-skill-evolution.md` (map to the skill whose anti-pattern/checklist table should have caught it; propose only, never edit the target skill, never during an autonomous build). For each mapping, emit ONE line into the session-end brain-candidate audit (skip silently if your setup has no such surface):

```
skill-edit candidate: <skill> — <missing check its anti-pattern/checklist table should have had>
```

No mapping → skip silently.

## Step 8: Completion Summary

Before exiting, print a single ASCII box so the user can see scope at a glance.

```
+============================================================+
|              REVIEW — COMPLETION SUMMARY                   |
+============================================================+
| Branch       | {branch}                                    |
| Commit       | {short hash}                                |
| Step 0 audit | ran / skipped — {N} stashed, {N} TODOs hit  |
| Step 3 brief | ON TRACK / DRIFT:{N} / GAP:{N} / no brief   |
| Step 5 passes| P0:_ P1:_ P2:_ P3:_  ({N} AUTO-FIX applied) |
| Step 6 cold  | ran / skipped — {N} COLD-CATCH              |
| Step 6.5 cdx | ran / unavailable — {N} CODEX-CATCH         |
| Codex apply  | {N} approved, {N} deferred to OPEN_QUESTIONS|
| Step 7 learn | {N} learnings written / skipped             |
| Step 7.5 map | {N} skill-edit candidates / none            |
+------------------------------------------------------------+
| OPEN_QUESTIONS  | {N}                                       |
| CRITICAL_GAPS   | {N}  (any P0 not approved counts)        |
| Files reviewed  | {N}                                      |
+============================================================+
```

If the user aborts mid-review, still print the box. Mark unrun steps as `skipped (user)`. Solves the "did I actually finish review?" ambiguity.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Step 0 audit takes too long, skip it" | The audit is 5 commands and 30 seconds. It catches the stash you forgot, the TODO marker still in the diff, the file you've touched 12 times this month — the structural drift signals you can't see while head-down in the patch. |
| "No need to load learnings, I remember the patterns" | Past-you wrote them down precisely because future-you doesn't remember them in fresh context. Confidence decay is part of the format — read them, don't reconstruct them. |
| "Cold review duplicates Step 5" | Same context produces same blind spots. Cold review with no diff context catches assumptions that Step 5 already absorbed and stopped questioning. The whole point is decorrelated context. |
| "Codex unavailable, just skip Step 6.5" | Mark `unavailable` in the completion box. Skipping silently turns a missing gate into an invisible gate. The box says what ran and what didn't — that's the contract. |
| "P2 is just nits, skip them" | P2 nits are the texture readers feel. List them in the box even if you defer. Done = P0/P1 zero, P2 listed and triaged, not P0/P1 zero and P2 hidden. |
| "I already reviewed this in my head while writing" | Writing the review forces the form. Half the issues surface only when you have to phrase them as findings. In-head review is a vibe, not a review. |
| "Patch-and-pray once more, no need to brief Codex with full picture" | After 3-4 failed patches the next patch is statistical noise. Stop, dump the full failure picture (what was tried, what broke, what's still broken), let a fresh-context reviewer (Codex) frame it. Recovery from "one more patch" loop is the longest debug. |
