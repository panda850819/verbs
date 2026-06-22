# Skill Context Schema

Pandastack skills may declare static context metadata in `SKILL.md`
frontmatter. These fields are **advisory audit metadata** documenting a skill's
intended access. The L5 PreToolUse firewall that would have consumed them was
retired with the `pdctx` overlay; nothing reads them at runtime.

## Fields

```yaml
reads:
  - vault: knowledge/**
  - repo: docs/briefs/**
  - cli: rg
writes:
  - vault: Blog/_daily/*.md
  - repo: docs/briefs/*.md
  - cli: stdout
forbids:
  - file: /Users/panda/site/knowledge/work-vault/**
  - cli: git push --force
domain: personal
classification: hybrid
```

`reads` lists paths, tools, or resources the skill may inspect.

`writes` lists paths, tools, or resources the skill may mutate or emit to.

`forbids` lists resources the skill must not touch even if the active
context would otherwise permit them.

`domain` is one of `personal`, `work`, or `shared`.

`classification` is one of:

- `read`: reads only, no intentional mutation.
- `write`: writes files or external records.
- `exec`: executes commands or external actions as the primary behavior.
- `hybrid`: mixes read, write, and command behavior.

## Access Entries

Each `reads`, `writes`, and `forbids` item must use:

```text
<source>: <target>
```

Known sources:

- `vault`: a vault-relative glob, for example `Blog/_daily/*.md`.
- `repo`: a repository-relative glob, for example `docs/briefs/**`.
- `file`: an explicit filesystem path outside repo or vault, for example
  `/tmp/morning-briefing-smoke.md`.
- `cli`: a command name or command prefix, for example `git` or
  `git push --force`.
- `mcp`: an MCP tool name or glob.
- `runtime`: a runtime capability such as `subagent`.

Path targets must not contain `..`, NUL bytes, or a leading `~`. Absolute
paths are only allowed for `file:` entries. Quote `**` in YAML when needed:

## vault: Resolution

`vault:` always resolves against the **primary vault root**
(default: `~/site/knowledge/obsidian-vault`). Patterns are
joined with that root at runtime: `vault: Blog/_daily/*.md` expands to
`<vault-root>/Blog/_daily/*.md`.

For resources outside the primary vault (for example, a sibling work-vault),
use `file:` with absolute paths:

```yaml
forbids:
  - file: /Users/panda/site/knowledge/work-vault/**
```

Using `vault: work-vault/**` in `forbids` is a common mistake — it expands
to `<primary-vault>/work-vault/**` which typically matches nothing; use `file:`
with an absolute path instead. Quote `**` in YAML when needed:

```yaml
reads:
  - repo: "**"
```

## Defaults

All fields are optional for backward compatibility. A skill with no context
metadata is still valid. The defaults are:

```yaml
domain: shared
classification: read
reads: []
writes: []
forbids: []
```

Missing metadata is not an error — these fields are advisory.

## Migration

Backfill high-use skills first. Do not guess: list only resources the skill
body explicitly reads, writes, executes, or forbids. If a resource is unclear,
omit it and leave the skill in a less restrictive state until the owner
reviews it.

## Status — retired

The L5 firewall that would have consumed `reads` / `writes` / `forbids` at
PreToolUse time was implemented in the `pdctx` overlay, now removed. These
fields remain as advisory documentation of intent; nothing enforces them. See
[docs/firewall-l5.md](firewall-l5.md).
