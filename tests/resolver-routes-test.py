#!/usr/bin/env python3
"""Executable resolver contract for the slim specialist surface."""
from pathlib import Path
import re
import tomllib

ROOT = Path(__file__).resolve().parents[1]
manifest = tomllib.loads((ROOT / "manifest.toml").read_text())
resolver = (ROOT / "RESOLVER.md").read_text()
active = set(manifest["skill"])

assert "## Intake" in resolver
assert "Grilling is Project Contract behavior" in resolver
assert "## Specialist routing" in resolver
assert "## Native parity boundary" in resolver
assert "## GBrain boundary" in resolver

routing = resolver.split("## Specialist routing", 1)[1].split("## Native parity boundary", 1)[0]
rows = set(re.findall(r"^\| [^|]+ \| `([a-z0-9-]+)` \|", routing, re.M))
assert rows == active, (rows, active)

for name in active:
    paths = list((ROOT / "skills").glob(f"*/{name}/SKILL.md"))
    assert len(paths) == 1, (name, paths)
    frontmatter = paths[0].read_text().split("\n---\n", 1)[0]
    assert "description:" in frontmatter

for retired in (
    "advisor", "ask-boss", "product-planning", "backlog-refinement",
    "sprint-planning", "sprint-review", "setup-verbs", "to-spec",
    "to-tickets", "verbs:grill",
):
    assert f"`{retired}` |" not in resolver, retired

print(f"resolver exposes exactly {len(active)} specialist skills")
