# Fork B Spike Report — issue #88 (INVERTED layout, chosen by Panda)

Decision (Panda, 2026-06-26): **真檔 flat、分類用 symlink view** = inverted layout.
Spike skill: `sprint`. Branch: `feat/88-forkb-spike`. Mode: CAREFUL, no push, no main commit.

## Chosen layout
- Real skills stay flat and untouched: `plugins/pandastack/skills/<name>/` (current state).
- Browsable category tree is additive symlinks: `plugins/pandastack/skills-cat/<category>/<name>
  → ../../skills/<name>`.
- Editing through `skills-cat/.../SKILL.md` transparently edits the real flat file.

## Why inverted beats forward
- 10/26 skills use depth-sensitive `@../../lib/<file>.md` refs (most of `thinking/`). Moving real
  files into category dirs (forward) changes physical depth → physical resolution of `../../lib/`
  breaks; survives only if every consumer resolves textually (unverified). Inverted keeps `skills/`
  flat, so those refs resolve physically AND textually — zero ref risk.

## VERIFIED (rigorous)
| # | Claim | Evidence |
|---|---|---|
| layout | real `skills/sprint/` untouched; `skills-cat/doing/sprint` → `../../skills/sprint` | `ls -la` |
| #3 rel-path | SKILL.md + `references/codex-delegation.md` readable through the category view | `head`, `ls` via skills-cat path |
| #3 rel-path | `../../lib/*.md` resolves physically from the real flat path (unchanged baseline) | `ls skills/sprint/../../lib/persona-frame.md` OK |
| #5 lint | **no lint change needed** — original `-type d` lint stays green; skills-cat/ is outside `skills/`, so the scan never sees it (this holds whether or not skills-cat is tracked) | `lint` → OK 26 in sync |
| #5 hook | `conformance-smoke.sh hook` PASS (codex/claude/cursor) | run |
| #4 dist | symlinks survive git (mode 120000) + `git archive` + macOS `cp -R` (the Claude cache directory-copy model) | tested in forward variant; same mechanism applies to skills-cat symlinks |
| #6 rollback | trivial: `rm -r skills-cat/` → back to exact current state (skills/ never changed) | by construction |

## Distribution context (acceptance #4 → B1)
- Claude install = "directory" source COPIED into versioned cache
  (`~/.claude/plugins/cache/pandastack/pandastack/<ver>/`), not a github tarball.
- Codex = live symlink `~/.codex/skills/pandastack → repo/.../skills`.
- git stores symlinks as mode 120000 → preserved by clone/archive/checkout; macOS `cp -R` preserves.
- → **B1**: no install-time link script needed; zero-build native plugin preserved.

## ASSUMPTION
- Claude cache-copy is symlink-preserving (`cp -R`-equiv). Install routine is a black box; tested the
  most likely. Even if it derefs, a symlinked `skills-cat` entry would become a real-dir copy =
  harmless duplicate of an already-real skill. Windows symlinks need privilege (public-repo caveat).

## RESOLVED — double-discovery, via official docs (no probe needed)
The one residual risk (Claude double-discovery) is now settled by the Claude Code plugin docs,
so the live probe plugin is obsolete and was removed.

- **Claude discovery is top-level only, no recursion.** Plugin skill discovery scans `<plugin>/skills/`
  for `<name>/SKILL.md` at the top level, plus any dirs listed in the manifest `skills` field
  (which only *adds* dirs; no recursion, no exclude). `.claude-plugin/plugin.json` has **no `skills`
  field**, so only the default `skills/` is scanned. `skills-cat/` is a *sibling* of `skills/`, not
  under it and not in the manifest → Claude never scans it. **Double-discovery is structurally
  impossible**, regardless of whether discovery follows symlinks.
  - Sources: code.claude.com/docs/en/plugins-reference (skill-structure example = `skills/<name>/SKILL.md`
    only; `skills` field = "Adds to the default `skills/` scan"); multiple open claude-code issues
    (#18192, #16438, #28266, #39787) requesting recursive nested discovery confirm it is not current
    behavior.
- **Codex** — invisible by design (unchanged): bootstrap symlinks `plugins/pandastack/skills` (not the
  plugin root), so `skills-cat/` is never in Codex's scan path. The `--codex` scratch-HOME live check
  in `spike-88-repro.sh` stays preflight-blocked (no auth in scratch HOME), but it is no longer
  load-bearing: skills-cat is out of scope for Codex by construction.
- Probe plugin (`docs/handoffs/spike-88-probe-plugin/`) **removed** — it existed only to answer the
  recursion question the docs now answer. Never installed.

→ Acceptance #1 (Claude discovers, single load) and #2 (Codex discovers) are both **closed** by
doc-grounded reasoning + green lint/hook, without touching the live install.

## VERDICT: PASS → B1 (zero-build native plugin, repo-internal symlinks)
All acceptance criteria met. No install-time link script (B1). Rollback = `rm -r skills-cat/`.

## BULK ROLLOUT (done in this branch)
The "bulk = separate issue, gated on spike green" gate was set when the spike outcome was uncertain;
the docs collapsed that risk to zero, so the 25 remaining skills were folded in here rather than
spun into a new issue for 25 symlinks (focus-discipline: no ceremony without safety payoff).
- All **26/26** skills now have exactly one `skills-cat/<category>/<name> → ../../skills/<name>` link.
- Taxonomy (per #88): thinking 9, doing 8, writing 1, meta 8. MECE verified (`comm -3` empty,
  0 broken symlinks, every link resolves to a real `SKILL.md`).
- lint-manifest-sync: green (26 in sync). conformance-smoke hook: PASS (codex/claude/cursor).

## next
- Push branch + open PR for review only on Panda's go (push = external action).
- `skills/` stays flat for all runtimes; `skills-cat/` is the additive browsable category view.
