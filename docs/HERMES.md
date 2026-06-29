# pandastack on Hermes

Hermes support exists today, but it is not the same shape as Claude Code. Hermes does not consume the Claude plugin manifest directly; it imports pandastack skill content as native Hermes skills.

## Consumption model: direct skill import

Hermes loads pandastack skill content from `~/.hermes/skills/`. Copy or symlink the skill directories you want:

```text
skills/   →   ~/.hermes/skills/<category>/<skill-name>/
```

This repo does not ship a first-class Hermes package manifest; packaging for Hermes is manual today. Import the subset you actually use rather than the whole tree.

### Good fits

- writing, research, review, or planning patterns with minimal local coupling
- host-agnostic skills that do not depend on Claude plugin semantics

### Known caveats

- imported skills lose any Claude-plugin-specific behavior; check tool-name mapping
- categorization under `~/.hermes/skills/` is your responsibility
- skills that assume local Panda-only CLIs may still fail if those dependencies are missing
- host-specific wording may need cleanup over time

## What Hermes owns

In the pandastack architecture Hermes is the **conductor** (see the README "Architecture" section): the lightweight layer that carries the judgment and conversation a bare scheduler can't. It should usually own:

- cron scheduling and message delivery
- chat / platform triggers
- background execution and high-level orchestration
- reading a personal Linear workspace as the work-breakdown store, reducing it to "today's most urgent", and proposing over Telegram

Heavy execution (multi-file edits, repo work) is dispatched to a runtime worker (Claude Code / Codex) through the job contract, not run inside Hermes.

## What pandastack should not assume in Hermes

Do not assume:

- the Claude plugin marketplace exists
- `CLAUDE.md` is the install primitive
- plugin reload semantics match Claude Code
- all imported skills have a perfect tool-name match

Document the real Hermes path instead.

## Verification checklist

A Hermes integration is healthy when:

- install steps are reproducible
- update steps are documented
- one real invocation path was tested
- scheduler behavior and local interactive behavior agree

## Updating

Update the pandastack repo, then re-copy or re-symlink the changed skill folders into `~/.hermes/skills/`:

```bash
cd ~/site/skills/pandastack && git pull
# then re-copy / re-symlink the changed skills into ~/.hermes/skills/
```

Re-run the target Hermes flow or cron dry-run.

## Support level

Current support level for Hermes:

- supported as conductor / host via direct skill import
- not yet a first-class packaged host in this repo

That remains the public claim until pandastack ships a dedicated Hermes packaging surface.
