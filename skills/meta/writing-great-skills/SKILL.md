---
name: writing-great-skills
description: |
  Reference for writing and editing Verbs skills well — the vocabulary and principles that make a skill predictable, plus the checkable scorecard `skill-creator --eval` scores against. Consult when authoring, splitting, pruning, or reviewing a SKILL.md. The construction-quality SSOT (counterpart to lib/quality-rubric.md, which scores artifacts, not skills).
version: 1.1.0
user-invocable: false
type: skill
---

# Writing Great Skills

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same _process_ every run, not producing the same output — is the root virtue; every lever below serves it.

**Bold terms** are defined in [`GLOSSARY.md`](GLOSSARY.md). This is the construction-quality SSOT: it scores the SKILL.md itself, not the artifact a skill produces (that is `lib/quality-rubric.md`). `skill-creator --eval` binds this file as its criteria; the creator self-checks against it before declaring a new skill done.

## Invocation

Two choices, trading different costs:

- **Model-invoked** keeps a **description**, so the agent fires it autonomously and other skills can reach it. It pays **context load** — the description sits in the window every turn. Mechanics: write a model-facing description with rich trigger phrasing.
- **User-invoked** strips the description from the agent's reach: only the human, by name. Zero context load, but it spends **cognitive load** — _you_ are the index that must remember it. Mechanics: `user-invocable: true`; the `description` becomes a human-facing one-liner.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. When user-invoked skills multiply past memory, use the pack's `DISPATCH.md` as the routing table instead of adding another router skill.

## Writing the description

A model-invoked **description** states what the skill is and lists the **branches** that trigger it. Every word is **context load**, so prune harder than the body:

- **Front-load the leading word** — it does the invocation work.
- **One trigger per branch.** Synonyms renaming one branch are **duplication**. Collapse them.
- **Cut identity already in the body.** Keep triggers + any "when another skill needs…" reach clause.

## Information hierarchy

A skill mixes two content types — **steps** and **reference** — placed on the **information hierarchy**, a ladder by how immediately the agent needs the material:

1. **In-skill step** — an ordered action in `SKILL.md`. Each ends on a **completion criterion**: make it _checkable_ (done vs not-done) and, where it matters, _exhaustive_. "Every heading enumerated" is checkable and exhaustive; "reviewed the structure" is neither. A demanding criterion forces the **legwork** that does the real work; a vague one invites **premature completion**.
2. **In-skill reference** — a rule or fact consulted on demand; often a flat peer-set, which is fine.
3. **External reference** — pushed out of `SKILL.md` into a linked file, reached by a **context pointer**, loaded only when the pointer fires.

**Progressive disclosure** is the move down the ladder so the top stays legible. A **branch** is a distinct way the skill is used; inline what every branch needs, push behind a pointer what only some reach. **Co-location**: keep a concept's definition, rules, and caveats under one heading.

Verbs note: the **hot/cold dispatch rule** is progressive disclosure with teeth — a skill that must read >5K tokens of reference dispatches a sub-agent rather than loading it hot.

## When to split

**Granularity** spends one of the two loads per cut, so split only when the cut earns it:

- **By invocation** — split off a model-invoked skill when a distinct **leading word** should trigger it, or another skill must reach it. You pay **context load** for the new always-loaded description.
- **By sequence** — split a run of **steps** when the steps ahead tempt the agent to rush the one in front (**premature completion**).

## Pruning

Keep each meaning in a **single source of truth**. Check every line for **relevance**. Then hunt **no-ops** sentence by sentence: does it change behaviour versus the default? Be aggressive — most prose that fails the no-op test should be deleted, not reworded. Verbs discipline: a skill body runs ~under 80 lines unless the extra length clearly earns itself.

## Leading words

A **leading word** is a compact concept already in the model's pretraining (_fog of war_, _tracer bullets_, _tight_ loop) that the agent thinks with while running the skill. It anchors a region of behaviour in the fewest tokens. It serves predictability twice: in the body it anchors _execution_; in the description it anchors _invocation_. Hunt for restatements a leading word can **collapse** ("fast, deterministic, low-overhead" → _tight_).

## Failure modes

Diagnose a struggling skill against these:

- **Premature completion** — ending a step before it is done. Defence: sharpen the completion criterion first; only then hide post-completion steps by splitting.
- **Duplication** — same meaning in two places; costs maintenance, tokens, and inflates a meaning's rank.
- **Sediment** — stale instructions from earlier edits; verify referenced paths, features, and branches still exist.
- **Sprawl** — scope creep into another skill's territory; cure with the ladder or a split.
- **No-op** — a sentence whose deletion changes no behaviour. A weak leading word (_be thorough_) is a no-op; fix with a stronger word, not a new technique.

## Native parity

**Native parity** treats every skill as competing with the harness's own defaults, which ship faster than this pack. Name the nearest native feature — built-in command, tool, or default behavior — and the delta that still earns the skill its slot: the lore plus reflex-override the model gets wrong despite understanding. A skill that cannot name its delta is a cut candidate at the next harness release; re-check this axis whenever the harness ships an overlapping feature.

This reference applies the same test to itself: generic model guidance can draft
a skill, while Verbs adds a checkable nine-axis scorecard plus its local
hot/cold, routing, and conformance rules.

## The scorecard

`skill-creator --eval` scores a skill on these axes — each **pass / weak / fail** with one cited line. The criterion for each lives in the section it names above; this is the index, not a second copy.

1. **Predictability** — see [Writing Great Skills](#writing-great-skills) (the root virtue).
2. **Description / invocation** — see [Invocation](#invocation) + [Writing the description](#writing-the-description).
3. **Completion criteria** — see [Information hierarchy](#information-hierarchy) (the step tier).
4. **Information hierarchy** — see [Information hierarchy](#information-hierarchy).
5. **Leading words** — see [Leading words](#leading-words).
6. **Pruning** — see [Pruning](#pruning) + [Failure modes](#failure-modes).
7. **Native parity** — see [Native parity](#native-parity).
8. **Granularity** — see [When to split](#when-to-split).
9. **Verbs conformance** — SKILL-FRONTMATTER.md valid; hot/cold dispatch honoured; ~<80 lines unless earned; `lib/` refs resolve.

Verdict shape: the skill's leading virtue (why it is good) + the top 1–3 line-cited fixes.

## Attribution

Principles, glossary, and failure-mode vocabulary adapted from [mattpocock/skills `writing-great-skills`](https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills). The scorecard and Verbs bindings are local additions.
