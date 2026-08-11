#!/usr/bin/env python3
"""Claude and Codex must agree on human-only skill entry points."""
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_HUMAN_ONLY = {
    "improve-codebase-architecture", "retro", "sprint", "sprint-planning",
    "sprint-review", "to-tickets",
}
claude_human_only = set()
codex_human_only = set()

for skill_file in sorted(ROOT.glob("skills/*/*/SKILL.md")):
    name = skill_file.parent.name
    frontmatter = skill_file.read_text(encoding="utf-8").split("\n---\n", 1)[0]
    if re.search(r"^disable-model-invocation:\s*true\s*$", frontmatter, re.M):
        claude_human_only.add(name)

    policy = skill_file.parent / "agents/openai.yaml"
    if policy.is_file():
        text = policy.read_text(encoding="utf-8")
        if re.search(r"^\s*allow_implicit_invocation:\s*false\s*$", text, re.M):
            codex_human_only.add(name)

assert claude_human_only == EXPECTED_HUMAN_ONLY, (
    f"Claude human-only drift: {sorted(claude_human_only)}"
)
assert codex_human_only == EXPECTED_HUMAN_ONLY, (
    f"Codex human-only drift: {sorted(codex_human_only)}"
)
assert claude_human_only == codex_human_only


def indirect_human_only_refs(text):
    return {
        name for name in EXPECTED_HUMAN_ONLY
        if re.search(rf"(?<![a-z0-9-]){re.escape(name)}(?![a-z0-9-])", text, re.I)
    }


# An implicitly available skill body must not become a dispatch bridge into a
# human-only skill. Human-facing cross-route documentation belongs in RESOLVER.
for skill_file in sorted(ROOT.glob("skills/*/*/SKILL.md")):
    name = skill_file.parent.name
    if name in EXPECTED_HUMAN_ONLY:
        continue
    leaked = indirect_human_only_refs(skill_file.read_text(encoding="utf-8"))
    assert not leaked, (
        f"{name} indirectly references human-only routes: {sorted(leaked)}"
    )

assert indirect_human_only_refs("Use `sprint` for this task.") == {"sprint"}
assert indirect_human_only_refs("Run /to-tickets next.") == {"to-tickets"}

for manifest in (".claude-plugin/plugin.json", ".codex-plugin/plugin.json"):
    text = (ROOT / manifest).read_text(encoding="utf-8")
    assert '"hooks"' not in text and "DISPATCH" not in text, (
        f"{manifest} is not skills-only"
    )

assert not (ROOT / "hooks").exists()
assert not (ROOT / "DISPATCH.md").exists()
print("OK: Claude and Codex agree on human-only entry points; plugins are skills-only.")
