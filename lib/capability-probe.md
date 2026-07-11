# Host capability probe

> Shared availability check for a Panda Verbs skill. It checks only the current
> working directory, packaged references, and tools declared by that skill.
> Identity, voice, memory, and project policy belong to the host.

## When to load

Load at the start of a multi-stage skill that will read packaged references,
write artifacts, or call optional CLIs. Atomic skills can check their one tool
at the callsite.

## Checks

Run only the checks declared by the skill and its `manifest.toml` row:

1. **Writable cwd**: `[ -d . ] && [ -w . ]`.
2. **Packaged references**: every `reads: repo:` path used by the run exists.
3. **Required CLIs**: every `requires` token for the selected operation resolves.
4. **Write parents**: create the parent of a declared output only when the skill
   is about to write that output.

Do not inspect `~/.agents`, a knowledge store, host identity files, credentials,
or another runtime's configuration.

## Requirement mapping

```text
cli:<name>   -> command -v <name>
npm:<pkg>    -> command named by the skill; install hint: npm install -g <pkg>
brew:<name>  -> command named by the skill; install hint: brew install <name>
pipx:<pkg>   -> command named by the skill; install hint: pipx install <pkg>
```

Core skills are markdown-first. Extension skills may require a public CLI for
their main operation. A missing optional integration can degrade only when the
skill names a real fallback. Otherwise stop with the install hint.

## Output

```text
== capability-probe (skill: {name}, tier: {core|ext}) ==
[1] writable cwd       : ok
[2] packaged refs      : ok
[3] required CLIs      : degraded (agent-browser missing; npm install -g agent-browser)
[4] write parents      : scaffolded (created docs/briefs/)

-> proceeding (degraded: [3], scaffolded: [4], blocked: none)
```

Use `ok`, `degraded`, `scaffolded`, or `blocked` precisely:

| State | Meaning | Action |
|---|---|---|
| `ok` | Requirement is present | Continue |
| `degraded` | A named fallback preserves the requested result | Continue and name the fallback |
| `scaffolded` | A declared output parent was created | Continue |
| `blocked` | The requested result cannot be produced | Stop with one concrete fix |

The probe checks availability, not correctness. A binary on `PATH` still needs
the skill's normal runtime verification.

## Skill obligation

A multi-stage skill declares only what it actually uses:

```yaml
capability_required:
  - writable-cwd
  - lib/push-once.md
  - cli:<name>
```

Undeclared tools or references are a construction defect. Do not expand this
probe into a global environment doctor.
