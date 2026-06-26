---
type: skill-eval
skill: freeze
bucket: engineering
evaluated_skill_hash: 2c1d203ec2c8aa8e63baa0206fd0191de0373c41
evaluated_at: 2026-06-26
rubric: writing-great-skills@1.0.0
---

# Eval — freeze

**Verdict: STRONG.** A dead-simple, single-responsibility guard: one job (lock edits to allowed paths), a deterministic ordered process, an exact greppable refusal message, and a clean inline unfreeze. Fully conformant with SKILL-FRONTMATTER.md and the established peer idiom (`careful`).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L21–L33 — the process is a fixed ordered sequence every run: parse allowlist (L21) → announce (L23–L29) → on each edit check membership (L30–L31) → refuse with a fixed string or proceed (L32). The rubric axis is "same *process* every run," and this process is deterministic. (It is prompt-enforced with no hook, but that is the canonical pandastack idiom for an in-session guard — the nearest sibling `careful` uses the identical self-policed "While Active" pattern with no hook, and SKILL-FRONTMATTER.md L59–L68 confirms even the advisory `forbids` fields are not runtime-enforced.) |
| Description / invocation | pass | L3–L6 — a clean model-facing description with three stated branches (lock to paths / blocks outside / `/unfreeze`). Having a `description` and no `user-invocable` flag IS the explicit model-invoked choice per the rubric (L20–L21 of writing-great-skills) and SKILL-FRONTMATTER.md (L48–L55, where `user-invocable` is optional); all 8 `doing/` peers do the same. The choice is not implicit. |
| Completion criteria | pass | L32 — "If not: **refuse the edit** and say: …" is binary and checkable (under allowed path → edit; else refuse with the exact string). |
| Information hierarchy | pass | L30 — the standing per-edit rule is correctly placed *after* the ordered On-Invoke steps; one file, nothing over-pushed, co-located. |
| Leading words | weak | L11 — "Lock editing scope to prevent accidental changes outside the working area" restates the description rather than collapsing to a compact pretrained anchor; the FREEZE/FROZEN caps carry the real invocation weight. This is the one genuine soft spot (and overlaps with pruning below). |
| Pruning | pass | L11 — only the one mild restatement noted above; body is 39 lines, well under the ~80 budget, no sediment, no sprawl, no other no-op. |
| Granularity | pass | L35 — unfreeze kept inline as the paired branch (`## Unfreeze`) rather than split into its own skill; correct, no distinct leading word earns a cut. |
| pandastack conformance | pass | L1–L7 — required fields `name` + `description` present and `name` matches the folder (SKILL-FRONTMATTER.md L41–L46); `version`/`type`/`user-invocable` are all OPTIONAL (L48–L55) so their absence is not a defect; `bash scripts/lint-manifest-sync.sh` emits no FAIL; body 39 lines < 80; no `lib/` refs to resolve. |

## Why it's good
The skill does exactly one thing and says so in seven body lines: parse paths, announce, then refuse out-of-scope edits with a fixed, greppable message (L32) and an explicit "never silently skip" (L33). The On-Invoke list (L21–L33) is a clean ordered sequence with concrete announce text, and unfreeze is co-located as the obvious paired branch (L35–L39) — no sprawl, no sediment, no over-splitting. It is fully conformant with SKILL-FRONTMATTER.md and mirrors the accepted `careful` guard idiom.

## Top fixes
1. L11 — drop the sentence that restates the description; replace the generic "lock editing scope" framing with a tighter anchor (e.g. "edit allowlist") used consistently in body and description. This is the only real lever; the skill is otherwise clean.
2. (optional) L30 — the guarantee is prompt-only and degrades over a long session. This matches every peer guard, so it is not a defect, but a one-line note that enforcement is best-effort agent-side (or, longer-term, routing the check through the `pretooluse-destructive-guard.sh`-style hook) would stop a user from over-trusting it as a hard boundary.

## Behavioral cases
- trigger `/freeze src/api/ tests/api/` → expected process: parse both paths as the allowlist (L21), announce FREEZE active with the two paths (L23–L29), then for every subsequent Edit/Write/NotebookEdit check membership and refuse with the FROZEN message if outside (L30–L33).
- anti-trigger `review my code before I open a PR` → should NOT fire; that is a review pass, routes to `review` (freeze locks an edit allowlist, it does not inspect or critique code).
