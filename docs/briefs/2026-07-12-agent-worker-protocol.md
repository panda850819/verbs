---
date: 2026-07-12
type: brief
source: grill
topic: Agent Worker protocol
tags: [brief, grill]
---

# Agent Worker protocol

## Problem

Claude Code and Codex already provide native subagents, but an explicit
read-heavy fan-out request has no shared, minimal task/result contract. Adding a
controller before proving a native-runtime gap would duplicate orchestration and
increase token and maintenance cost.

## Original premise

Add an Agent Worker layer with cross-runtime work orders, result normalization,
lifecycle events, resume, model routing, budgets, and evidence.

## Revised premise (after grill)

Agent Worker starts as a tiny protocol carried by the existing dispatch context.
Native Claude Code and Codex subagents remain the executors. The coordinator
owns synthesis, acceptance, and metrics; no new execution engine exists.

## Alternatives considered

- A: No-code protocol pilot — two read-only source workers plus one single-agent baseline — Add
- B: Thin contract integration — JIT dispatch contract using native subagents — Add
- C: Worker controller — scheduler, persistence, retries, and runtime adapters — Defer

## Chosen approach

B, earned by A. The pilot improved exhaustive source coverage but did not change
the architecture decision. It also proved worker-authored elapsed metrics were
unreliable. The coordinator measured 2.3 minutes while workers self-reported
9–22 minutes.

Executable plan: docs/plans/agent-worker-protocol.md

## Scope

In: explicit Agent Worker signal; maximum two depth-one read-only native
subagents; WorkOrder and WorkerResult fields; coordinator-owned verification and
metrics; handover boundary for mechanical write work.

Out: new skill, CLI, scheduler, queue, database, durable session, retry/resume
controller, dashboard, worker-to-worker communication, dynamic agent trees, or
concurrent writers.

## Next skill (recommended)

```
Shape: single-target-iterative
Reasoning: the protocol and its dispatch boundary need one foreground implementation and conformance pass.

Recommended skill:
  → /sprint agent-worker-protocol
```

## Gotchas surfaced

- WorkerResult is untrusted input; citations, diffs, and tests need coordinator verification.
- Runtime-native token usage may be unavailable; never ask a worker to invent it.
- Fan-out improved coverage, not the decision. It stays opt-in and read-heavy.
- Model and runtime resource envelopes must be recorded when comparing results.

## Gate Log

- Stage 1: inspected dispatch, handover, model anchors, runtime events, and prior pack audit.
- Stage 2: four user turns; the premise narrowed from controller to protocol.
- Stage 3: user approved running A, B, and C in order; evidence gates remain binding.
- Stage 4: A earned B; A did not earn C.
- Stage 5: brief saved to docs/briefs/2026-07-12-agent-worker-protocol.md.

## OPEN_QUESTIONS

- Revisit C only after repeated native failures involving resume, retry, cancel, or cross-runtime acceptance parity.
