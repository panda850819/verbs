# Slim the low-risk review path

Date: 2026-07-16
Entry: Slim the low-risk review path
Status: resolved
Issue: #248

## Decision

Ship a bounded low-risk fast path in `review` while preserving the existing
medium/high evidence contract. A review can stop after scope provenance, one
grounded correctness pass, coverage, and self-refutation only when the diff is
local and reversible and the pass finds no risk trigger, candidate finding,
coverage gap, or scope drift.

The fast path omits unused lenses, repo-learning recall, model anchors, and
empty scope-drift/cold-review fields. Any failed condition promotes into the
existing escalated path without repeating scope discovery.

## Candidate identity

- Host: Codex CLI `0.144.1`
- Model and effort: `gpt-5.6-sol`, `low`
- Base commit: `fd92f15f1e6d4c9f2f896b70d7c705f6f9262b60`
- Behavior-canary `review/SKILL.md` SHA-256:
  `4053ff167058ee26a5792d92984fead7fa25cd6edfd7307bdc9bc2601b01a562`
- Final candidate SHA-256:
  `71ac7c0185983699b8c4eb4145f4188c3b7e6a95e078a37ae8474c76bb85465e`.
  The post-canary change updates only the HOT description to name the fast
  path; the evaluated body is unchanged.
- Both canaries used fresh ephemeral, read-only sessions with user config,
  user rules, and automatic project-document loading disabled.

## Real canaries

### Low-risk README cleanup

Historical diff: `8831798^..8831798`.

The edited skill selected `risk: low`, returned the four-field compact format,
and correctly reported no findings. Its trace did not read
`lib/learning-recall.md` or `lib/model-anchors.md`; it emitted no lens list,
scope-drift field, or cold-review field.

- Prior treatment: 45,671 tokens.
- Edited treatment: 26,205 tokens.
- Reduction: 19,466 tokens, about 43%, with the same correct outcome.

### Trust-boundary guard change

Historical diff: `5bdee55^..5bdee55`.

The edited skill promoted to `risk: high`, loaded the escalated resources,
completed a cold review, and retained executable evidence. Direct probes
grounded four findings: shell-valid quoting bypass, `push --all` / `--mirror`
bypass, directory-change repo confusion, and benign Git subcommand false
positives. It also preserved coverage gaps, scope drift, and self-refutation.

- Prior treatment: 56,599 tokens and three grounded findings.
- Edited treatment: 72,858 tokens and four grounded findings.
- The extra high-risk cost bought a completed cold review and another
  reproducible bypass class; the fast path did not weaken this lane.

The read-only canary could not run fixture suites that create temporary git
repositories. Main-session verification ran the final candidate through the
full repository suite instead.

## Consequence

`review` remains EDIT at the audit level until field use confirms the new path,
but the measured avoidable low-risk cost has been removed. Version `0.10.1`
contains the candidate contract and a structural regression test. Future audit
runs should keep low and high token cost separate; averaging the two would hide
the intended risk tradeoff.
