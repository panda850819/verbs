# pandastack skill frontmatter spec

> Contract for `skills/<name>/SKILL.md` frontmatter in pandastack and any pandastack-compatible stack.

## Why this exists

Stack content (skills) and stack framework (pdctx) are different layers. The frontmatter is the contract between them: pandastack declares what each skill is, pdctx and downstream runtimes (Claude Code, Codex CLI, future tools) read it to surface, validate, and route.

Without a contract, the `name` field drifts (`pandastack:X` / `ps-X` / `X` all coexist in the current corpus) and optional fields multiply ad-hoc. Drift makes the resolver brittle and migration costly.

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
# optional below
allowed-tools: <tool patterns>
version: <semver>
user-invocable: true | false
type: skill | flow | lib
---
```

## Required fields

| Field | Rule |
|---|---|
| `name` | Must equal the skill's folder name. Plain. No `pandastack:` or `ps-` prefix. The prefix belongs to the consumer side (Claude Code plugin namespace, etc.), not the content. |
| `description` | Trigger paragraph. Should be short and concrete enough for an AI runtime to decide whether the skill applies. See "On length". |

## Optional fields

| Field | Rule |
|---|---|
| `allowed-tools` | Tool-pattern allowlist for runtimes that honour it (e.g. Claude Code). |
| `version` | Semver string. Bumped on user-visible behavior change. |
| `user-invocable` | Boolean. `true` if the skill is surfaced as `/<name>` to the user. |
| `type` | `skill` (default), `flow` (multi-step orchestration), or `lib` (helper consumed by other skills). |

Other top-level keys are not warned and not blocked. Stacks may extend.

## Advisory firewall fields (audit metadata)

`reads`, `writes`, `forbids`, `domain`, and `classification` are optional
per-skill fields originally specified for the Layer 5 firewall (see
[docs/firewall-l5.md](docs/firewall-l5.md)). On the public pandastack surface
they are **advisory audit metadata only** — nothing in the public stack enforces
them at PreToolUse time. The enforcing hook ships in the private `pdctx` overlay;
the public firewall is 4 enforced layers (L1–L4) plus this 1 advisory layer (L5).
Authors may declare them to document intent and feed the overlay, but must not
rely on them as a security boundary on the public surface. High-blast Bash
commands are hard-blocked by the separate global `pretooluse-destructive-guard.sh`,
not by these fields.

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

`pdctx skill-validate <stack-path>` checks each `skills/*/SKILL.md` and `plugins/*/skills/*/SKILL.md` against this spec.

Status levels:

- **pass** — required fields present, `name` matches folder
- **warn** — known drift (`name` carries `ps-` or `pandastack:` prefix, `name` mismatches folder)
- **fail** — no frontmatter, or required field missing

`pdctx publish-check` blocks publication when any `fail` is detected. `warn` is reported but does not block.

## Migration

Existing skills are not auto-rewritten. Run `pdctx skill-validate` to see drift, fix when convenient. A future `--fix` mode may auto-rewrite drift; this spec does not require it.
