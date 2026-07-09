# Glossary

Terms **bolded** in [`SKILL.md`](SKILL.md), defined once here (single source of truth). Failure-mode vocabulary is adapted from mattpocock/skills `writing-great-skills`.

- **Predictability** — the agent taking the same _process_ every run (not the same output). The root virtue every other lever serves.
- **Leading word** — a compact pretrained concept (_fog of war_, _tracer bullets_, _tight_) that anchors behaviour in few tokens.
- **Context load** — tokens a skill costs by sitting in the window every turn (chiefly a model-invoked **description**).
- **Cognitive load** — the cost a **user-invoked** skill puts on the human, who must remember it exists.
- **Router contract** — one dispatch surface that names the skills and when to reach for each; cures piled-up cognitive load. (pandastack: `DISPATCH.md`.)
- **Description** — the model-facing line that does a skill's invocation work: states what it is and lists trigger **branches**.
- **Branch** — a distinct way the skill is used; different runs taking different paths through it.
- **Duplication** — the same meaning in more than one place; costs maintenance and tokens and inflates a meaning's rank on the ladder.
- **Information hierarchy** — the ladder ranking material by immediacy: in-skill step → in-skill reference → external reference.
- **Step** — an ordered action in `SKILL.md`; the primary tier.
- **Reference** — a definition, rule, or fact consulted on demand rather than executed in order.
- **Completion criterion** — the condition that tells the agent a step is done. Must be _checkable_; _exhaustive_ where it matters.
- **Premature completion** — declaring done before the artifact or step is verifiable.
- **Context pointer** — a link whose _wording_ decides when and how reliably the agent reaches an external file.
- **Progressive disclosure** — moving material down the ladder (out of `SKILL.md` into a linked file) so the top stays legible.
- **Co-location** — keeping a concept's definition, rules, and caveats under one heading so reading one part brings its neighbours.
- **Granularity** — how finely skills are divided; each cut spends one of the two loads.
- **Single source of truth** — one authoritative place for each meaning, so changing behaviour is a one-place edit.
- **Relevance** — whether a line still bears on what the skill does.
- **No-op** — a sentence whose deletion changes no behaviour; test by deleting it and asking what process would differ.
- **Sediment** — stale instructions accumulating across edits, especially retired paths, features, or branches.
- **Sprawl** — scope creep into another skill's territory.
- **Legwork** — the digging the agent does within the work, driven by a demanding completion criterion.
- **Hot/cold dispatch** (pandastack) — a skill needing >5K tokens of reference dispatches a sub-agent instead of loading it hot; progressive disclosure enforced.
