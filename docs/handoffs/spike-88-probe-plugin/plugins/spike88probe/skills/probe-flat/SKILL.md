---
name: probe-flat
description: Throwaway probe skill for issue #88 discovery-scope test. Do not invoke. After install+reload, check whether this appears once or twice in the skill list, then uninstall the spike88probe plugin.
---

# probe-flat

This skill exists only to be counted in the loaded-skill list.

- If `spike88probe:probe-flat` appears **once** after install + reload → Claude plugin discovery
  scans `skills/` only. The inverted layout (real flat `skills/` + sibling `skills-cat/` symlink
  view) is SAFE.
- If it appears **twice** → discovery also walked the sibling `skills-cat/` symlink and double-loaded.
  Fix: keep the browsable `skills-cat/` outside the plugin's discovered root, or add a discovery
  ignore. (Does not change the B1 verdict.)
