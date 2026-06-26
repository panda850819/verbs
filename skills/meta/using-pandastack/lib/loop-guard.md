# Loop guard (3-strike rule)

Same file / same diagnostic / same fix variant tried 3+ times → STOP, do not attempt a 4th. Repo-root `lib/verify-the-test-loop.md` already hard-gates build/deploy phantom-bug class; this guard covers other loop classes (refactor circling, design back-and-forth, infra-config trial-and-error).

When triggered:
1. Stop attempting more variants.
2. Re-grill the premise: is the abstraction wrong? Is the loop verifying the right thing?
3. Consider `pandastack:checkpoint` to externalize state + restart cold.

Source: Mnilax Rule 6 office-hours 2026-05-24 (`~/site/knowledge/brain/inbox/briefs/2026-05-24-rule6-cross-agent-baton-aware-rituals.md`). Companion to brain-first protocol step 0 (session-start sync) in `~/.agents/AGENTS.md`.
