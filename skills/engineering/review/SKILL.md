---
name: review
description: |
  Use when asked to "review", "check my code", or before creating a PR. NOT UI/browser (qa), prepared-plan critique (advisor --panel), or lightweight single-pass diff checks.
reads:
  - repo: "**"
  - repo: CLAUDE.md
  - repo: AGENTS.md
  - repo: docs/briefs/**
  - repo: docs/learnings/**
  - repo: lib/gate-contract.md
  - repo: lib/learning-format.md
  - repo: lib/learning-recall.md
  - repo: lib/model-anchors.md
  - repo: lib/trigger-first-skill-evolution.md
  - repo: skills/engineering/review/lib/cross-model-transport.md
  - repo: skills/engineering/review/lib/rationalizations.md
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
user-invocable: false
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

1. Read verbs config from `CLAUDE.md` or `AGENTS.md` (whichever the project uses). Bind the path variables used below from it: `{main}` = configured main branch (default `main`), `{learnings_dir}` = configured learnings dir (default `docs/learnings`). Use these resolved values everywhere they appear.
2. Run `git branch --show-current`. If on the main branch, stop: "Nothing to review — you're on main."
3. Run `git diff origin/{main} --stat`. If no diff, stop.
4. Get the full diff: `git diff origin/{main}`

## Step 2: Load Learnings (recall)

Run the learnings recall per [`lib/learning-recall.md`](../../../lib/learning-recall.md): derive the review topic from the changed files + diff keywords, pull the top 3-5 relevant learnings from `{learnings_dir}`, and INJECT them:

```bash
grep -rl "relevant-file-path" {learnings_dir}/ 2>/dev/null   # by changed path
grep -rl "keyword" {learnings_dir}/ 2>/dev/null               # by diff keyword / function name
```

This step was historically listed but skipped (measured: 0 fires across 375 sessions) — it is now mandatory and must **change the review, not just list titles**. For each surfaced learning, apply confidence decay (`effective = max(0, confidence − floor(days_since_created / 30))`; `observed`/`inferred` lose 1 pt per 30d; `user-stated` never decays; skip effective < 3) and state in one line whether it bears on this diff. A learning flagging a known pitfall in a changed file is a finding, not a footnote. If nothing relevant surfaces, print `(no relevant prior learning)`.

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

Use the host's available isolated-agent mechanism. Verbs defines the three review lenses and their output contract; agent implementation, model selection, and global dispatch policy remain host concerns.

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
- **Deep-module lens (refactor / replatform / keep-vs-rewrite diffs only):** judge each touched module by depth — a deep module hides substantial implementation behind a narrow interface; a shallow one leaks complexity through a wide interface, so callers carry what the module should have absorbed. Before endorsing a seam (where a strangler-fig cut lands, where a rewrite boundary goes), state the module's depth and where the seam sits; a keep-vs-rewrite verdict with no depth named is a vibe, not a review — the same bar as "can't state the bug's mechanism in one sentence → not ready to fix it". Flag a change that makes an already-shallow module shallower (more surface, same leak), or a seam drawn mid-module instead of at a natural interface. Format: `[P2] file — shallow module / seam mis-placed — Fix: name the interface the complexity should hide behind`.

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

## Step 6.5: Cross-Model Adversarial Review

**Launch in parallel with Step 6.** This is an internal review transport, not an
`advisor` invocation. `advisor` rejects code-diff review by design. Materialize
the raw diff and use the file/stdin, size, isolation, and opposite-seat contract
in `skills/engineering/review/lib/cross-model-transport.md`, which resolves the
verified role from `lib/model-anchors.md`. Never embed a raw diff in a command
argument and never truncate it silently.

Prompt contract:

```
Review this PR diff as an independent adversarial reviewer.
Report only real defects as [P0|P1|P2|P3] file:line — issue — fix.
Terse, no praise, max 8 findings. Prioritize concurrency, object lifetime,
auth/permission gates, migration safety, and error-path correctness.
```

**Outside Voice Integration Rule:** findings are informational only. Each must
be explicitly approved by the user before it lands in the final report or a
follow-up commit. Cross-model consensus is a strong signal; do not auto-elevate
priority or confidence based on consensus alone.

Merge with Steps 5-6 findings:
- matching finding → tag `CROSS-MODEL CONFIRMED`, retaining the original confidence;
- novel finding → tag `OUTSIDE-CATCH, suggested P{N}` and request approval;
- contradiction of a clean assessment → present both opinions.

`N` responses go to the Completion Summary's `OPEN_QUESTIONS` count.

## Step 7: Surface Learning Candidates

After review completes (including cold review), evaluate whether any non-obvious pattern was discovered.

Test: "Would this save time in a future session on this codebase?"

If yes, check `{learnings_dir}` for an existing learning with a similar key.
- If a match exists: cite it and emit a one-line `seen again` candidate.
- If no match exists: emit a full candidate using `lib/learning-format.md`.

Do not write or update the learning store. Persistence belongs to the
host/project.

Guard escalation (propose-only): if the flaw is a bug class seen before (grep `{learnings_dir}` for the signature) or is mechanically checkable, propose one structural guard and name the exact file it would add: `scripts/lint-<class>.sh`, `tests/<class>-test.sh`, or a hook under `hooks/`. Never auto-create the guard during review.

If nothing worth recording: skip silently. Not every review produces learnings.

## Step 7.5: Route caught flaws back to the skill (propose-only)

After Step 7, for each confirmed flaw, apply the propose-only flaw-routing rule in `lib/trigger-first-skill-evolution.md` (map to the skill whose anti-pattern/checklist table should have caught it; propose only, never edit the target skill, never during an autonomous build). For each mapping, emit ONE line in the review result:

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
| Step 6.5 xmdl| ran / unavailable — {N} OUTSIDE-CATCH       |
| Outside apply| {N} approved, {N} deferred to OPEN_QUESTIONS|
| Step 7 cand  | {N} learning candidates / skipped           |
| Step 7.5 map | {N} skill-edit candidates / none            |
+------------------------------------------------------------+
| OPEN_QUESTIONS  | {N}                                       |
| CRITICAL_GAPS   | {N}  (any P0 not approved counts)        |
| Files reviewed  | {N}                                      |
+============================================================+
```

If the user aborts mid-review, still print the box. Mark unrun steps as `skipped (user)`. Solves the "did I actually finish review?" ambiguity.

## Common Rationalizations

Anti-bypass table tying each shortcut to the failure it causes: `@skills/engineering/review/lib/rationalizations.md`.
