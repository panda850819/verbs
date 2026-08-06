---
slug: grill-default-close
date: 2026-07-18
type: plan
source: grill
brief: docs/briefs/2026-07-18-grill-default-close.md
execution: code
status: shipped
delivered_by: https://github.com/panda850819/verbs/pull/253
---

# Collapse grill to one skill with a default structured close — executable plan

> WHAT only. WHY is in the brief (`brief:` above). Agents read this file; per-task `status:` is DERIVED from git at execute time, never hand-edited mid-sprint.

## Tasks

### grill-default-close-T01 — grill SKILL.md: default-close + verbal opt-out
- scope: skills/productivity/grill/SKILL.md
- detail: fold the `--brief` "mode" into the default flow (drill → Stage A/B/C
  always run unless opted out); delete the `--brief` flag framing; add a
  chat-only opt-out to the Stopping rule that short-circuits Stage A/B/C when a
  "quick / just talk / 不用寫檔" signal is present, leaving only the chat log;
  keep the wayfinder map-exit branch intact.
- acceptance: `grep -c -- '--brief' skills/productivity/grill/SKILL.md` returns 0; `grep -qi 'opt-out\|chat-only\|不用寫檔' skills/productivity/grill/SKILL.md` succeeds; `grep -qi 'wayfinder' skills/productivity/grill/SKILL.md` still succeeds.
- depends-on: none
- status: todo

### grill-default-close-T02 — sweep every `grill --brief` reference to `grill`
- scope: DISPATCH.md, RESOLVER.md, skills/productivity/wayfinder/SKILL.md, manifest.toml
- detail: rewrite each `grill --brief` mention to `grill` and adjust surrounding
  prose so the sentence still reads correctly (e.g. "chart via `grill`",
  "grill's structured close"); confirm wayfinder charting text still points at
  the map-exit.
- acceptance: `grep -rn -- 'grill --brief' DISPATCH.md RESOLVER.md skills/ manifest.toml` returns nothing.
- depends-on: grill-default-close-T01
- status: todo

### grill-default-close-T03 — manifest description + RESOLVER row + version bump
- scope: manifest.toml, RESOLVER.md
- detail: update `[skill.grill]` description to name the default-close behaviour;
  update the `verbs:grill` RESOLVER catalog row and the two grill lines in the
  skill-relationship section so none advertise a `--brief` flag; bump
  `[manifest] version` 0.10.1 → 0.11.0.
- acceptance: `grep -q '0.11.0' manifest.toml` succeeds; RESOLVER `verbs:grill` row contains no `--brief`.
- depends-on: grill-default-close-T02
- status: todo

### grill-default-close-T04 — regenerate loaders via sync
- scope: .claude-plugin/, .codex-plugin/, .agents/plugins/, skills/*/lib/, resource index
- detail: run `python3 scripts/verbs sync`; commit the regenerated files; do not
  hand-edit any generated output.
- acceptance: `python3 scripts/verbs sync` exits 0 and a second run leaves `git status` clean (determinism).
- depends-on: grill-default-close-T03
- status: todo

### grill-default-close-T05 — CHANGELOG entry
- scope: CHANGELOG.md
- detail: add a `v0.11.0` section describing grill's default structured close,
  the removal of the `--brief` flag, and the chat-only verbal opt-out.
- acceptance: `grep -q 'v0.11.0' CHANGELOG.md` succeeds.
- depends-on: grill-default-close-T03
- status: todo

### grill-default-close-T06 — full suite green
- scope: tests/
- detail: run the verification suite; fix any drift or lint failure the change
  introduced.
- acceptance: `bash tests/run-all.sh` exits 0.
- depends-on: grill-default-close-T04, grill-default-close-T05
- status: todo
