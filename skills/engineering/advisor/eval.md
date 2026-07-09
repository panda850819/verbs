---
type: skill-eval
skill: advisor
bucket: engineering
evaluated_skill_hash: fc37645494fbd1aeaffcc625753b049e10309d54
evaluated_at: 2026-07-09
rubric: writing-great-skills@1.1.0
---

# Eval — advisor

**Verdict: SOLID.** A thin (70-line), opinionated cross-model consult primitive whose load-bearing asset is a fail-loud guard — it refuses to fake decorrelation by asking the same model, and gates the unverified Codex→claude arm behind a probe. Default consult / `--panel` split is clean; only Completion criteria trails (stop conditions are prose, not a crisp artifact).

| Axis | Verdict | Evidence |
|---|---|---|
| Predictability | pass | L38-47 — Step 0 seat-locate is a deterministic env check (`CLAUDECODE=1` → Claude seat, else Codex seat), Step 1 is a deterministic `command -v` gate; the direction is derived, never hardcoded, so every run takes the same shape regardless of which runtime invokes it. |
| Description / invocation | pass | L4 — front-loads the load-bearing-judgment trigger ("design fork", "a plan before you commit", "second opinion", "red-team this", "多角度審") and reciprocates boundaries: NOT code-diff review (`review`), NOT sending build work out (`handover`), NOT self-interview (`grill`). |
| Completion criteria | weak | L58 — the stop conditions are stated in prose ("Stop after the gated list", "keep the judgment local" + banner on probe fail) rather than a single checkable completion artifact like `review`'s ASCII box; the default-consult path has no explicit "done when" line beyond "return the outside view". |
| Information hierarchy | pass | L26 — the Routing Boundary and the four numbered steps stay hot; the per-finding gate mechanics are pushed behind the `lib/gate-contract.md` pointer (L69) rather than inlined. |
| Leading words | pass | L47 — strong coined anchors carry the behaviour: "fail loud, never silently self-review", "judgment stays local, NOT self-reviewed", "A self-issued second opinion is not a second opinion", "Cross-model is the point" (L64), and "Keep every lone-critic finding" (L68). |
| Pruning | pass | whole file — 70 lines, under the ~80 guideline; no restated step, no ceremony, the seat-locate logic is inlined (4 lines) rather than spun into a lib it doesn't need. |
| Native parity | pass | L47 — names the native competitor directly: the model answering the judgment itself, or spawning a same-model critic. The delta is cross-MODEL decorrelation, and the skill refuses the native fallback loudly ("do not fake decorrelation by asking the same model") instead of silently degrading to it. |
| Granularity | pass | L51/L60 — the default single-consult vs `--panel` blind-critique split earns its load: one is a narrow read for a fork, the other a decorrelated panel for an expensive-if-wrong plan; the panel is explicitly frequency-gated, not a gratuitous mode. |
| pandastack conformance | pass | frontmatter — `name` = folder (`advisor`), required fields present (`name`/`description`/`user-invocable: false`); the `lib/gate-contract.md` pointer resolves repo-root (same as `review`); advisory `reads`/`writes`/`forbids`/`domain` declared; paired with `handover` as inbound/outbound halves without overlapping its exec role. |

## Why it's good
The asset is the anti-fake-decorrelation guard. The failure mode a cross-model consult must never hit is "the binary wasn't reachable so I quietly asked the same model and called it a second opinion" — that produces false confidence, the worst outcome. The skill hard-stops on that (L47) and additionally gates the one unverified arm (Codex→`claude -p`) behind a `claude -p 'ping'` probe (L48), degrading loudly to "judgment stays local" rather than to self-review. Zero-config seat detection (L42) means the same skill works from either runtime without a mode flag, and the direction follows the token economics (expensive seat reaches out, cheap seat keeps the bulk local). `--panel` absorbs boardroom's whole mechanism (mutual blindness, keep-lone-findings, per-finding gate) but upgrades it from same-model to cross-model, which is the stronger decorrelation axis.

## Top fixes
1. L58 — give the default-consult path one checkable completion line (e.g. "done when: the outside view is returned to the caller, tagged as outside-voice, un-incorporated") so Completion criteria stops trailing; the `--panel` path already ends on the gated list.
2. L48 — the Codex→`claude -p` probe is described but the ship-gate ("only after this probe is green") lives in prose; once verified on the machine, record the green result so the arm can enable without re-reasoning it each session.
3. L51 — the Claude-seat "Fable subagent when same-provider depth is what you want" option is a soft fork; name when to prefer it over `codex exec` (depth vs decorrelation) or drop it to keep the default single-pathed.

## Behavioral cases
- trigger `I'm about to commit to this schema design — am I sure?` -> expected process: recognise a load-bearing, expensive-if-wrong fork -> Step 0 locate seat (`CLAUDECODE=1` → Claude) -> Step 1 `command -v codex` (probe) -> Step 2 `codex exec` a narrow one-shot with the fork + minimal context -> return the outside view as outside-voice, caller decides; never auto-incorporate.
- trigger `red-team this replatform plan before I start` -> expected process: expensive-if-wrong plan -> Step 3 `--panel` with 2-3 blind cross-model critics (1 sonnet + 1 codex + at most 1 opus), distinct lenses, keep every lone finding, per-finding gate; stop after the gated list.
- anti-trigger `review my branch before the PR` -> should NOT fire (routes to `review`, code-diff review; advisor is judgment consult, not diff review).
- anti-trigger `finish building these three files` -> should NOT fire (routes to `handover`, which sends mechanical build work OUT to Codex; advisor pulls judgment IN, never executes).
- degrade case `Codex seat, claude not on PATH` -> Step 1 prints `ADVISOR: no cross-model binary on PATH (claude) — judgment stays local, NOT self-reviewed` and stops; does not ask GPT to critique its own output.
