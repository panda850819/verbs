# Overlay extension

A personal / org overlay may be appended to this contract by the SessionStart hook. Resolution order:

1. Personal overlay: `~/.agents/overlays/using-pandastack.md` (override with env `PANDASTACK_OVERLAY`)
2. `${PANDASTACK_OVERLAY}` env var if explicitly set (escape hatch for non-standard layouts)
3. (no overlay loaded — public contract is self-contained)

The SessionStart hook MUST log explicitly which step matched. Silent fallback to a private path is a bug — fresh users without an overlay get no signal that the lifecycle map is running on public defaults only.

The overlay typically adds:
- Concrete vault / repo / memory paths bound to abstract slots above
- Private skill triggers (org-specific alerts, internal SOPs)
- Active dogfood / experiment windows

If no overlay loads, this public contract still works on its own — the lifecycle map degrades to abstract guidance.
