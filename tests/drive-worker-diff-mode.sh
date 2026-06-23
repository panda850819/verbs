#!/usr/bin/env bash
# tests/drive-worker-diff-mode.sh — agent-worker captures the working-tree exec bit into
# the diff (PRO-71). An executable untracked file -> `new file mode 100755`, a plain file
# -> 100644, and the captured patch applies to a fresh checkout yielding an EXECUTABLE
# tool. Without this every tool an autonomous build creates lands non-executable on
# psdrive/integration, so the merged artifact is broken even when the build was correct.
set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AW="$repo_root/scripts/agent-worker"
fail=0
pass(){ echo "PASS: $1"; }
fl(){ echo "FAIL: $1"; fail=1; }

wt="$(mktemp -d)"
git -C "$wt" init -q; git -C "$wt" config user.email t@t.t; git -C "$wt" config user.name t
echo base > "$wt/base.txt"; git -C "$wt" add -A; git -C "$wt" commit -qm base
printf '#!/usr/bin/env bash\necho hi\n' > "$wt/bin-tool"; chmod +x "$wt/bin-tool"
printf 'plain\n' > "$wt/plain.txt"
job="$(mktemp -d)"; mkdir -p "$job/output"

python3 - "$AW" "$job" "$wt" <<'PY'
import importlib.util, importlib.machinery, sys
# agent-worker has no .py extension -> spec_from_file_location can't infer a loader.
loader = importlib.machinery.SourceFileLoader("agent_worker", sys.argv[1])
spec = importlib.util.spec_from_loader("agent_worker", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
m.write_diff_patch(sys.argv[2], sys.argv[3], include_untracked=True)
PY

patch="$job/output/diff.patch"
[ -f "$patch" ] || fl "no diff.patch produced"
grep -A1 "b/bin-tool" "$patch" | grep -q "new file mode 100755" \
  && pass "executable untracked file -> 100755" || fl "exec bit not preserved: $(grep -A1 'b/bin-tool' "$patch" | tr '\n' ' ')"
grep -A1 "b/plain.txt" "$patch" | grep -q "new file mode 100644" \
  && pass "plain untracked file -> 100644" || fl "plain file mode wrong: $(grep -A1 'b/plain.txt' "$patch" | tr '\n' ' ')"

# end-to-end: the captured patch applies to a fresh checkout and yields an EXECUTABLE tool
fresh="$(mktemp -d)"
git -C "$fresh" init -q; git -C "$fresh" config user.email t@t.t; git -C "$fresh" config user.name t
echo base > "$fresh/base.txt"; git -C "$fresh" add -A; git -C "$fresh" commit -qm base
( cd "$fresh" && git apply "$patch" ) && [ -x "$fresh/bin-tool" ] \
  && pass "applied patch yields executable bin-tool" || fl "applied tool not executable"

[ "$fail" -eq 0 ] && echo "OK: drive-worker-diff-mode all green" || echo "FAILURES present"
exit "$fail"
