# Layer 5 Firewall — retired

> **Status: retired.** The L5 per-skill firewall — and the L3 (MCP deny list) and L4 (context recipe) layers it relied on — was implemented in the `pdctx` overlay, which has been removed. Nothing reads the `reads` / `writes` / `forbids` / `classification` skill-frontmatter fields at runtime. They remain only as **advisory audit metadata** documenting a skill's intended access.

`hooks/pretooluse-destructive-guard.sh` can hard-block high-blast Bash commands.
The Marketplace Plugin registers it for Bash PreToolUse; portable and manual
skill installs remain hook-free. This narrow command guard does not restore the
retired per-skill firewall.

## The fields

`reads` / `writes` / `forbids` / `domain` / `classification` stay valid in `SKILL.md` frontmatter as documentation of intent. See [SKILL-FRONTMATTER.md](../SKILL-FRONTMATTER.md) for the full frontmatter spec. They are not enforced.

## History

The retired design consumed these fields at PreToolUse time to enforce a per-skill tool-argument allowlist: a session tracker wrote the active skill name to state, a hook parsed that skill's frontmatter, and tool calls were allowed or denied against `reads + writes` (with `forbids` always denying), logging each decision to an audit timeline. The enforcement, the MCP deny list, and the context-recipe layer all lived in the `pdctx` overlay and went with it.
