---
name: init
description: |
  Use once per project to initialize pandastack. Triggers on `/init`,
  "initialize pandastack", "set up this project". Detects project type,
  confirms detected values, writes pandastack config to CLAUDE.md (Claude
  Code) or AGENTS.md (Codex / other agent runtimes).
---

# Init

## Step 1: Detect

Auto-detect from the repo:
- Language/framework (package.json, Cargo.toml, pyproject.toml, go.mod, Gemfile)
- Test command (scripts.test, Makefile, etc.)
- Main branch (main or master)
- Existing CI (.github/workflows, .gitlab-ci.yml)

Done when language and main branch are resolved. If no test command is found, carry it forward as "not found" — do not block; Step 2 surfaces it for the user to fill in.

## Step 2: Confirm

Present detected values via AskUserQuestion. One question, all fields:

> pandastack detected:
> - Test: `{detected or "not found"}`
> - Main branch: `{main or master}`
> - Tag format: none
> - GitHub Release: false
> - Deploy command: none
> - Learnings dir: `docs/learnings`
>
> Adjust anything, or approve to continue?

## Step 3: Write Config

Pick the runtime's project-config file: `CLAUDE.md` for Claude Code, `AGENTS.md` for Codex / other agent runtimes. If both exist, write to whichever is canonical for the active runtime; if neither exists, default to `CLAUDE.md` when running under Claude Code and `AGENTS.md` otherwise.

Append to that file (create if needed):

```markdown
## pandastack

test: {test command}
main: {main branch}
tag: none
release: false
deploy: null
learnings: docs/learnings
```

## Step 4: Create Directories

```bash
mkdir -p docs/learnings/{patterns,pitfalls,architecture,preferences}
mkdir -p docs/checkpoints
```

## Step 5: Verify

Before claiming success, confirm the writes landed:
- The `## pandastack` block exists in the target config file (`grep -q '^## pandastack' <file>`).
- All four learnings dirs and the checkpoints dir exist (`docs/learnings/{patterns,pitfalls,architecture,preferences}`, `docs/checkpoints`).

If any check fails, report what is missing and stop — do not claim initialized. Only when all checks pass, output: "pandastack initialized. Run `/review` after your next change to start building learnings."
