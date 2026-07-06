---
name: instruction-audit
description: |
  Audit the live instruction corpus (AGENTS.md, CLAUDE.md, judgment-compact, pandastack skill bodies) for stale, duplicated, or overtriggered rules. Read-only: produces a candidate delete/rewrite/merge list; the human applies it.
version: 1.0.0
forbids:
  - edit: ~/.agents/AGENTS.md
  - edit: ~/.claude/CLAUDE.md
  - edit: ~/.agents/judgment-compact.md
  - edit: any skill body under audit
domain: shared
classification: tool
type: skill
user-invocable: true
---
# Instruction Audit

Audits the standing rule corpus a session actually loads — the whole instruction surface, not one skill — hunting rules that have gone stale, duplicate each other, or overtrigger. The trust model is read-only: this skill NEVER edits an audited file. Output is a candidate list; the human decides what ships.

Native competitor: pasting a file into chat and asking "review my CLAUDE.md". The earned delta: six named defect classes hunted exhaustively across ALL always-loaded layers at once (cross-layer duplicates are invisible one file at a time), greppable-quote evidence, and the hard read-only rule.

## Surfaces

Audit in this order — always-loaded files first, since their cost is paid every session:

1. `~/.agents/AGENTS.md` — the agent-agnostic contract (growth budget: ~200 lines)
2. `~/.claude/CLAUDE.md` — the Claude shim
3. `~/.agents/judgment-compact.md` — the judgment block
4. pandastack skill bodies (`skills/<bucket>/<skill>/SKILL.md`) — loaded per-invocation; audited for class (d) only, against layers 1-3 (construction quality of a single skill routes to `/skill-eval`)

## Defect classes

| Class | Hunt for | Test |
|---|---|---|
| (a) model-era compensation | rules hand-holding behavior a current strong model has natively | would deleting it change today's model's output? |
| (b) overtrigger language | CRITICAL / ALWAYS / NEVER on rules that have exceptions | a known exception exists — absolutism the model learns to discount |
| (c) step-list bloat | numbered procedures replaceable by one principle | can one sentence regenerate the same steps? |
| (d) cross-layer duplicate | same rule in two always-loaded files | near-match greppable across surfaces |
| (e) admission-test failure | rule that cannot name a failure mode prevented or a behavior changed | "what goes wrong without this line?" has no answer |
| (f) growth-budget breach | AGENTS.md over its ~200-line target | `wc -l` |

## Phases

### 1. Load the corpus

Read every surface above in full; record `wc -l` for each. Completion criterion: all four surfaces read whole and AGENTS.md line count noted for class (f).

### 2. Hunt per defect class

Walk surfaces 1-3 once per class (a)-(e); walk surface 4 (skill bodies) for class (d) only; run (f) on AGENTS.md. For every hit, quote the exact rule line — the quote must be greppable in the source file. Completion criterion: every class explicitly reported, including "no hits"; an unexamined class is not a clean class.

### 3. Write the candidate list

One item per finding in the format below, ranked by payoff: always-loaded surfaces first, then by lines freed. Then stop — hand the list to the human; apply nothing.

## Output Format

```
## Instruction audit — <date>
Corpus: AGENTS.md <n> lines (budget ~200) · CLAUDE.md <n> · judgment-compact <n> · <k> skill bodies

| # | Surface | Quoted rule line | Class | Reason | Proposed action |
|---|---|---|---|---|---|
| 1 | ~/.agents/AGENTS.md | "<exact line>" | (b) | exception X exists | rewrite: drop ALWAYS, name the exception |
| 2 | ... | ... | (d) | duplicates CLAUDE.md L<n> | merge: keep one home |

Classes with no hits: (a), (f)
```

Proposed action is one of **delete / rewrite / merge**. No edits are applied by this skill.

## Trigger

Manual only: `/instruction-audit`. Suggested cadence: during retro-week, or right before adding a new rule to an always-loaded surface — audit first, add second, so additions displace instead of accrete.

## Boundary (MECE)

- `pandastack:skill-eval` — scores ONE skill's construction against the writing-great-skills scorecard.
- cross-modal-review (gbrain) — reviews a work artifact via a second model.
- This skill — audits the live rule corpus across surfaces for staleness, conflict, and budget. Corpus-level and cross-file; never a single skill's quality score, never an artifact review.

## Anti-Patterns

- **Auto-fixing** — editing an audited file "while you're in there". The whole trust model is read-only; the human decides.
- **Paraphrased quotes** — a quoted rule line that is not greppable in its source is a phantom finding. Re-read and quote exactly; never reconstruct from memory.
- **Class (b) as a grep** — mechanically flagging every ALWAYS/NEVER. It fires only when a real exception exists; some absolutes are true.
- **Class (e) as a mood** — "feels unnecessary" is not the admission test; the item must name the missing failure mode.
- **Scoring skill quality** — one skill's construction routes to `/skill-eval`; here skill bodies are only checked for duplication against the always-loaded layers.
