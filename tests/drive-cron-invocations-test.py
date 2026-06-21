#!/usr/bin/env python3
"""Offline tests for drive-cron.py autonomy config -> invocation mapping.

No driver is spawned and no scheduler state is touched; only the pure config /
argv logic (load_autonomy_config + build_invocations) is exercised.

Run: python3 tests/drive-cron-invocations-test.py
"""
import importlib.util
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
DC_PATH = os.path.join(HERE, "..", "scripts", "drive-cron.py")
spec = importlib.util.spec_from_file_location("drive_cron", DC_PATH)
dc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dc)

passed = failed = 0


def check(desc, got, want):
    global passed, failed
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"FAIL  {desc}\n  got:  {got}\n  want: {want}")


# --- build_invocations: the empty/no-autonomy path must equal today's behavior ---
GLOBAL_1 = [(None, ["--execute", "--max", "1"])]
check("empty cfg -> global read-only", dc.build_invocations({}, "1"), GLOBAL_1)
check("None cfg -> global read-only", dc.build_invocations(None, "1"), GLOBAL_1)
check("build_auto False -> global read-only",
      dc.build_invocations({"pandastack": {"build_auto": False}}, "1"), GLOBAL_1)
check("malformed opts ignored -> global",
      dc.build_invocations({"p": "nope"}, "1"), GLOBAL_1)
check("max passed through to global",
      dc.build_invocations({}, "3"), [(None, ["--execute", "--max", "3"])])

# --- per-project autonomy ---
check("build_auto only",
      dc.build_invocations({"pandastack": {"build_auto": True}}, "1"),
      [("pandastack", ["--execute", "--build-auto", "--only", "pandastack", "--max", "1"])])
check("build_auto + merge_auto",
      dc.build_invocations({"pandastack": {"build_auto": True, "merge_auto": True}}, "1"),
      [("pandastack", ["--execute", "--build-auto", "--only", "pandastack",
                       "--merge-auto", "--max", "1"])])
check("merge_auto without build_auto -> build, NO merge",
      dc.build_invocations({"p": {"merge_auto": True}}, "1"),
      [("p", ["--execute", "--build-auto", "--only", "p", "--max", "1"])])
check("max passed through to autonomy run",
      dc.build_invocations({"pandastack": {"build_auto": True}}, "5"),
      [("pandastack", ["--execute", "--build-auto", "--only", "pandastack", "--max", "5"])])

# two build_auto projects (order-independent)
got = dc.build_invocations({"a": {"build_auto": True},
                            "b": {"build_auto": True, "merge_auto": True}}, "1")
check("two build_auto projects",
      {(lbl, tuple(args)) for lbl, args in got},
      {("a", ("--execute", "--build-auto", "--only", "a", "--max", "1")),
       ("b", ("--execute", "--build-auto", "--only", "b", "--merge-auto", "--max", "1"))})

# --- load_autonomy_config: every failure mode degrades to {} without raising ---
check("missing file -> {}", dc.load_autonomy_config("/nonexistent/path/xyz.json"), {})

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    f.write("{ not valid json ")
    bad = f.name
check("malformed JSON -> {}", dc.load_autonomy_config(bad), {})
os.unlink(bad)

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump({"pandastack": {"build_auto": True}}, f)
    good = f.name
check("valid config -> dict", dc.load_autonomy_config(good),
      {"pandastack": {"build_auto": True}})
os.unlink(good)

with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump([1, 2, 3], f)
    arr = f.name
check("non-dict top-level -> {}", dc.load_autonomy_config(arr), {})
os.unlink(arr)

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
