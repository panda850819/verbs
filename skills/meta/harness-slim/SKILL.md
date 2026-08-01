---
name: harness-slim
description: |
  Audit and reduce a live multi-runtime agent harness after adoption. Use for
  installed skill/plugin parity, cold-start context, routing overlap, available
  usage evidence, or human-attention load. Produces a reversible proposal; it does not mutate
  the harness.
reads:
  - repo: AGENTS.md
  - repo: CLAUDE.md
  - cli: git
  - cli: codex
  - cli: claude
writes:
  - cli: stdout
domain: shared
classification: hybrid
user-invocable: true
---
# Harness Slim

This is the **post-adoption harness evaluator**. `gatekeeper` decides whether
an external artifact is safe to adopt; `review` checks a code diff;
`harness-slim` compares the live source, installation, runtime, context, and
attention surfaces after adoption.

## Contract

- Audit read-only. Propose before any move; execution routes through `careful`
  and the host's normal issue/worktree flow.
- Treat responsibility overlap as the prune signal. Counts and usage are
  supporting evidence, never deletion authority.
- Keep `actual_invocation`, `dispatch_selection`, and `load_proxy` separate.
  A skill-file read is load evidence, not invocation.
- Preserve trust, permission, data-loss, and external-write gates unless a
  replacement proves the same behavior.

## Audit

1. Read the host contract and machine-state documentation. Resolve the
   authoritative source manifest, installed registrations/caches, cold-start
   context, available doctor commands, and usage evidence. Missing paths remain
   named evidence gaps; do not invent defaults.
2. Run read-only doctors first. Report source truth, installed truth, and live
   runtime truth independently; one green surface cannot mask another red one.
3. Inventory what hosts actually register. Marketplace/catalog availability,
   unregistered files, remote tools, and optional overlays are separate
   surfaces.
4. Normalize usage by event semantics and coverage. Zero-use pruning requires
   at least 30 days, 20 eligible opportunities for that skill, and verified
   outcome coverage. Lifetime counters cannot prove a windowed zero.
5. Use only usage evidence the host actually exposes. Name its event semantics,
   window, denominator, and coverage before drawing a conclusion. Unknown
   denominators remain `Rate: UNAVAILABLE`; zero observed use remains
   `NO CONCLUSION`, and unresolved causality stays `NEEDS TRACE`. Verbs no
   longer supplies a usage denominator; without host evidence, zero-use pruning
   is unavailable and the audit proposes no usage-based retirement. Every
   candidate is propose-only; the audit edits no Skill, test, or host state.
6. Audit context. Measure content actually present at cold start and classify
   each instruction as **always-on**, **deferred**, or **task-local**. Tool
   recipes, examples, and domain detail default to deferred loading. Name one
   owner and absorber for every duplicate responsibility.
7. Audit attention. Long-running or parallel routes need a checkable exit,
   plateau/budget bound, quiet background behavior, and aggregated reporting.
   Preserve one foreground judgment lane. Resolve unknowns before long
   execution; use independent maker/verifier contexts only when subjective or
   high-risk output lacks a deterministic check.
8. Classify each surface exactly once: **Keep**, **Slim**, **Resource**,
   **Maintainer-only**, **Overlay**, or **Retire**. A major model change earns
   paired with-skill/without-skill fixtures before retirement.

## Output

```text
Harness slim
Core health: green | red
Runtime surface: source / installed / live
Usage evidence: source, window, event kinds, coverage, eligible sample
Context: always-on / deferred / task-local, bytes or observed tokens
Attention: foreground lane, background exits, aggregation, verifier policy
Keep / Slim / Resource / Maintainer / Overlay / Retire: owner + evidence
Backups: required paths for a later move
Verification: commands + observed results
```

Stop after the proposal. A later execution must preserve backups, rerun every
red-capable doctor, and prove cold-start parity.
