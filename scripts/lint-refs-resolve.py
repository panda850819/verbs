#!/usr/bin/env python3
"""lint-refs-resolve.py — every resolvable reference token in SKILL.md grounds.

Born from the flat -> skills/<bucket>/<skill> restructure: cross-skill refs
hid in `reads:`, `capability_required:`, body links, and `skills/{voice}`
templates, and a single grep pattern never caught them all. This checks the
property directly (does the path exist?) instead of pattern-matching the bug.

Usage: python3 scripts/lint-refs-resolve.py [repo-root]

Accepted non-repo tokens (skipped): output convention dirs skills create at
runtime (docs/sessions, docs/checkpoints, docs/retros, docs/plans, docs/briefs,
docs/handoffs — not tracked when empty), absolute-path substrings
(skills/pandastack/...), external URLs (skills/tree/main/...), and template
placeholders containing { or < (verified by shape, not existence).

Cross-pack token limits: pandastack:<name> resolves to this pack's skill dirs;
gbrain:<name> resolves against the checked-in snapshot scripts/gbrain-skills.list
(so CI, which has no gbrain checkout, still gates the class deterministically);
when the local pack IS present, every snapshot entry is also freshness-checked
against the real dirs so the snapshot cannot silently rot; and
slash commands are checked only when shaped as backticked `/lower-kebab` (or
`/pandastack:name`) so prose slashes, paths, and CLI flags do not false-positive.
Bare skill names in prose are outside this deterministic token shape.
"""
import os
import re
import sys
import glob

ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

skill_bucket = {}
for skill_dir in glob.glob("skills/*/*"):
    if os.path.isdir(skill_dir):
        n = os.path.basename(skill_dir)
        skill_bucket[n] = os.path.dirname(skill_dir)
TOKEN = re.compile(r"(?:skills|lib|docs|contexts)/[A-Za-z0-9_./{}<>-]+")
PACK_TOKEN = re.compile(r"\b(pandastack|gbrain):([a-z0-9][a-z0-9-]*)\b")
SLASH_COMMAND = re.compile(r"`(/(?:pandastack:)?[a-z0-9][a-z0-9-]*)`")


def accepted(t):
    return (
        t.startswith(("docs/sessions", "docs/checkpoints", "docs/retros", "docs/plans", "docs/briefs", "docs/handoffs"))
        or t.startswith("skills/pandastack/scripts")  # abs-path substring of ~/site/skills/pandastack/...
        or t.startswith("skills/tree/main")           # github URL substring
        or t == "skills/SKILL.md"                       # substring of writing-great-skills/SKILL.md
        or "{" in t or "<" in t                         # template placeholder
    )


broken = {}
notices = set()
allowlist_path = os.path.join(ROOT, "scripts", "lint-command-allowlist.txt")
command_allowlist = set()
if os.path.exists(allowlist_path):
    for line in open(allowlist_path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            command_allowlist.add(line)

gbrain_dir = os.environ.get("PANDASTACK_GBRAIN_SKILLS") or os.path.join(os.path.expanduser("~"), "site", "knowledge", "brain", "skills")
gbrain_present = os.path.isdir(gbrain_dir)
gbrain_list_path = os.path.join(ROOT, "scripts", "gbrain-skills.list")
gbrain_list = set()
if os.path.exists(gbrain_list_path):
    for line in open(gbrain_list_path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            gbrain_list.add(line)

for f in glob.glob("skills/**/SKILL.md", recursive=True):
    if "/.archive/" in f or "/_deprecated/" in f:
        continue
    text = open(f, encoding="utf-8").read()
    for m in set(TOKEN.findall(text)):
        tok = m.rstrip(".,):;`")
        if accepted(tok) or os.path.exists(tok):
            continue
        mm = re.match(r"skills/([A-Za-z0-9_-]+)(/.*)?$", tok)
        hint = "does not resolve"
        if mm and mm.group(1) in skill_bucket:
            n = mm.group(1)
            hint = f"flat ref — bucket it: skills/{skill_bucket[n]}/{n}"
        broken.setdefault(f, []).append((tok, hint))

    for pack, name in set(PACK_TOKEN.findall(text)):
        if pack == "pandastack":
            if name not in skill_bucket:
                broken.setdefault(f, []).append((f"pandastack:{name}", "no matching skills/*/<name>/ directory"))
        else:
            if name in gbrain_list:
                continue
            if gbrain_present and os.path.isdir(os.path.join(gbrain_dir, name)):
                broken.setdefault(f, []).append((f"gbrain:{name}", "in the local pack but missing from scripts/gbrain-skills.list — add it so CI gates the ref"))
            else:
                broken.setdefault(f, []).append((f"gbrain:{name}", "not in scripts/gbrain-skills.list (the CI-gated snapshot)"))

    for command in set(SLASH_COMMAND.findall(text)):
        name = command[1:]
        if name.startswith("pandastack:"):
            name = name.split(":", 1)[1]
        if name in skill_bucket or command in command_allowlist:
            continue
        broken.setdefault(f, []).append((command, "slash command does not match a pandastack skill or allowlist entry"))

if gbrain_present:
    for name in sorted(gbrain_list):
        if not os.path.isdir(os.path.join(gbrain_dir, name)):
            broken.setdefault("scripts/gbrain-skills.list", []).append((name, f"stale snapshot entry — no such dir in the local gbrain pack at {gbrain_dir}"))
elif gbrain_list:
    notices.add(f"NOTICE: gbrain pack absent at {gbrain_dir}; gbrain:* refs gated against scripts/gbrain-skills.list, freshness check skipped")

for notice in sorted(notices):
    print(notice)

if broken:
    print("FAIL: unresolved internal refs in SKILL.md files:")
    for f in sorted(broken):
        for tok, hint in sorted(set(broken[f])):
            print(f"  {f}: {tok}  [{hint}]")
    sys.exit(1)

print("OK: every internal path, pack, and slash-command ref in SKILL.md resolves.")
