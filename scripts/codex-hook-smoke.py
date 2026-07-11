#!/usr/bin/env python3
"""Prove Codex discovers Verbs hooks and triggers installed SessionStart.

The caller provides a disposable host profile and its installer-returned plugin
path. This script talks to the installed Codex app-server over stdio, asks the
host for its exact hook inventory, then triggers SessionStart from a real Codex
turn. The installed hook contract suite separately executes all three commands.
This script never edits the source checkout.
"""

import argparse
import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import threading
import time


TIMEOUT_SECONDS = 30
EXPECTED_EVENTS = {
    ("preToolUse", "Bash"),
    ("sessionStart", "startup|clear|compact"),
    ("stop", None),
}


def fail(message):
    raise RuntimeError(message)


class AppServer:
    def __init__(self, profile):
        env = os.environ.copy()
        env["HOME"] = str(profile)
        env["CODEX_HOME"] = str(profile / ".codex")
        self.process = subprocess.Popen(
            [
                "codex", "app-server", "--stdio",
                "--disable", "remote_plugin",
                "--disable", "plugin_sharing",
            ],
            cwd=str(profile),
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        self.request_id = 0
        self.pending = []
        self.messages = queue.Queue()
        self.reader = threading.Thread(target=self._read_stdout, daemon=True)
        self.reader.start()

    def _read_stdout(self):
        try:
            for line in self.process.stdout:
                self.messages.put(json.loads(line))
        except Exception as exc:
            self.messages.put(exc)
        finally:
            self.messages.put(None)

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=5)
        self.reader.join(timeout=5)

    def send(self, message):
        self.process.stdin.write(json.dumps(message) + "\n")
        self.process.stdin.flush()

    def read(self, deadline):
        if self.pending:
            return self.pending.pop(0)
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            fail("timed out waiting for Codex app-server")
        try:
            message = self.messages.get(timeout=remaining)
        except queue.Empty:
            fail("timed out waiting for Codex app-server")
        if message is None:
            fail("Codex app-server closed stdout")
        if isinstance(message, Exception):
            fail("invalid Codex app-server output: {}".format(message))
        return message

    def request(self, method, params):
        self.request_id += 1
        request_id = self.request_id
        self.send({
            "jsonrpc": "2.0",
            "id": request_id,
            "method": method,
            "params": params,
        })
        deadline = time.monotonic() + TIMEOUT_SECONDS
        deferred = []
        while True:
            message = self.read(deadline)
            if message.get("id") == request_id:
                self.pending.extend(deferred)
                if "error" in message:
                    fail("{} failed: {}".format(method, message["error"]))
                return message.get("result", {})
            deferred.append(message)

    def notify(self, method):
        self.send({"jsonrpc": "2.0", "method": method})

def completed_hook(message, event_name, installed_manifest):
    if message.get("method") != "hook/completed":
        return None
    run = message.get("params", {}).get("run", {})
    if run.get("eventName") != event_name:
        return None
    if run.get("source") != "plugin":
        fail("{} hook did not come from a plugin".format(event_name))
    if Path(run.get("sourcePath", "")).resolve() != installed_manifest:
        fail("{} hook came from the wrong manifest".format(event_name))
    return run


def hook_inventory(server, profile):
    response = server.request("hooks/list", {"cwds": [str(profile)]})
    rows = response.get("data", [])
    if len(rows) != 1 or rows[0].get("warnings") or rows[0].get("errors"):
        fail("Codex hook inventory returned warnings, errors, or the wrong cwd count")
    return rows[0].get("hooks", [])


def assert_inventory(server, profile, installed_root):
    hooks = [
        hook for hook in hook_inventory(server, profile)
        if hook.get("pluginId") == "verbs@verbs"
    ]
    actual = {(hook.get("eventName"), hook.get("matcher")) for hook in hooks}
    if actual != EXPECTED_EVENTS or len(hooks) != 3:
        fail("Codex did not discover exactly the three Verbs hooks")

    manifest = (installed_root / "hooks" / "hooks.json").resolve()
    for hook in hooks:
        if not hook.get("enabled") or hook.get("source") != "plugin":
            fail("Codex discovered a disabled or non-plugin Verbs hook")
        if Path(hook.get("sourcePath", "")).resolve() != manifest:
            fail("Codex hook inventory escaped the installed plugin")
        if str(installed_root) not in (hook.get("command") or ""):
            fail("Codex hook command does not target the installed plugin")
    return manifest


def assert_no_inventory(server, profile):
    hooks = [
        hook for hook in hook_inventory(server, profile)
        if hook.get("pluginId") == "verbs@verbs"
    ]
    if hooks:
        fail("Codex rollback left Verbs hooks registered")


def start_thread(server, profile):
    response = server.request("thread/start", {
        "cwd": str(profile),
        "ephemeral": True,
        "sessionStartSource": "startup",
        "approvalPolicy": "never",
        "sandbox": "read-only",
        "config": {"bypass_hook_trust": True},
    })
    return response["thread"]["id"]


def start_turn(server, thread_id, prompt):
    response = server.request("turn/start", {
        "threadId": thread_id,
        "input": [{"type": "text", "text": prompt, "text_elements": []}],
    })
    return response["turn"]["id"]


def wait_for_session_start(server, thread_id, turn_id, installed_manifest):
    deadline = time.monotonic() + TIMEOUT_SECONDS
    while True:
        message = server.read(deadline)
        run = completed_hook(message, "sessionStart", installed_manifest)
        if run is None:
            continue
        params = message.get("params", {})
        if params.get("threadId") != thread_id or params.get("turnId") != turn_id:
            continue
        return run


def assert_host_behavior(server, profile, installed_manifest):
    if (profile / ".git").exists():
        fail("disposable hook profile must not be a Git checkout")
    thread_id = start_thread(server, profile)
    print("INFO [codex hooks]: trigger installed SessionStart", flush=True)
    turn_id = start_turn(
        server,
        thread_id,
        "Return exactly HOOK_TEST_DONE.",
    )
    session = wait_for_session_start(
        server, thread_id, turn_id, installed_manifest)
    if session.get("status") != "completed" or not any(
            entry.get("kind") == "context" and "# Dispatch" in entry.get("text", "")
            for entry in session.get("entries", [])):
        fail("Codex SessionStart did not inject Dispatch context")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expect-none", action="store_true")
    parser.add_argument("profile", type=Path)
    parser.add_argument("installed_root", type=Path, nargs="?")
    args = parser.parse_args()
    profile = args.profile.resolve()
    installed_root = args.installed_root.resolve() if args.installed_root else None
    if not args.expect_none:
        if installed_root is None:
            fail("installed_root is required unless --expect-none is used")
        expected_plugins = (profile / ".codex" / "plugins").resolve()
        try:
            installed_root.relative_to(expected_plugins)
        except ValueError:
            fail("installed plugin is outside the disposable Codex profile")

    server = AppServer(profile)
    try:
        server.request("initialize", {
            "clientInfo": {"name": "verbs-hook-smoke", "title": None, "version": "0.6.0"},
            "capabilities": None,
        })
        server.notify("initialized")
        if args.expect_none:
            assert_no_inventory(server, profile)
        else:
            print("INFO [codex hooks]: inspect installed hook inventory", flush=True)
            installed_manifest = assert_inventory(server, profile, installed_root)
            assert_host_behavior(server, profile, installed_manifest)
    finally:
        server.close()
    if args.expect_none:
        print("PASS [codex]: rollback left no Verbs hooks registered")
    else:
        print("PASS [codex]: host discovered three hooks and triggered installed SessionStart")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("ERROR: {}".format(exc), file=sys.stderr)
        raise SystemExit(1)
