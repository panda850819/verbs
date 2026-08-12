#!/usr/bin/env python3
"""Keep codebase design vocabulary canonical and routed through owning skills."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESOURCE = (ROOT / "lib/codebase-design.md").read_text(encoding="utf-8")
GRILL = (ROOT / "skills/productivity/grill/SKILL.md").read_text(encoding="utf-8")
SURVEY = (
    ROOT / "skills/engineering/improve-codebase-architecture/SKILL.md"
).read_text(encoding="utf-8")
MANIFEST = (ROOT / "manifest.toml").read_text(encoding="utf-8")
RESOLVER = (ROOT / "RESOLVER.md").read_text(encoding="utf-8")

for fragment in (
    "Depth is a property of the interface",
    "The deletion test",
    "The interface is the test surface",
    "One adapter means a hypothetical seam; two adapters make it real",
    "Accept dependencies, don't create them",
):
    assert fragment in RESOURCE, f"canonical design contract lost {fragment!r}"

assert not (ROOT / "skills/engineering/codebase-design").exists()
assert "[skill.codebase-design]" not in MANIFEST
assert "resources = [\"lib/codebase-design.md\"]" in MANIFEST
assert "`lib/codebase-design.md`" in GRILL
assert "interface, seam, depth tradeoff" in GRILL
assert "Read `lib/codebase-design.md` first" in SURVEY
assert "`grill` with `lib/codebase-design.md`" in RESOLVER
assert "`verbs:codebase-design`" not in RESOLVER

for consumer in (
    ROOT / "skills/productivity/grill/lib/codebase-design.md",
    ROOT / "skills/engineering/improve-codebase-architecture/lib/codebase-design.md",
):
    assert consumer.read_text(encoding="utf-8") == RESOURCE, consumer

print("codebase design resource contract: ok")
