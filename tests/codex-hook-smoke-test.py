#!/usr/bin/env python3
"""Offline behavior checks for Codex live hook inventory trust."""

import importlib.util
import tempfile
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
SCRIPT = REPO / "scripts" / "codex-hook-smoke.py"
SPEC = importlib.util.spec_from_file_location("codex_hook_smoke", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FakeServer:
    def __init__(self, hooks, warnings=None, errors=None):
        self.hooks = hooks
        self.warnings = warnings or []
        self.errors = errors or []

    def request(self, method, params):
        assert method == "hooks/list"
        assert len(params["cwds"]) == 1
        return {
            "data": [{
                "warnings": self.warnings,
                "errors": self.errors,
                "hooks": self.hooks,
            }],
        }


def hook_rows(root, trust_status):
    manifest = (root / "hooks" / "hooks.json").resolve()
    return [
        {
            "pluginId": "verbs@verbs",
            "eventName": event,
            "matcher": matcher,
            "enabled": True,
            "source": "plugin",
            "sourcePath": str(manifest),
            "command": f"{root}/hooks/test-command",
            "trustStatus": trust_status,
        }
        for event, matcher in sorted(
            MODULE.EXPECTED_EVENTS,
            key=lambda item: (item[0], item[1] or ""),
        )
    ]


def main():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory) / ".codex" / "plugins" / "cache" / "verbs"
        (root / "hooks").mkdir(parents=True)
        (root / "hooks" / "hooks.json").write_text("{}\n", encoding="utf-8")
        manifest = (root / "hooks" / "hooks.json").resolve()

        trusted = FakeServer(hook_rows(root, "trusted"))
        MODULE.assert_inventory(trusted, Path(directory), root, require_trusted=True)

        warned = FakeServer(
            hook_rows(root, "trusted"),
            warnings=["warning from an unrelated plugin"],
        )
        MODULE.assert_inventory(warned, Path(directory), root, require_trusted=True)

        errored = FakeServer(
            hook_rows(root, "trusted"),
            errors=["invalid hook manifest"],
        )
        try:
            MODULE.assert_inventory(
                errored, Path(directory), root, require_trusted=True)
        except RuntimeError as exc:
            assert "returned errors or the wrong cwd count" in str(exc)
        else:
            raise AssertionError("inventory errors were accepted")

        untrusted = FakeServer(hook_rows(root, "untrusted"))
        MODULE.assert_inventory(untrusted, Path(directory), root, require_trusted=False)
        try:
            MODULE.assert_inventory(
                untrusted, Path(directory), root, require_trusted=True)
        except RuntimeError as exc:
            assert "untrusted Verbs hook" in str(exc)
        else:
            raise AssertionError("require_trusted accepted an untrusted hook")

        user_completion = {
            "method": "hook/completed",
            "params": {"run": {
                "eventName": "sessionStart",
                "source": "user",
                "sourcePath": str(Path(directory) / "hooks.json"),
            }},
        }
        assert MODULE.completed_hook(
            user_completion, "sessionStart", manifest) is None

        other_plugin_completion = {
            "method": "hook/completed",
            "params": {"run": {
                "eventName": "sessionStart",
                "source": "plugin",
                "sourcePath": str(Path(directory) / "other" / "hooks.json"),
            }},
        }
        assert MODULE.completed_hook(
            other_plugin_completion, "sessionStart", manifest) is None

        target_completion = {
            "method": "hook/completed",
            "params": {"run": {
                "eventName": "sessionStart",
                "source": "plugin",
                "sourcePath": str(manifest),
            }},
        }
        assert MODULE.completed_hook(
            target_completion, "sessionStart", manifest) == (
                target_completion["params"]["run"])

        spoofed_completion = {
            "method": "hook/completed",
            "params": {"run": {
                "eventName": "sessionStart",
                "source": "user",
                "sourcePath": str(manifest),
            }},
        }
        try:
            MODULE.completed_hook(
                spoofed_completion, "sessionStart", manifest)
        except RuntimeError as exc:
            assert "did not come from a plugin" in str(exc)
        else:
            raise AssertionError("target manifest accepted a non-plugin source")

    print("OK: Codex hook smoke isolates and validates the Verbs plugin")


if __name__ == "__main__":
    main()
