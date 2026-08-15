#!/usr/bin/env python3
"""Integration contract for scripts/verbs setup."""
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "scripts/verbs"


def run(repo, *args, env=None):
    return subprocess.run(
        [str(CLI), "setup", *args, "--repo", str(repo)],
        text=True, capture_output=True, env=env,
    )


def contract(tracker="github"):
    return f"""## verbs
work-source: github-issues
ticket-policy: required
goal-source: ticket
acceptance-source: ticket
unclear-intent: automatic-grilling-session
gbrain: enabled
test: bash tests/run-all.sh
delivery: pull-request
tracker: {tracker}
"""


def fixture(agent_text="# Agent\n", remote="git@github.com:Acme/Widget.git"):
    root = Path(tempfile.mkdtemp())
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    if remote:
        subprocess.run(["git", "-C", str(root), "remote", "add", "origin", remote], check=True)
    (root / "AGENTS.md").write_text(agent_text)
    return root


# Questionnaire exposes every project-level decision and automatic intake rule.
repo = fixture()
questions = run(repo, "--questionnaire")
assert questions.returncode == 0
for fragment in (
    "Work source:", "Ticket policy:", "Goal source:", "Acceptance source:",
    "Verification command(s):", "Delivery:", "GBrain:",
    "Automatically enter a Grilling Session",
):
    assert fragment in questions.stdout, fragment

# Missing tracker: preview is exact and read-only; apply is approval-gated.
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
incomplete = run(repo, "--check")
assert incomplete.returncode == 1 and "Project Contract is missing" in incomplete.stdout

# A complete contract validates and is idempotent.
repo = fixture(contract())
assert run(repo, "--check").returncode == 0
noop = run(repo, "--apply", "--approve")
assert noop.returncode == 0 and "NO-OP" in noop.stdout

# SSH aliases resolve through SSH config and unknown aliases fail closed.
repo = fixture(contract(), "git@github-personal:Acme/Widget.git")
home = Path(tempfile.mkdtemp())
ssh_dir = home / ".ssh"
ssh_dir.mkdir()
(ssh_dir / "config").write_text("Host github-personal\n  HostName github.com\n  User git\n")
env = os.environ.copy()
env["HOME"] = str(home)
alias_check = run(repo, "--check", env=env)
assert alias_check.returncode == 0, alias_check.stderr
assert "acme/widget" in alias_check.stdout

repo = fixture(contract(), "git@not-github:Acme/Widget.git")
assert "expected one GitHub repository identity" in run(repo, "--check").stderr
repo = fixture(contract(), "https://notgithub.com/Acme/Widget.git")
assert "expected one GitHub repository identity" in run(repo, "--check").stderr

# AGENTS.md symlinked to a host compatibility file is still one canonical path.
repo = fixture(contract())
(repo / "CLAUDE.md").write_text((repo / "AGENTS.md").read_text())
(repo / "AGENTS.md").unlink()
(repo / "AGENTS.md").symlink_to("CLAUDE.md")
linked_check = run(repo, "--check")
assert linked_check.returncode == 0, linked_check.stderr
assert "AGENTS.md" in linked_check.stdout

# CLAUDE.md alone is no longer accepted as project policy.
repo = fixture()
(repo / "AGENTS.md").unlink()
(repo / "CLAUDE.md").write_text(contract())
assert "no AGENTS.md exists" in run(repo, "--check").stderr

# Conflicting tracker and remote ambiguity fail closed.
repo = fixture(contract("linear"))
assert "existing tracker" in run(repo, "--check").stderr
repo = fixture()
subprocess.run(["git", "-C", str(repo), "remote", "add", "upstream", "https://github.com/Other/Repo.git"], check=True)
assert "expected one GitHub repository identity" in run(repo, "--check").stderr

assert not (ROOT / ".verbs.toml").exists()
print("setup verbs contract: ok")
