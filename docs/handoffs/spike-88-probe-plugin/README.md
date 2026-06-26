# spike-88 discovery-scope probe (throwaway)

Purpose: settle the ONE live unknown in the inverted Fork B layout — does Claude Code plugin
discovery scan only `<plugin>/skills/*` or also walk a sibling `skills-cat/` symlink tree (which
would double-load a skill). Mirrors pandastack's structure minimally:

```
plugins/spike88probe/
  skills/probe-flat/SKILL.md          # the one real skill
  skills-cat/demo/probe-flat -> ../../skills/probe-flat   # category symlink view (sibling of skills/)
```

No scripts, no network, no deps, no secrets. Nothing here writes to ~/.claude.

## Install — run by Panda ONLY, after authorization (these touch the Claude plugin surface)

```
/plugin marketplace add /Users/panda/site/skills/pandastack-worktrees/88-forkb-spike/docs/handoffs/spike-88-probe-plugin
/plugin install spike88probe@spike88probe
```

Then start a fresh session / reload and check the skill list:
- `spike88probe:probe-flat` appears **once**  → inverted layout SAFE (discovery = skills/ only).
- appears **twice**                            → double-load (discovery scans skills-cat too).

## Uninstall (always run after the test)

```
/plugin uninstall spike88probe@spike88probe
/plugin marketplace remove spike88probe
```
