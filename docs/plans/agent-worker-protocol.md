---
slug: agent-worker-protocol
date: 2026-07-12
type: plan
source: grill
brief: docs/briefs/2026-07-12-agent-worker-protocol.md
execution: code
status: todo
---

# Agent Worker protocol — executable plan

> WHAT only. WHY is in the brief above. Status is derived from acceptance checks.

## Tasks

### agent-worker-protocol-T01 — Add the opt-in native-worker contract
- scope: DISPATCH.md
- acceptance: `grep -F 'Explicit Agent Worker / parallel read-only research' DISPATCH.md` returns exactly one row; the Agent Worker section contains `objective`, `scope`, `deliverable`, `acceptance`, `permissions`, `budget`, `status`, `findings`, `evidence`, and `gaps`; it fixes maximum workers at two, disables nested delegation, and assigns metrics to the coordinator.
- depends-on: none
- status: todo

### agent-worker-protocol-T02 — Preserve the handover boundary
- scope: skills/engineering/handover/SKILL.md
- acceptance: `grep -F 'read-only Agent Worker' skills/engineering/handover/SKILL.md` states that native read-only fan-out does not route through handover and that mechanical write delegation still does.
- depends-on: agent-worker-protocol-T01
- status: todo

### agent-worker-protocol-T03 — Add a thin-contract conformance test
- scope: tests/agent-worker-contract-test.sh
- acceptance: `bash tests/agent-worker-contract-test.sh` passes, detects a seeded missing-field mutation, proves Claude and Codex SessionStart payloads include the protocol, confirms no Agent Worker skill or runner was added, and `bash tests/lint-suite.sh && bash tests/run-all.sh` reports zero failures.
- depends-on: agent-worker-protocol-T01, agent-worker-protocol-T02
- status: todo
