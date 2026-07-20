#!/usr/bin/env python3
"""Offline contract tests for the fresh-run CLI seam."""

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "scripts" / "verbs"

FAKE_RUNTIME = r'''#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from pathlib import Path

if "--version" in sys.argv:
    name = Path(sys.argv[0]).name
    print(name + (" 2.1.206" if name == "claude" else " 0.144.1"))
    raise SystemExit(0)

base = Path(os.environ["HOME"])
control = json.loads((base / "control.json").read_text())
(base / "args.json").write_text(json.dumps(sys.argv[1:]))
(base / "prompt.txt").write_text(sys.stdin.read())
if "--settings" in sys.argv:
    settings_path = Path(sys.argv[sys.argv.index("--settings") + 1])
    (base / "settings.json").write_text(settings_path.read_text())
(base / "env.json").write_text(json.dumps({
    "AMBIENT_SECRET": os.environ.get("AMBIENT_SECRET"),
    "CLAUDECODE": os.environ.get("CLAUDECODE"),
    "CODEX_SESSION_ID": os.environ.get("CODEX_SESSION_ID"),
    "CODEX_THREAD_ID": os.environ.get("CODEX_THREAD_ID"),
    "CODEX_TURN_ID": os.environ.get("CODEX_TURN_ID"),
    "VERBS_FRESH_WORKER": os.environ.get("VERBS_FRESH_WORKER"),
    "VERBS_FRESH_RUN_ID": os.environ.get("VERBS_FRESH_RUN_ID"),
}))
if control.get("background_sentinel"):
    ready = control["background_sentinel"] + ".ready"
    subprocess.Popen(
        [sys.executable, "-c", "import pathlib,signal,time; "
         "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
         "pathlib.Path(%r).write_text('ready'); time.sleep(3); "
         "pathlib.Path(%r).write_text('escaped')" %
         (ready, control["background_sentinel"])],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    deadline = time.monotonic() + 1
    while not Path(ready).exists() and time.monotonic() < deadline:
        time.sleep(0.01)
if control.get("git_commit"):
    Path("worker-change.txt").write_text("worker-owned commit\n")
    subprocess.run(["git", "add", "worker-change.txt"], check=True)
    subprocess.run(
        ["git", "-c", "user.name=Fixture", "-c",
         "user.email=fixture@example.invalid", "commit", "-m", "worker commit"],
        check=True,
        stdout=subprocess.DEVNULL,
    )
if control.get("sleep"):
    time.sleep(float(control["sleep"]))
if control.get("stdout_bytes"):
    sys.stdout.write("x" * int(control["stdout_bytes"]))
    sys.stdout.flush()
if control.get("exit"):
    print(control.get("exit_text", "failed"), file=sys.stderr)
    raise SystemExit(int(control["exit"]))
result = control["result"]
if Path(sys.argv[0]).name == "codex":
    output = Path(sys.argv[sys.argv.index("-o") + 1])
    output.write_text(json.dumps(result))
else:
    print(json.dumps({"is_error": False, "structured_output": result}))
'''


class FreshRunTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.workspace = self.base / "workspace"
        self.workspace.mkdir()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        for name in ("claude", "codex"):
            path = self.bin / name
            path.write_text(FAKE_RUNTIME)
            path.chmod(0o755)
        self.artifact = self.workspace / "artifact.txt"
        self.artifact.write_text("verified artifact\n")
        self.request = {
            "goal": "Return the bounded result",
            "acceptance": ["status is success"],
            "working_directory": str(self.workspace),
            "completed_evidence": [],
        }
        self.result = {
            "status": "success",
            "summary": "bounded task completed",
            "evidence": ["fixture observed"],
            "artifacts": ["artifact.txt"],
            "next_action": "return to orchestrator",
            "errors": [],
        }

    def invoke(
        self, caller, worker, request=None, result=None, extra_env=None,
        fake_control=None, timeout=5, sandbox="read-only",
    ):
        request_path = self.base / "request.json"
        request_path.write_text(json.dumps(request or self.request))
        env = os.environ.copy()
        env.update({
            "PATH": str(self.bin) + os.pathsep + env.get("PATH", ""),
            "HOME": str(self.base),
        })
        control = {"result": result if result is not None else self.result}
        if fake_control:
            control.update(fake_control)
        (self.base / "control.json").write_text(json.dumps(control))
        if caller == "claude":
            env["CLAUDECODE"] = "caller-session"
        else:
            env["CODEX_SESSION_ID"] = "caller-session"
            env["CODEX_THREAD_ID"] = "caller-thread"
            env["CODEX_TURN_ID"] = "caller-turn"
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            [
                sys.executable,
                str(CLI),
                "fresh-run",
                "--agent",
                worker,
                "--model",
                "fixture-model",
                "--effort",
                "medium",
                "--sandbox",
                sandbox,
                "--request",
                str(request_path),
                "--timeout",
                str(timeout),
            ],
            cwd=str(self.workspace),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def test_four_caller_worker_routes_share_one_contract(self):
        for caller in ("claude", "codex"):
            for worker in ("claude", "codex"):
                with self.subTest(caller=caller, worker=worker):
                    completed = self.invoke(caller, worker)
                    self.assertEqual(completed.returncode, 0, completed.stderr)
                    result = json.loads(completed.stdout)
                    self.assertEqual(result["status"], "success")
                    self.assertEqual(set(result), {
                        "status", "summary", "evidence", "artifacts",
                        "next_action", "errors",
                    })
                    artifact = result["artifacts"][0]
                    self.assertEqual(artifact["path"], "artifact.txt")
                    self.assertEqual(
                        artifact["sha256"],
                        hashlib.sha256(self.artifact.read_bytes()).hexdigest(),
                    )
                    child_env = json.loads((self.base / "env.json").read_text())
                    self.assertEqual(child_env["VERBS_FRESH_WORKER"], "1")
                    self.assertTrue(child_env["VERBS_FRESH_RUN_ID"])
                    for key in (
                        "CLAUDECODE", "CODEX_SESSION_ID", "CODEX_THREAD_ID",
                        "CODEX_TURN_ID",
                    ):
                        self.assertIsNone(child_env[key])
                    arguments = json.loads((self.base / "args.json").read_text())
                    self.assertIn("fixture-model", arguments)
                    for forbidden in (
                        "--continue", "--resume", "--fork-session", "resume",
                    ):
                        self.assertNotIn(forbidden, arguments)
                    if worker == "claude":
                        schema = json.loads(
                            arguments[arguments.index("--json-schema") + 1]
                        )
                        self.assertNotIn("$schema", schema)
                        self.assertIn("--setting-sources", arguments)
                        self.assertEqual(
                            arguments[arguments.index("--setting-sources") + 1], ""
                        )
                        settings = json.loads(
                            (self.base / "settings.json").read_text()
                        )
                        self.assertTrue(settings["sandbox"]["enabled"])
                        self.assertTrue(settings["sandbox"]["failIfUnavailable"])
                        self.assertFalse(
                            settings["sandbox"]["allowUnsandboxedCommands"]
                        )
                        self.assertIn(
                            str((self.workspace / ".git").resolve()),
                            settings["sandbox"]["filesystem"]["denyWrite"],
                        )
                    else:
                        self.assertIn("--ignore-user-config", arguments)
                        self.assertIn("--ignore-rules", arguments)
                    self.assertIn(
                        "Do not invoke Verbs handover or fresh-run",
                        (self.base / "prompt.txt").read_text(),
                    )
                    self.assertIn(
                        "Do not start background or detached processes",
                        (self.base / "prompt.txt").read_text(),
                    )

    def test_request_allowlist_fails_closed(self):
        request = dict(self.request)
        request["transcript"] = "must not cross"
        completed = self.invoke("claude", "codex", request=request)
        self.assertEqual(completed.returncode, 1)
        result = json.loads(completed.stdout)
        self.assertEqual(result["status"], "failed")
        self.assertIn("unknown transcript", result["errors"][0])

    def test_artifact_traversal_and_symlink_fail_closed(self):
        traversal = dict(self.result)
        traversal["artifacts"] = ["../escape.txt"]
        completed = self.invoke("codex", "claude", result=traversal)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("not confined", json.loads(completed.stdout)["errors"][0])

        link = self.workspace / "link.txt"
        link.symlink_to(self.artifact)
        symlink_result = dict(self.result)
        symlink_result["artifacts"] = ["link.txt"]
        completed = self.invoke("codex", "codex", result=symlink_result)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("must not be a symlink", json.loads(completed.stdout)["errors"][0])

    def test_worker_cannot_recursively_dispatch(self):
        completed = self.invoke(
            "claude", "claude", extra_env={"VERBS_FRESH_WORKER": "1"}
        )
        self.assertEqual(completed.returncode, 1)
        self.assertIn("recursive fresh-run", json.loads(completed.stdout)["errors"][0])

    def test_timeout_terminates_the_worker(self):
        started = time.monotonic()
        completed = self.invoke(
            "codex", "codex", fake_control={"sleep": 5}, timeout=1
        )
        self.assertEqual(completed.returncode, 1)
        self.assertLess(time.monotonic() - started, 4)
        self.assertIn("timed out", json.loads(completed.stdout)["errors"][0])
        self.assertIn('"status": "failed"', completed.stderr)

    def test_runtime_stderr_is_not_copied_into_the_result(self):
        completed = self.invoke(
            "codex",
            "codex",
            fake_control={
                "exit": 7,
                "exit_text": "api_key=must-not-cross",
            },
        )
        self.assertEqual(completed.returncode, 1)
        self.assertNotIn("must-not-cross", completed.stdout)
        self.assertNotIn("must-not-cross", completed.stderr)
        self.assertEqual(
            json.loads(completed.stdout)["errors"], ["codex worker exited 7"]
        )

    def test_runtime_output_and_result_file_are_bounded(self):
        completed = self.invoke(
            "codex", "codex", fake_control={"stdout_bytes": 1024 * 1024 + 1}
        )
        self.assertEqual(completed.returncode, 1)
        self.assertIn("stdout exceeds 1 MiB", json.loads(completed.stdout)["errors"][0])

        oversized = dict(self.result)
        oversized["summary"] = "x" * (16 * 1024)
        completed = self.invoke("codex", "codex", result=oversized)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("Codex result exceeds 16 KiB", json.loads(completed.stdout)["errors"][0])

    def test_ambient_environment_is_not_inherited(self):
        completed = self.invoke(
            "codex", "codex", extra_env={"AMBIENT_SECRET": "must-not-cross"}
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        child_env = json.loads((self.base / "env.json").read_text())
        self.assertIsNone(child_env["AMBIENT_SECRET"])

    def test_non_string_status_fails_closed_without_traceback(self):
        result = dict(self.result)
        result["status"] = []
        completed = self.invoke("codex", "codex", result=result)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("invalid status", json.loads(completed.stdout)["errors"][0])
        self.assertNotIn("Traceback", completed.stderr)

    def test_duplicate_and_oversized_artifacts_fail_closed(self):
        duplicate = dict(self.result)
        duplicate["artifacts"] = ["artifact.txt", "./artifact.txt"]
        completed = self.invoke("codex", "codex", result=duplicate)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("duplicate paths", json.loads(completed.stdout)["errors"][0])

        large = self.workspace / "large.bin"
        with large.open("wb") as handle:
            handle.seek(16 * 1024 * 1024)
            handle.write(b"x")
        oversized = dict(self.result)
        oversized["artifacts"] = ["large.bin"]
        completed = self.invoke("codex", "codex", result=oversized)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("exceeds 16 MiB", json.loads(completed.stdout)["errors"][0])

    def test_shell_shaped_goal_is_data_not_a_command(self):
        sentinel = self.base / "injected"
        request = dict(self.request)
        request["goal"] = "Review $(touch {}) ; rm -rf ./x".format(sentinel)
        completed = self.invoke("claude", "codex", request=request)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertFalse(sentinel.exists())
        self.assertIn(request["goal"], (self.base / "prompt.txt").read_text())
        arguments = json.loads((self.base / "args.json").read_text())
        self.assertNotIn(request["goal"], arguments)

    def test_background_descendants_are_cancelled_after_parent_exits(self):
        sentinel = self.base / "descendant-survived"
        completed = self.invoke(
            "codex", "codex",
            fake_control={"background_sentinel": str(sentinel)},
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        time.sleep(1.2)
        self.assertFalse(sentinel.exists())

    def test_workspace_write_requires_clean_git_and_preserves_head(self):
        subprocess.run(["git", "init", "-q"], cwd=self.workspace, check=True)
        subprocess.run(["git", "add", "artifact.txt"], cwd=self.workspace, check=True)
        subprocess.run(
            ["git", "-c", "user.name=Fixture", "-c",
             "user.email=fixture@example.invalid", "commit", "-qm", "baseline"],
            cwd=self.workspace,
            check=True,
        )
        dirty = self.workspace / "dirty.txt"
        dirty.write_text("pre-existing\n")
        completed = self.invoke(
            "claude", "codex", sandbox="workspace-write"
        )
        self.assertEqual(completed.returncode, 1)
        self.assertIn("clean git baseline", json.loads(completed.stdout)["errors"][0])

        dirty.unlink()
        completed = self.invoke(
            "claude", "codex", sandbox="workspace-write",
            fake_control={"git_commit": True},
        )
        self.assertEqual(completed.returncode, 1)
        self.assertIn(
            "changed git HEAD", json.loads(completed.stdout)["errors"][0]
        )


if __name__ == "__main__":
    unittest.main()
