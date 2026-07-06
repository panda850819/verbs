---
date: 2026-07-05
issue: 165
branch: ci/165-harness-mechanization
type: plan
---

# Plan — harness-mechanization (#165)

> Mechanize the rules layer: the weakest rule class (procedural gates as prose) moves into deterministic hooks and enforced contracts. Sources: brain concepts/rules-attention-mechanics, media/repos/miguok-fable-harness-personalized (design reference, MIT), media/articles/aihao-claude-fable-5-prompting-personalized (anti-overtrigger constraint). Base: main (includes #164 <judgment> block).

### harness-mechanization-T01 — verify-gate Stop hook
- scope: plugins/pandastack/hooks/stop-verify-gate.py (new), plugins/pandastack/hooks/hooks.json (add Stop entry)
- goal: deterministic Stop hook, design ported from fable-harness verify_gate.py (MIT; local clone at scratchpad for reference). Behavior: stdin hook JSON (transcript_path, stop_hook_active); stop_hook_active=true → exit 0 (block-once). Parse transcript JSONL entries AFTER the last real user prompt (string content, not tool_result arrays, not <command-name>/<local-command-*> prefixed). If any Edit/Write/NotebookEdit tool_use touched a code-extension file AND no Bash/shell tool_use command matches the test/verify regex → stdout {"decision":"block","reason":"[pandastack verify-gate] ..."} ; else exit 0 silent. ANY exception → exit 0 (fail-open; the gate must never break a session). Env kill-switch: PANDASTACK_VERIFY_GATE=off → exit 0 immediately. Python 3.9 compatible, stdlib only, no network, target <100ms. Reason string: one line, plain tone, no CRITICAL/ALWAYS (overtrigger).
- acceptance: `bash tests/stop-verify-gate-test.sh` passes (see T02); `python3 plugins/pandastack/hooks/stop-verify-gate.py < fixture` manually verified for block and allow paths
- depends-on: none
- status: todo

### harness-mechanization-T02 — verify-gate regression test
- scope: tests/stop-verify-gate-test.sh (new)
- goal: FIRST read tests/run-all.sh header + one existing test (e.g. tests/destructive-guard-test.sh) to learn conventions (self-contained, mktemp, offline, exit-code keyed), then write fixture-transcript cases: (1) code edit + no test cmd → block JSON on stdout; (2) code edit + pytest/bun test/bash tests/x.sh run after the edit → exit 0 silent; (3) .md-only edits → exit 0; (4) stop_hook_active=true → exit 0; (5) malformed/missing transcript → exit 0 (fail-open); (6) PANDASTACK_VERIFY_GATE=off → exit 0; (7) test cmd ran BEFORE the last user prompt but not after → block (stale green must not count).
- acceptance: `bash tests/stop-verify-gate-test.sh` passes; picked up by `bash tests/run-all.sh`
- depends-on: harness-mechanization-T01
- status: todo

### harness-mechanization-T03 — dispatch packet upgrade
- scope: skills/engineering/handover/references/codex-invocation.md, skills/engineering/handover/SKILL.md (payload enumeration lines only)
- goal: extend the XML payload contract with <non_goals> (explicit not-to-do list, ≥1 entry, guards against drive-by changes) and <stop_conditions> (out-of-scope file, compile/syntax error wall, secrets, deletion needed → stop and report) blocks after <constraints>. Harden <output_contract> prose: verification_summary with no run evidence MUST say "changed but not verified" (never "should work"); out-of-scope discoveries go in issues[] (report, don't fix). Do NOT change the result JSON schema (consumers: sprint codex-delegation classification). Keep wording principle-level — no rule bloat.
- acceptance: both new blocks greppable in codex-invocation.md; SKILL.md enumeration mentions them; result schema line unchanged; `bash tests/lint-suite.sh` green
- depends-on: none
- status: todo

### harness-mechanization-T04 — instruction-audit skill
- scope: skills/meta/instruction-audit/SKILL.md (new), skills/meta/instruction-audit/eval.md (new), manifest.toml, RESOLVER.md
- goal: FIRST read skills/meta/skill-creator/SKILL.md (conformance), skills/meta/writing-great-skills/SKILL.md (scorecard), skills/meta/skill-eval/SKILL.md + scripts/lint-eval-fresh.sh + an existing eval.md (hash format). Then create the manual skill: audit live instruction surfaces (~/.agents/AGENTS.md, ~/.claude/CLAUDE.md, ~/.agents/judgment-compact.md, pandastack skills) for (a) old-model-era compensation rules, (b) overtrigger language (CRITICAL/ALWAYS/NEVER on non-absolute rules), (c) step-lists replaceable by one principle, (d) cross-layer duplicates, (e) rules failing the admission test (no failure mode prevented / no behavior changed), (f) growth-budget breach (AGENTS.md ~200 lines). Output: candidate deletion/rewrite list with per-item reason + evidence line; NEVER auto-edit the audited files — human decides. Trigger: manual /instruction-audit, suggested at retro-week. MECE note vs skill-eval (scores one skill's construction) and cross-modal-review (reviews artifacts): this audits the live rule corpus for staleness/conflict. Frontmatter: user-invocable: true, classification per existing meta skills, forbids editing audited files.
- acceptance: `bash tests/lint-suite.sh` green (manifest-sync, eval-fresh+verdict for the new skill, refs-resolve, invocation-axis, meta-sync all pass)
- depends-on: none
- status: todo

### harness-mechanization-T05 — suite green
- scope: verification only
- goal: full deterministic suite passes with all units in.
- acceptance: `bash tests/lint-suite.sh` and `bash tests/run-all.sh` report 0 failed
- depends-on: harness-mechanization-T01, harness-mechanization-T02, harness-mechanization-T03, harness-mechanization-T04
- status: todo
