# First session — a 15-minute software-work walkthrough

New to Verbs? This 15-minute pass proves discovery, routing, and artifact
creation. Finishing the resulting build may take a full sprint.

## 0. Where you are (2 min)

Start in a writable software repository. Confirm the host sees the plugin:

```bash
python3 /absolute/path/to/verbs/scripts/verbs doctor --host claude --strict
# Or replace claude with codex.
```

## 1. Drill a problem (7 min)

`cd` into a repo or scratch dir, then:

```
/verbs:grill --brief "<a real problem you're working on>"
```

Bring a small real change, not a hypothetical. `grill --brief` challenges the
premise one question at a time, names alternatives, and writes a brief plus an
executable plan under `docs/`. Read both paths it prints.

## 2. Inspect the handoff (3 min)

The brief owns the reason and scope. The plan owns file-scoped tasks,
dependencies, and runnable acceptance checks. If either artifact mixes those
roles, fix it before execution.

## 3. Choose the next verb (3 min)

If the plan is ready for foreground execution:

```
/verbs:sprint --plan <slug>
```

Use the slug printed by `grill --brief`. A sprint can take 1-2 hours and ends in
`SHIPPED`, `PAUSED`, `FAILED`, or `ABORTED_BY_USER`. For at least three bounded
mechanical units, `/verbs:handover <slug>` is the explicit delegated path.

## What done looks like

- `grill --brief` wrote a brief and executable plan with checkable acceptance.
- `doctor --strict` confirmed the installed host matches the checkout.
- You selected `sprint` or `handover`; the 15-minute walkthrough does not claim
  that longer build work is already shipped.

## Next

- README § Skills — the 14-skill catalog.
- `RESOLVER.md` — routing guide ("which skill for X?").
- `INSTALL_FOR_AGENTS.md` — host install and migration truth.
