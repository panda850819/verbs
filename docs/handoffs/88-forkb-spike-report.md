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
| #5 lint | **no lint change needed** — original `-type d` lint stays green; skills-cat is a sibling of skills/, invisible to the scan | `lint` → OK 26 in sync (skills-cat untracked, not counted) |
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

## NOT VERIFIED — the one residual risk (live runtime; blocker before bulk)
- **Double-discovery**: does Claude plugin discovery or Codex bootstrap scan beyond `skills/` and
  also pick up `skills-cat/<cat>/<name>/SKILL.md` (via symlink) → loading `sprint` twice?
  - Low risk by construction: lint scans `skills/` only; Codex symlinks `skills/` only; native plugin
    discovery convention is `skills/`. skills-cat is a sibling.
  - Still needs live confirmation. Repro: fresh Claude session with plugin on this branch → confirm
    `pandastack:sprint` appears exactly once; `bash scripts/conformance-smoke.sh codex` likewise.
  - If discovery DOES scan skills-cat → either move skills-cat outside the plugin's discovered root,
    or add it to a discovery ignore. (Cheap fix, but must be confirmed.)

## RECOMMENDATION / next
1. Inverted layout verified for everything except live double-discovery (#1/#2).
2. Bulk: because `skills/` is untouched, the full category view (all 26 symlinks under skills-cat/)
   carries the SAME single risk (double-discovery) as this 1-skill spike — so once #1/#2 confirm no
   double-load, bulk is a low-risk mechanical add (1 symlink per skill), proposed as a separate issue.
3. Push branch + open draft PR for review only on Panda's go (push = external action).
