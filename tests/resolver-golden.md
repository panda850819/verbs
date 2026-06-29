---
date: 2026-05-04
last_updated: 2026-05-07
type: test
tags: [resolver, regression, b-test]
---

# Resolver Golden Test — pandastack v1.4.x

> **Status: stale (v1.4.x-era spec).** This regression set predates the current 25-skill surface. Cases referencing removed skills (`eng-lead` in T25/T30, `scout` in T19/T26, `brief-morning` in T13/T27, `write-ship`/`content-write` in T10/T16, the private-overlay `bird`/`curate-feeds`) and the deleted persona-voice boardroom (T30's "voice eng-lead missing" abort) no longer describe real behavior. New skills `debug` and `ui` have no cases yet. A v3.1 re-cut is a tracked follow-up; until then treat failures here as expected drift, not regressions.

> 30 prompts × expected skill mapping. Run before merging changes. Catches regressions when prompts → skill matching changes due to renames, new skills, or description tweaks. Updated 2026-05-07 for v1.4.0 tool-* prefix drop and v1.4.1 pdf removal.

## How to run

For each test case:

1. Inject prompt into a fresh Claude Code or Codex session with the context loaded as specified.
2. Observe which skill fires (via Skill tool invocation log or PreToolUse hook trace).
3. Compare to expected. Mark pass / fail.
4. If fail: examine which skill fired instead, decide if it's a description fix, a missing trigger, or an actual regression.

Automated runner is a follow-up — manual eval acceptable for v1.1 cut.

## Test cases

### Direct slash invocation (12 cases)

```
T01  /sprint fix hermes cron                    context: personal:developer  → sprint
T02  /sprint --quick rename one var             context: personal:developer  → sprint (quick mode)
T03  /office-hours product kill or pivot        context: -                   → office-hours
T04  /boardroom plans/q2-roadmap.md             context: -                   → boardroom
T05  /dojo "fix hermes weekly retro cron"       context: personal:developer  → dojo
T06  /prep "ship the rename batch"              context: personal:developer  → dojo (alias /prep)
T07  /grill 想做一個 points system              context: -                   → grill (default mode)
T08  /office-hours --quick points system        context: -                   → office-hours (quick mode)
T09  /review                                    context: personal:developer  → review
T10  /ship                                      context: personal:writer     → write-ship (route by context)
T11  /ship                                      context: personal:developer  → ship (route by context)
T11b /handover auth-refactor                    context: personal:developer  → handover (sync)
T11c 把剩下的丟給 codex 做                        context: personal:developer  → handover
T12  /retro week                                context: -                   → retro-week
```

### Old-name aliases — 90-day grace (13 cases)

```
T13  /morning-briefing                          context: personal:writer     → brief-morning (alias)
T14  /weekly-retro-prep                         context: personal:writer     → FAIL (retro-prep-week was cut in v2.0.0; expect "skill not found")
T15  /feed-curator                              context: personal:knowledge-manager  → curate-feeds (alias)
T16  /content-write                             context: personal:writer     → write (alias)
T17  /tool-browser open https://example.com     context: -                   → agent-browser (alias, v1.4.0)
T18  /slowmist-agent-security check this repo   context: -                   → gatekeeper (alias)
T19  /harness-survey scan public ecosystem      context: -                   → scout (alias)
T19a /tool-bird read tweet                      context: -                   → bird (alias, v1.4.0)
T19b /tool-slack search                         context: -                   → slack (alias, v1.4.0)
T19c /tool-notion get page                      context: -                   → notion (alias, v1.4.0)
T19d /tool-deepwiki repo                        context: -                   → deepwiki (alias, v1.4.0)
T19e /tool-summarize https://...                context: -                   → summarize (alias, v1.4.0)
T19f /agent-browser ...                         context: -                   → agent-browser (no alias; canonical name kept)
```

### Natural language triggers (8 cases)

```
T20  "is this MCP safe to install"              context: -                   → gatekeeper
T21  "check this github repo for me"            context: -                   → gatekeeper
T22  "I want to think out loud about X"         context: -                   → office-hours
T23  "let me prep before I start"               context: personal:developer  → dojo
T24  "review this plan with all the leads"      context: -                   → boardroom
T25  "what would the staff engineer say about"  context: -                   → eng-lead (skill mode)
T26  "scout other harnesses for ideas"          context: -                   → scout
T27  "morning briefing into today's note"       context: personal:writer     → brief-morning
```

### Capability-probe degradation (3 cases)

```
T28  /sprint <topic>     env: ripgrep missing
                                                                          → sprint runs, capability-probe surfaces missing rg,
                                                                            stage 1 dojo falls back to find, stage proceeds
T29  /office-hours <topic>  env: ~/.agents/AGENTS.md missing
                                                                          → office-hours ABORTS with capability-probe error,
                                                                            does NOT silently degrade
T30  /boardroom <plan>      env: skills/eng-lead/ deleted
                                                                          → boardroom ABORTS at Stage 2 voice scope detection,
                                                                            error: "voice eng-lead missing"
```

## Expected pass/fail tracking

```
| Case | Expected | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| T01 | sprint | _ | _ | _ |
| T02 | sprint (quick mode) | _ | _ | _ |
... fill in during run ...
```

## Acceptance criteria for v1.1 cut

- ≥27 / 30 pass (90%) on direct slash + alias + capability-probe (T01-T19, T28-T30 = 22 cases). Allow 2 failures in this set if they're documented and fixable in v1.2.
- ≥6 / 8 pass on natural language triggers (T20-T27). Description match is fuzzier; 75% threshold acceptable.
- 0 silent failures (every fail must produce error message, not wrong skill firing without notice).

## Failure response protocol

For each fail:

1. Run `bash scripts/bootstrap.sh` to confirm substrate is healthy at test time.
2. Read the skill's frontmatter `description:` — does it contain triggering keywords from the prompt?
3. If description gap: patch description, re-run that case only.
4. If actual skill is wrong: this is a real regression; examine the resolver's matching logic.
5. If silent failure (no skill fires): substrate or registration broken; check plugin manifest.

Log all fails to `Inbox/cron-reports/2026-05-04-resolver-test-results.md` with verdict + patch action.

## Origin

- codex Blind Spot 2 (2026-05-04 review) — pandastack has no resolver regression test, all dogfood is manual
- v1.1 cut introduced 7 renames + 4 new flow skills + Layer 1/2/3 split
- 2026-05-07 update: v1.4.0 dropped the `tool-` prefix on 6 wrappers (added T17, T19a-T19e); v1.4.1 removed `pdf` skill (no test case needed — skill no longer resolves at all)
- 30 cases is enough to catch obvious breaks; not exhaustive (automation pending)
