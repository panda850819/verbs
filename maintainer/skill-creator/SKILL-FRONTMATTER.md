# Verbs skill frontmatter spec

> Contract for `skills/<name>/SKILL.md` frontmatter in Verbs and compatible skill packs.

## Why this exists

The frontmatter is the contract between a skill and the hosts that consume it: Verbs declares what each skill is, and downstream hosts read it to surface, validate, and route.

Without a contract, the `name` field drifts (`verbs:X` / `ps-X` / `X` coexist) and optional fields multiply ad-hoc. Drift makes the resolver brittle and migration costly.

## Scope

This spec covers:

- Required and optional top-level keys
- Naming rules (`name` field)
- HOT / COLD field classification (which fields end up in the runtime skill index)

This spec does not cover:

- Skill body content style (left to individual skill conventions)
- Trigger phrasing (left to skill author)
- Hard length budgets — see "On length" below

## Frontmatter format

YAML-style frontmatter delimited by `---` at the top of `SKILL.md`. Inline scalars or `|` block scalars both acceptable.

```yaml
---
name: <skill-folder-name>
description: <one-paragraph trigger sentence>
user-invocable: true | false
# optional below
allowed-tools: <tool patterns>
version: <semver>
type: skill | flow | lib
---
```

## Required fields

| Field | Rule |
|---|---|
| `name` | Must equal the skill's folder name. Plain. No `verbs:` or `ps-` prefix. The prefix belongs to the consumer side (Claude Code plugin namespace, etc.), not the content. |
| `description` | Trigger paragraph. Should be short and concrete enough for an AI runtime to decide whether the skill applies. See "On length". |
| `user-invocable` | Boolean. `true` marks a user-invoked-only skill that the human must call by name; `false` marks a model-dispatched skill that the runtime may choose from its description. |

### Description cost rule

User-invoked-only skills (`user-invocable: true` and not model-dispatched) carry
a one-line human-facing description with trigger lists stripped. Model-invoked
skills keep rich "Use when" / "Triggers" phrasing because the description is
the routing surface.

### Dependency rule

A user-invoked-only skill body may reference model-invoked skills, never another
user-invoked-only skill. If the workflow needs that much user memory, put the
routing in a model-dispatched router instead.

## Optional fields

| Field | Rule |
|---|---|
| `allowed-tools` | Tool-pattern allowlist for runtimes that honour it (e.g. Claude Code). |
| `version` | Semver string. Bumped on user-visible behavior change. |
| `type` | `skill` (default), `flow` (multi-step orchestration), or `lib` (helper consumed by other skills). |

Other top-level keys are not warned and not blocked. Stacks may extend.

## Advisory firewall fields (audit metadata)

`reads`, `writes`, `forbids`, `domain`, and `classification` are optional
advisory audit metadata. Current hosts do not enforce them as a per-skill
security boundary. Reference adapters under `hooks/` are separate and activate
only when a host registers them. The Marketplace Plugin registers its three
documented adapters; portable and manual skill installs remain hook-free.

## HOT / COLD classification

AI runtimes typically build a **skill index** in the system prompt: every available skill's `name` + `description` is loaded into context at session start. The body of `SKILL.md` is loaded only when the skill is invoked.

This means:

- **HOT** (in skill index, every session): `name`, `description`
- **COLD** (loaded on invocation): `allowed-tools`, `version`, `user-invocable`, `type`, body

Implication for skill authors: keep HOT fields focused. The COLD area is where details belong.

## On length

This spec deliberately does not codify a character or token budget for any field. Reasons:

- Token counting varies across models and tokenizers. A fixed number creates false precision.
- Downstream tools that read budget numbers from a spec may convert them into hard truncation, causing premature output cutoffs.
- Discipline is qualitative: short is good because it improves cache stability and resolver discrimination, not because of a magic number.

Validators may emit informational signals on long descriptions but should not warn or fail on length alone.

## Validation

`bash scripts/lint-manifest-sync.sh` checks each `skills/<bucket>/<skill>/SKILL.md` against this spec.

Status levels:

- **pass** — required fields present, `name` matches folder
- **warn** — known drift (`name` carries `ps-` or `verbs:` prefix, `name` mismatches folder)
- **fail** — no frontmatter, or required field missing

A `fail` should block publication; `warn` is reported but does not block.

## Migration

Existing skills are not auto-rewritten. Run `bash scripts/lint-manifest-sync.sh` to see drift, fix when convenient. A future `--fix` mode may auto-rewrite drift; this spec does not require it.
