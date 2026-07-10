#!/usr/bin/env bash
# Offline structural and mutation checks for the tag-only release workflow.
set -euo pipefail
cd "$(dirname "$0")/.."

workflow=".github/workflows/release.yml"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/pandastack-release-workflow.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
validator="$tmp/validate.py"

cat >"$validator" <<'PY'
import re
import subprocess
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


def top_block(name):
    marker = name + ":"
    starts = [index for index, line in enumerate(lines) if line == marker]
    if len(starts) != 1:
        errors.append("expected exactly one top-level {} block".format(name))
        return []
    start = starts[0]
    end = len(lines)
    for index in range(start + 1, len(lines)):
        if lines[index] and not lines[index][0].isspace():
            end = index
            break
    return lines[start:end]


on_block = [line for line in top_block("on") if line]
check(
    on_block == ["on:", "  push:", "    tags:", '      - "v*"'],
    "trigger must be only tag pushes matching v*",
)

try:
    jobs_index = lines.index("jobs:")
except ValueError:
    jobs_index = len(lines)
    errors.append("missing top-level jobs block")

prefix = "\n".join(lines[:jobs_index])
check(not re.search(r"(?m)^permissions:", prefix), "permissions must be job-scoped")

job_starts = []
for index in range(jobs_index + 1, len(lines)):
    match = re.fullmatch(r"  ([a-z][a-z0-9_-]*):", lines[index])
    if match:
        job_starts.append((match.group(1), index))
    elif lines[index] and not lines[index][0].isspace():
        break

jobs = {}
for position, (name, start) in enumerate(job_starts):
    end = job_starts[position + 1][1] if position + 1 < len(job_starts) else len(lines)
    jobs[name] = "\n".join(lines[start:end])

check(set(jobs) == {"preflight", "publish"}, "jobs must be exactly preflight and publish")
preflight = jobs.get("preflight", "")
publish = jobs.get("publish", "")

checkout_sha = "34e114876b0b11c390a56381ad16ebd13914f8d5"
upload_sha = "ea165f8d65b6e75b540449e92b4886f43607fa02"
download_sha = "d3f86a106a0bac45b974a628896c90dbdf5c8093"

check(
    "    permissions:\n      contents: read\n    runs-on: macos-latest" in preflight,
    "preflight permissions must be exactly contents: read",
)
check("contents: write" not in preflight, "preflight must not have write permission")
check(
    re.findall(r"(?m)^\s+uses: (\S+)$", preflight)
    == ["actions/checkout@" + checkout_sha, "actions/upload-artifact@" + upload_sha],
    "preflight actions must use the exact pinned checkout and upload SHAs",
)
check(
    "        with:\n          fetch-depth: 0\n          persist-credentials: false" in preflight,
    "checkout must fetch full history without persisted credentials",
)
check(
    re.findall(r"(?m)^\s+run: (.+)$", preflight)
    == ['bash scripts/release-preflight.sh --tag "$GITHUB_REF_NAME"'],
    "preflight must run the locked --tag interface exactly once",
)
check(
    "          name: release-artifacts\n          if-no-files-found: error\n          path: |"
    in preflight,
    "upload must use the release-artifacts name and fail on missing files",
)

path_match = re.search(r"(?m)^          path: \|\n((?:^            .+(?:\n|$))+)", preflight)
upload_paths = []
if path_match:
    upload_paths = [line.strip() for line in path_match.group(1).splitlines()]
check(
    upload_paths
    == [
        "dist/release-title.txt",
        "dist/release-notes.md",
        "dist/pandastack-${{ github.ref_name }}.tar.gz",
        "dist/pandastack-${{ github.ref_name }}.tar.gz.sha256",
    ],
    "artifact upload must contain exactly the four dist outputs",
)

check("    needs: preflight" in publish, "publish must need preflight")
check(
    "    permissions:\n      contents: write\n    runs-on: macos-latest" in publish,
    "publish permissions must be exactly contents: write",
)
check("contents: read" not in publish, "publish permission must not be ambiguous")
check(
    re.findall(r"(?m)^\s+uses: (\S+)$", publish)
    == ["actions/download-artifact@" + download_sha],
    "publish must use only the exact pinned download SHA",
)
check(
    "          name: release-artifacts\n          path: dist" in publish,
    "publish must download release-artifacts into dist",
)
check(
    re.findall(r"(?m)^      - name: (.+)$", publish)
    == ["Download release artifacts", "Publish GitHub release"],
    "publish must contain only download and final publish steps",
)
check("actions/checkout@" not in publish, "publish must not check out repository code")
check("scripts/" not in publish, "publish must not execute repository scripts")
check(publish.count("        run: |") == 1, "publish must have one run block")
check(text.count("GH_TOKEN:") == 1, "GH_TOKEN must appear exactly once")
check("GH_TOKEN:" not in preflight, "GH_TOKEN must not reach preflight")

final_marker = "      - name: Publish GitHub release"
final_step = publish[publish.find(final_marker):] if final_marker in publish else ""
check("          GH_TOKEN: ${{ github.token }}" in final_step, "final step must receive GH_TOKEN")
check(
    "          GH_REPO: ${{ github.repository }}" in final_step,
    "final step must set repository context without a checkout",
)

run_marker = "        run: |\n"
script = final_step.split(run_marker, 1)[1] if run_marker in final_step else ""
script = "\n".join(
    line[10:] if line.startswith("          ") else line
    for line in script.splitlines()
)
syntax = subprocess.run(
    ["bash", "-n"],
    input=script,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    check=False,
)
check(syntax.returncode == 0, "final publish script must parse as Bash")
check(
    re.search(r"(?m)^\s*(?:bash|sh|python3?|ruby|node|source|\.)\s", script) is None,
    "publish must not execute downloaded or repository code",
)

check(
    'gh release view "$GITHUB_REF_NAME"' in script
    and "--json isDraft" in script
    and "--jq '.isDraft'" in script,
    "rerun cleanup must inspect isDraft",
)
cleanup = '''case "$existing_draft" in
  "")
    ;;
  true)
    gh release delete "$GITHUB_REF_NAME" --yes
    ;;
  *)
    echo "ERROR: release $GITHUB_REF_NAME already exists and is not a draft" >&2
    exit 1
    ;;
esac'''
check(cleanup in script, "cleanup must delete only a draft and reject published releases")
check(script.count('gh release delete "$GITHUB_REF_NAME" --yes') == 1, "draft cleanup must be singular")

create = 'gh release create "$GITHUB_REF_NAME" --verify-tag --draft'
edit = 'gh release edit "$GITHUB_REF_NAME" --draft=false'
check(create in script, "release creation must verify the existing tag and stay draft")
check('--title "$(cat dist/release-title.txt)"' in script, "title must come from the exact title file")
check("--notes-file dist/release-notes.md" in script, "notes must come from the exact notes file")
check(
    '"dist/pandastack-$GITHUB_REF_NAME.tar.gz"' in script,
    "archive must be uploaded",
)
check(
    '"dist/pandastack-$GITHUB_REF_NAME.tar.gz.sha256"' in script,
    "archive checksum must be uploaded",
)
check(edit in script, "draft must be published only after asset upload")

view_at = script.find('gh release view "$GITHUB_REF_NAME"')
delete_at = script.find('gh release delete "$GITHUB_REF_NAME" --yes')
create_at = script.find(create)
checksum_at = script.find('"dist/pandastack-$GITHUB_REF_NAME.tar.gz.sha256"')
edit_at = script.find(edit)
check(
    -1 not in (view_at, delete_at, create_at, checksum_at, edit_at)
    and view_at < delete_at < create_at < checksum_at < edit_at,
    "release order must be inspect, draft cleanup, draft create/assets, publish",
)

check("--generate-notes" not in text, "generated notes are forbidden")
check("gh release upload" not in text, "assets must upload during draft creation")
check(
    re.search(r"(?m)^\s*git\s+(?:tag|push)\b", text) is None,
    "workflow must never create or push tags",
)

if errors:
    for error in errors:
        print("FAIL: {}".format(error), file=sys.stderr)
    sys.exit(1)

print("OK: release workflow is tag-only, least-privilege, pinned, and draft-first")
PY

python3 "$validator" "$workflow"

python3 - "$workflow" "$tmp/write-permission.yml" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
needle = "      contents: read"
if source.count(needle) != 1:
    raise SystemExit("fixture requires exactly one read permission")
Path(sys.argv[2]).write_text(source.replace(needle, "      contents: write", 1), encoding="utf-8")
PY
if python3 "$validator" "$tmp/write-permission.yml" >/dev/null 2>&1; then
  echo "FAIL: write-enabled preflight mutation unexpectedly passed" >&2
  exit 1
fi

python3 - "$workflow" "$tmp/non-draft.yml" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
needle = '--verify-tag --draft'
if source.count(needle) != 1:
    raise SystemExit("fixture requires exactly one draft create command")
Path(sys.argv[2]).write_text(source.replace(needle, "--verify-tag", 1), encoding="utf-8")
PY
if python3 "$validator" "$tmp/non-draft.yml" >/dev/null 2>&1; then
  echo "FAIL: non-draft release mutation unexpectedly passed" >&2
  exit 1
fi

echo "OK: seeded permission and draft mutations failed as expected."
