---
title: Writing Great Skills
version: 1.1.0
type: lib
---

# Writing Great Skills

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same _process_ every run, not producing the same output — is the root virtue; every lever below serves it.

**Bold terms** are defined in
[`writing-great-skills-glossary.md`](writing-great-skills-glossary.md). This is
the construction-quality SSOT: it scores the SKILL.md itself, not the artifact
a skill produces (that is `quality-rubric.md` in this directory).

## Invocation

Two choices, trading different costs:

- **Model-invoked** keeps a **description**, so the agent fires it autonomously and other skills can reach it. It pays **context load** — the description sits in the window every turn. Mechanics: write a model-facing description with rich trigger phrasing.
- **User-invoked-only** strips the description from the agent's reach: only the human, by name. Zero context load, but it spends **cognitive load** — _you_ are the index that must remember it. Mechanics: `disable-model-invocation: true`; the `description` becomes a human-facing one-liner. (`user-invocable` gates the opposite, human, channel and stays `true` — see `SKILL-FRONTMATTER.md` "Invocation axes".)

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. When user-invoked skills multiply past memory, use the host pack's routing table instead of adding another router skill.

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

For Specs, briefs, Decision Maps, rejected-direction records, and other durable
prose, apply [`lib/durable-records.md`](../lib/durable-records.md). Enumerate the
proposition before trimming so actors, obligations, conditions, exceptions,
ownership, failures, and consequences survive without session narration.

Hunt **negation** the same way: state target behaviour positively wherever a positive form exists; keep a prohibition only as a hard guardrail (safety, data-loss, permission boundaries), and pair it with the replacement behaviour.

## Leading words

A **leading word** is a compact concept already in the model's pretraining (_fog of war_, _tracer bullets_, _tight_ loop) that the agent thinks with while running the skill. It anchors a region of behaviour in the fewest tokens. It serves predictability twice: in the body it anchors _execution_; in the description it anchors _invocation_. Hunt for restatements a leading word can **collapse** ("fast, deterministic, low-overhead" → _tight_).

## Failure modes

Diagnose a struggling skill against these:

- **Premature completion** — ending a step before it is done. Defence: sharpen the completion criterion first; only then hide post-completion steps by splitting.
- **Duplication** — same meaning in two places; costs maintenance, tokens, and inflates a meaning's rank.
- **Sediment** — stale instructions from earlier edits; verify referenced paths, features, and branches still exist.
- **Sprawl** — scope creep into another skill's territory; cure with the ladder or a split.
- **No-op** — a sentence whose deletion changes no behaviour. A weak leading word (_be thorough_) is a no-op; fix with a stronger word, not a new technique.

## Project overlays

Keep project truth in repository-owned instructions such as `AGENTS.md` and the
review references those instructions explicitly link. Review already reads that
surface; a repository may use it to supply known bug classes, real entry paths,
invariants, and relevant commands. Current code and tests remain authoritative.
Do not add a Verbs overlay registry, hidden discovery convention, router, or
project-memory layer. Rebase, retarget, and head rewrites invalidate checks or
comments bound to the old commits.

This contract adapts the repository-local overlay pattern from DeepSeek
Harness's MIT-licensed
[`dsh-code-review`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-code-review/SKILL.md)
and evidence freshness from
[`dsh-pre-push-checks`](https://github.com/deepseek-ai/deepseek-harness/blob/master/.agents/skills/dsh-pre-push-checks/SKILL.md).

## Native parity

**Native parity** treats every skill as competing with the harness's own defaults, which ship faster than this pack. Name the nearest native feature — built-in command, tool, or default behavior — and the delta that still earns the skill its slot: the lore plus reflex-override the model gets wrong despite understanding. A skill that cannot name its delta is a cut candidate at the next harness release; re-check this axis whenever the harness ships an overlapping feature.

This reference applies the same test to itself: generic model guidance can draft
a skill, while Verbs adds a checkable nine-axis scorecard plus its local
hot/cold, routing, and conformance rules.

## New skill contract checklist

Before registering a new skill:

1. Name the existing surface it extends or replaces.
2. Cite the matching `.out-of-scope/` precedent. If none exists, add a clear
   precedent before registration.
3. Make every required input visible in each output record that depends on it.
4. Give every terminal state one unambiguous result and completion condition.
5. State the stop boundary. Explicitly prohibit claiming, assigning, scheduling,
   tracker mutation, successor invocation, and execution unless the skill owns
   that side effect.
6. Define a required capability by semantics, not by one host's tool name. Name
   a host-specific transport only when that transport is the product capability,
   and state the fail-closed result when the semantic capability is unavailable.
7. Add the `RESOLVER.md` catalog row with concrete routing details and update
   the skill description.

## The scorecard

Score a skill on these axes — each **pass / weak / fail** with one cited line. The criterion for each lives in the section it names above; this is the index, not a second copy.

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
