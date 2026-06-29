# pandastack on OpenClaw

OpenClaw support should be described by boundary first, not by plugin imitation.

Pandastack is not a Claude-only artifact, but the current repo still ships its most polished install surface through Claude Code and Codex.

For OpenClaw, the right question is:
what should run natively inside OpenClaw, and what should be delegated to a coding runtime.

## Recommended position

Treat pandastack on OpenClaw as a companion integration, not a cloned runtime.

That means:
- pandastack remains the source of methodology, skill content, flow definitions, and context conventions
- OpenClaw owns orchestration, routing, memory, and agent session policy on the OpenClaw side
- when coding-session execution is needed, OpenClaw can spawn or delegate to a runtime that is better suited for pandastack's coding workflows

This keeps the boundary clean.

## Three possible integration modes

### Mode 1, companion session delegation, recommended

OpenClaw does not need to consume every pandastack skill natively.
Instead, OpenClaw decides when a request should dispatch to a coding runtime that uses pandastack.

Typical shape:
- user speaks to OpenClaw
- OpenClaw classifies the task
- if the task needs a coding session or structured workflow, OpenClaw spawns or dispatches to a runtime with pandastack available
- the result is reported back to the user through OpenClaw

This mode is recommended for:
- feature implementation
- multi-file code changes
- review, QA, ship flows
- context-heavy workflows already modeled in pandastack

### Mode 2, native conversational skill adaptation

A small subset of pandastack methodology can be rewritten as OpenClaw-native conversational skills.

This fits skills that are mostly:
- questioning
- reframing
- review prompts
- retrospectives
- planning discipline

These are adaptations, not direct imports.
The host is different, so the delivery should match the host.

### Mode 3, direct skill-package consumption, experimental

OpenClaw may directly consume a transformed pandastack skill package in the future.

This is only worth doing if:
- OpenClaw's skill model is stable enough
- tool vocabulary mapping is clear
- install and update surfaces are reproducible
- the result is simpler than companion-session delegation

Today, treat this as experimental.

## What should stay on the OpenClaw side

OpenClaw should own:
- agent orchestration
- conversation routing
- platform or gateway behavior
- session spawning policy
- cross-agent coordination
- OpenClaw-specific memory or channel rules

Do not move those concerns into pandastack docs.

## What should stay on the pandastack side

Pandastack should own:
- shared workflow discipline
- coding and review methodology
- shared `lib/` primitives and conventions
- host-agnostic skill content where possible
- guidance for when to escalate into a coding runtime

## Practical recommendation today

If you want a working OpenClaw story now, use this rule:

- simple conversational guidance can be adapted into OpenClaw-native skills
- real coding workflows should dispatch into a runtime where pandastack already works well

That runtime might be:
- Claude Code
- Codex CLI
- another supported coding host in the future

The OpenClaw integration should focus on routing, not pretending the host model is identical.

## Suggested dispatch heuristic

Use a simple classification model.

| Task type | Recommended handling |
|---|---|
| typo, tiny config fix, single obvious edit | OpenClaw native, no pandastack required |
| plan, critique, weekly retro, high-level decision support | OpenClaw-native adapted pandastack methodology can work |
| multi-file feature, review, QA, ship, refactor, debugging gauntlet | delegate to pandastack-enabled coding runtime |

## Install story, current honest version

There is no first-class OpenClaw installer in this repo yet.

Current honest install story:
- use `skills/` (at the repo root) as the canonical content source
- adapt selected methodology into OpenClaw-native skills if needed
- or keep OpenClaw thin and dispatch to a pandastack-enabled runtime

Do not claim a polished native install surface until it exists.

## If you later formalize native OpenClaw support

Before saying OpenClaw is supported as a first-class host, define:
- install path
- update path
- tool mapping
- prompt or config injection point
- what gets transformed versus copied directly
- how issues should be reported

That work belongs in a dedicated host adapter or generation layer, not in ad hoc README text.

## Native versus companion boundary

Use this rule:

### Good candidates for native OpenClaw adaptation
- office-hours style questioning
- CEO-style scope challenge
- investigate-style debugging interview before runtime handoff
- retro or decision triage conversations

### Better as companion coding-runtime workflows
- build
- review
- qa
- ship
- long multi-file implementation
- workflows that assume a specific coding-session tool model

## What not to do

- do not present pandastack as a drop-in Claude plugin inside OpenClaw
- do not copy host-specific Claude assumptions into OpenClaw docs
- do not claim full native support if the real path is dispatch
- do not fork the entire stack just to rename a few tools

## Updating

If OpenClaw uses pandastack as companion methodology:
- update the pandastack repo as usual
- update any OpenClaw-side routing or prompt templates if their assumptions changed
- verify one real delegated task path

If OpenClaw later gets native adapted skills:
- track which skills are adapted
- note whether they are manual ports or generated artifacts
- document the update process per skill family

## Definition of done for an OpenClaw integration

OpenClaw support is ready to claim publicly only when:
- the integration mode is explicit
- install or routing steps are reproducible
- one real end-to-end task path was tested
- native versus delegated responsibilities are documented
- the issue-reporting surface is clear

Until then, the correct label is experimental.
