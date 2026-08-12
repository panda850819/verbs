#!/usr/bin/env python3
"""Integration and prose contracts for scripts/verbs setup."""

import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts/verbs"
SKILL = (ROOT / "skills/engineering/setup-verbs/SKILL.md").read_text()


def run(repo, *args):
    return subprocess.run(
        [str(CLI), "setup", *args, "--repo", str(repo)],
        text=True, capture_output=True,
    )


def fixture(agent_text="# Agent\n", remote="git@github.com:Acme/Widget.git"):
    root = Path(tempfile.mkdtemp())
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    if remote:
        subprocess.run(["git", "-C", str(root), "remote", "add", "origin", remote], check=True)
    (root / "AGENTS.md").write_text(agent_text)
    return root


# Missing config: check fails, preview is exact and read-only, apply is gated.
repo = fixture("# Agent\n\nKeep me.\n")
check = run(repo, "--check")
assert check.returncode == 1 and "NOT CONFIGURED" in check.stdout
preview = run(repo, "--preview")
assert preview.returncode == 0 and "+## verbs" in preview.stdout
assert "tracker: github" not in (repo / "AGENTS.md").read_text()
blocked = run(repo, "--apply")
assert blocked.returncode == 2 and "requires --approve" in blocked.stderr
applied = run(repo, "--apply", "--approve")
assert applied.returncode == 0 and "APPLIED" in applied.stdout
text = (repo / "AGENTS.md").read_text()
assert text.count("## verbs") == 1 and text.count("tracker: github") == 1
assert "Keep me." in text

# Idempotence: no diff and no approval required.
assert run(repo, "--check").returncode == 0
noop = run(repo, "--apply", "--approve")
assert noop.returncode == 0 and "NO-OP" in noop.stdout

# Existing block preserves keys and inserts one tracker.
repo = fixture("# Agent\n\n## verbs\ntest: bash tests/run-all.sh\n\n## Notes\nkeep\n")
assert run(repo, "--apply", "--approve").returncode == 0
text = (repo / "AGENTS.md").read_text()
assert "test: bash tests/run-all.sh\ntracker: github\n\n## Notes" in text

# Conflicting tracker, document ambiguity, and remote ambiguity fail closed.
repo = fixture("## verbs\ntracker: linear\n")
assert "existing tracker" in run(repo, "--check").stderr
repo = fixture()
(repo / "CLAUDE.md").write_text("# Claude\n")
assert "both exist without" in run(repo, "--check").stderr
repo = fixture()
subprocess.run(["git", "-C", str(repo), "remote", "add", "upstream", "https://github.com/Other/Repo.git"], check=True)
assert "expected one GitHub repository identity" in run(repo, "--check").stderr

for fragment in (
    "deterministic setup contract belongs to `scripts/verbs setup`",
    "ask the human to choose `AGENTS.md` or\n   `CLAUDE.md`",
    "`scripts/verbs setup --preview`",
    "`scripts/verbs setup --apply --approve`",
    "Never edit the document independently of the\n   CLI preview",
    "`.verbs.toml`",
):
    assert fragment in SKILL, fragment

assert not (ROOT / ".verbs.toml").exists()
print("setup-verbs contract: ok")
