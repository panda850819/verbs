# Adding a Host to pandastack

pandastack should be treated as a stack package, not a single-runtime plugin.

The source of truth is the shared content under `plugins/pandastack/`:
- skills
- flows
- personas
- contexts
- command conventions
- path tokens and host assumptions

A host integration is the thin layer that makes that content usable inside one runtime.

## Goal

When adding a new host, the target is simple:
- keep pandastack content canonical in one place
- adapt install surface per host
- adapt tool names and path references per host
- document what is native, what is bridged, and what is unsupported

Do not fork the methodology unless the host truly cannot express the same behavior.

## Layer model

| Layer | Responsibility |
|---|---|
| pandastack content | Skills, flows, personas, contexts, conventions |
| host adapter | Path rewrites, tool rewrites, frontmatter filtering, install path |
| runtime | Claude Code, Codex, Hermes, others |
| scheduler, optional | Hermes cron, launchd, Claude CronCreate, external orchestrators |

## What counts as a host

A host is any runtime or orchestrator that wants to consume pandastack content.

Examples:
- Claude Code
- Codex CLI
- Hermes
- OpenCode

A host is not required to support everything.
A valid host integration may support only:
- direct skill loading
- spawned-session delegation
- plan-only or review-only usage

The important thing is to state the support boundary clearly.

## Required decisions before adding a host

Before writing any adapter or install doc, answer these questions.

### 1. Consumption model

Choose one primary model:
- direct skill loading
- generated host-specific skill package
- spawned companion session
- mixed model

Definitions:

| Model | Meaning |
|---|---|
| direct skill loading | The host reads pandastack skills directly from an installed path |
| generated host-specific skill package | pandastack content is transformed into a host-specific output tree |
| spawned companion session | The host does not run pandastack natively. It spawns another runtime that does |
| mixed model | Some skills are native, others dispatch to another runtime |

### 2. Install surface

Decide:
- where files live
- whether install is clone, symlink, copy, marketplace, or generated output
- how updates propagate

### 3. Tool vocabulary

Map pandastack assumptions to the host:
- read tool
- write tool
- edit or patch tool
- shell or exec tool
- subagent or session spawn tool
- browser or web-fetch tool

If a capability does not exist, document the degradation path.

### 4. Path and state model

Decide:
- what replaces `~/.claude/` assumptions
- whether the host has a stable home directory for skills
- whether state is writable in cron or sandboxed sessions
- whether `AGENTS.md` or another file is the instruction entry point

### 5. Boundary of support

State explicitly:
- what works today
- what works only with a bridge or adapter
- what is experimental
- what is unsupported

## Host integration checklist

A host integration is ready only when all items below are answered.

### Content adaptation
- skill content can be loaded or generated without manual per-skill rewriting
- host-specific path leakage is either rewritten or documented
- host-specific tool wording is either rewritten or documented
- unsupported sections are suppressed or clearly marked

### Installation
- install steps are written as copy-paste commands
- update steps are documented
- uninstall steps are documented if installation leaves persistent files

### Verification
- there is a concrete verification command or flow
- at least one real skill invocation was tested
- README and host-specific doc agree on status and install path

### Maintenance
- versioning impact is clear
- user-visible changes are recorded in `CHANGELOG.md`
- the host-specific doc tells users how to report issues

## Minimal host contract

Every supported host should have a document or config that answers these fields.

| Field | Meaning |
|---|---|
| host name | Runtime name |
| install model | clone, marketplace, generated, symlink, dispatch |
| skill root | Where the host reads pandastack content |
| instruction entry | `CLAUDE.md`, `AGENTS.md`, runtime config, or prompt injection |
| tool mapping | How pandastack actions map to host tools |
| update model | how users pull new versions |
| support level | first-class, supported, experimental |

## Recommended file layout

Today pandastack does not yet ship a generator pipeline like gstack. Until it does, use docs-first host support.

Recommended layout:

```text
README.md
CHANGELOG.md
docs/
  ADDING_A_HOST.md
  HERMES.md
  OPENCLAW.md
plugins/pandastack/
  skills/
  agents/
  contexts/
  .claude-plugin/
  .codex/
  .codex-plugin/
```

If pandastack later adds generated host outputs, extend this with a host registry or adapter directory.

## Recommended progression

Add hosts in this order:

1. document the host boundary
2. make install and update steps reproducible
3. verify one real invocation path
4. only then automate generation or packaging

Do not start with automation if the boundary is still unclear.

## Host-specific guidance

### Claude Code
- canonical first-class host today
- plugin marketplace install surface exists
- local marketplace dogfood loop exists
- `/reload-plugins` is the primary reload mechanism

### Codex CLI
- supported through native skill discovery
- install surface is clone + symlink
- the main burden is tool vocabulary and path mapping

### Hermes
- treat Hermes as two possible integrations:
  - direct skill host
  - scheduler and dispatch trigger
- if a workflow depends on context injection, document the mechanism

### OpenClaw
- decide first whether the host should consume pandastack directly or spawn a companion coding runtime
- keep OpenClaw-specific orchestration on the OpenClaw side
- do not force Claude plugin assumptions into OpenClaw docs

## When to fork content

Forking skill content should be rare.
Only do it when at least one of these is true:
- the host lacks a required tool model and no rewrite can preserve intent
- the host interaction pattern is fundamentally different
- the host needs a conversational skill where pandastack assumes a coding session

If the difference is only:
- install path
- tool names
- instruction file name
- update mechanism

then use adaptation, not a content fork.

## Author workflow when adding a host

1. Define the host boundary in a dedicated doc.
2. Add or update install instructions.
3. Add a verification flow.
4. Update `README.md` runtime support table if user-visible support changed.
5. Update `CHANGELOG.md` if user-visible behavior changed.
6. Test the real install path.
7. Only after that, add automation if repeated manual work is obvious.

## Definition of done

A new host is ready to claim in README only when:
- install steps are reproducible
- update steps are documented
- one real invocation path was tested
- support boundary is explicit
- issue-reporting inputs are known

If any of those are missing, mark the host experimental.