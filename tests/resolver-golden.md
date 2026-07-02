---
date: 2026-05-04
last_updated: 2026-07-02
type: test
tags: [resolver, regression, b-test]
---

# Resolver Golden Test — pandastack v3.4.x

> Re-cut 2026-07-02 against the current 19-skill surface (15 core + 4 ext, `manifest.toml`). The v3.4 harness cut removed `dojo`, `checkpoint`, `freeze`, and `team-orchestrate` from the active runtime surface.

> 27 prompts × expected skill mapping. **Manual spec — not executed by CI** (no automated runner; `tests/run-all.sh` does not read this file). Run by hand before merging changes that touch skill descriptions, names, or the dispatch table; catches routing regressions from renames, new skills, or trigger tweaks.

## How to run

For each test case:

1. Inject prompt into a fresh Claude Code or Codex session with the context loaded as specified.
2. Observe which skill fires (via Skill tool invocation log or PreToolUse hook trace).
3. Compare to expected. Mark pass / fail.
4. If fail: examine which skill fired instead, decide if it's a description fix, a missing trigger, or an actual regression.

## Test cases

### Direct slash invocation (12 cases)

```
T01  /sprint fix hermes cron                    context: personal:developer  → sprint
T02  /sprint --quick rename one var             context: personal:developer  → sprint (quick mode)
T03  /office-hours product kill or pivot        context: -                   → office-hours
T04  /office-hours --quick points system        context: -                   → office-hours (quick mode)
T05  /grill 想做一個 points system              context: -                   → grill (default mode)
T06  /boardroom plans/q2-roadmap.md             context: -                   → boardroom
T07  /review                                    context: personal:developer  → review
T08  /ship                                      context: personal:developer  → ship (git mode)
T09  /handover auth-refactor                    context: personal:developer  → handover (sync)
T10  /debug auth test fails intermittently      context: personal:developer  → debug
T11  /ui build the settings page                context: -                   → ui
T12  /qa check the checkout flow                context: personal:developer  → qa
```

### Old-name aliases — frontmatter `aliases:`, 90-day grace (6 cases)

```
T15  /content-write draft this post             context: personal:writer     → write (alias, grace through 2026-08-04)
T16  /slowmist-agent-security check this repo   context: -                   → gatekeeper (alias)
T17  /tool-deepwiki repo                        context: -                   → deepwiki (alias)
T18  /knowledge-ship                            context: -                   → ship (alias, knowledge mode)
T19  /prep "ship the rename batch"              context: personal:developer  → FAIL (dojo/prep cut in v3.4.0; expect "skill not found", no silent wrong-fire)
T20  /weekly-retro-prep                         context: personal:writer     → FAIL (retro-prep-week cut in v2.0.0; expect "skill not found", no silent wrong-fire)
```

### Natural language triggers (6 cases)

```
T21  "is this MCP safe to install"              context: -                   → gatekeeper
T22  "I want to think out loud about X"         context: -                   → office-hours
T23  "poke holes in this plan before I commit"  context: -                   → boardroom
T24  "let me prep before I start"               context: personal:developer  → sprint or office-hours, depending on whether a concrete build topic is present
T25  "以前是好的，現在報錯" / "used to work, now broken"  context: -          → debug
T26  "這個頁面很醜，排版怪怪的" / "the layout looks wrong"   context: -          → ui
```

### Boundary anti-triggers (collision locks, 2 cases)

```
T27  "review my diff before the PR"             context: personal:developer  → review  (NOT debug — a diff to read, no error/crash/regression)
T28  "QA the checkout flow in the browser"      context: personal:developer  → qa      (NOT ui — runtime verification of real pages, not design taste)
```

### Degradation & precondition (3 cases)

```
T29  /sprint <topic>        env: ripgrep missing
                                                                          → sprint runs; capability-probe surfaces missing rg,
                                                                            stage-1 prep falls back to find, stage proceeds
T30  /office-hours <topic>  env: ~/.agents/AGENTS.md missing
                                                                          → office-hours ABORTS with capability-probe error,
                                                                            does NOT silently degrade (manifest: AGENTS.md is
                                                                            a substrate dep, capability-probe aborts without it)
T31  /boardroom <fuzzy idea, no prepared plan>
                                                                          → boardroom declines / routes to office-hours or grill;
                                                                            needs a PREPARED plan, does NOT convene a panel on an
                                                                            unformed idea (per its description's NOT clause)
```

## Expected pass/fail tracking

```
| Case | Expected | Actual | Pass/Fail | Notes |
|---|---|---|---|---|
| T01 | sprint | _ | _ | _ |
| T11 | debug | _ | _ | _ |
| T12 | ui | _ | _ | _ |
| T27 | review (not debug) | _ | _ | _ |
... fill in during run ...
```

## Acceptance criteria (v3.4.x cut)

- ≥18 / 20 pass (90%) on the deterministic set: direct slash + aliases + degradation/precondition (T01-T20, T29-T31 = 20 live cases after retired direct invocations are excluded). Allow 2 documented, fixable failures.
- ≥6 / 8 pass on the fuzzier set: natural-language triggers + boundary anti-triggers (T21-T28 = 8 cases). Description match is fuzzier; 75% threshold acceptable.
- 0 silent failures (every fail must produce an error message or a defensible wrong-skill trace, not a wrong skill firing unnoticed).

## Failure response protocol

For each fail:

1. Run `bash scripts/bootstrap.sh` to confirm substrate is healthy at test time.
2. Read the skill's frontmatter `description:` — does it contain the triggering keywords from the prompt?
3. If description gap: patch description, re-run that case only, then re-run `/skill-eval <name>` (the edit bumps `evaluated_skill_hash`).
4. If actual skill is wrong: this is a real regression; examine the resolver's matching logic and the `DISPATCH.md` row.
5. If silent failure (no skill fires): substrate or registration broken; check the plugin manifest + `lint-manifest-sync.sh`.

## Origin

- codex Blind Spot 2 (2026-05-04 review) — pandastack had no resolver regression test; all dogfood was manual.
- 2026-05-07: v1.4.0 dropped the `tool-` prefix on 6 wrappers; v1.4.1 removed `pdf`.
- 2026-06-29: full re-cut to v3.2.0. Dropped 13 cases for removed/overlay skills (`eng-lead`, `scout`, `brief-morning`, `write-ship`, `bird`, `slack`, `notion`, `summarize`, `agent-browser`, `curate-feeds`); fixed the boardroom case (persona-voice abort → no-plan precondition); added `debug` + `ui` triggers and the debug↔review / ui↔qa boundary anti-triggers; recounted acceptance criteria. Alias cases now track only the live `aliases:` declared in current SKILL.md frontmatter.
- 2026-07-02: v3.4.0 harness cut retired `dojo`, `checkpoint`, `freeze`, and `team-orchestrate`; direct and alias cases updated so retired invocations must fail loud instead of wrong-firing.
- 27 cases is enough to catch obvious breaks; not exhaustive (automation still pending).
