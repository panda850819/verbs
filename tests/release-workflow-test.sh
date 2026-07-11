#!/usr/bin/env bash
# Offline structural and mutation checks for tag-triggered release and recovery.
set -euo pipefail
cd "$(dirname "$0")/.."

workflow=".github/workflows/release.yml"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/verbs-release-workflow.XXXXXX")"
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
    on_block
    == [
        "on:",
        "  push:",
        "    tags:",
        '      - "v*"',
        "  workflow_dispatch:",
        "    inputs:",
        "      release_tag:",
        "        description: Existing annotated release tag",
        "        required: true",
        "        type: string",
    ],
    "trigger must support v* pushes plus one required recovery tag input",
)
env_block = [line for line in top_block("env") if line]
check(
    env_block == ["env:", "  RELEASE_TAG: ${{ inputs.release_tag || github.ref_name }}"],
    "one RELEASE_TAG must resolve push and manual-dispatch events",
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
    "        with:\n          fetch-depth: 0\n          persist-credentials: false\n"
    "          ref: ${{ env.RELEASE_TAG }}" in preflight,
    "checkout must fetch the resolved tag with full history and no persisted credentials",
)
check(
    re.findall(r"(?m)^\s+run: (.+)$", preflight)
    == [
        'git fetch --force --no-tags origin "refs/tags/$RELEASE_TAG:refs/tags/$RELEASE_TAG"',
        'bash scripts/release-preflight.sh --tag "$RELEASE_TAG"',
    ],
    "preflight must restore the annotated tag object before the locked --tag interface",
)
restore_at = preflight.find("Restore annotated tag object")
preflight_at = preflight.find('bash scripts/release-preflight.sh --tag "$RELEASE_TAG"')
check(
    -1 not in (restore_at, preflight_at) and restore_at < preflight_at,
    "annotated tag restoration must happen before release preflight",
)
check(
    "          name: release-metadata\n          if-no-files-found: error\n          path: |"
    in preflight,
    "upload must use the release-metadata name and fail on missing files",
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
    ],
    "metadata upload must contain exactly title and notes",
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
    "          name: release-metadata\n          path: dist" in publish,
    "publish must download release-metadata into dist",
)
check(
    re.findall(r"(?m)^      - name: (.+)$", publish)
    == ["Download release metadata", "Publish GitHub release"],
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
check(".tar.gz" not in text and ".sha256" not in text,
      "public release workflow must not carry custom archives or checksums")

check(
    'gh release view "$RELEASE_TAG"' in script
    and "--json isDraft" in script
    and "--jq '.isDraft'" in script,
    "rerun cleanup must inspect isDraft",
)
cleanup = '''case "$existing_draft" in
  "")
    ;;
  true)
    gh release delete "$RELEASE_TAG" --yes
    ;;
  *)
    echo "ERROR: release $RELEASE_TAG already exists and is not a draft" >&2
    exit 1
    ;;
esac'''
check(cleanup in script, "cleanup must delete only a draft and reject published releases")
check(script.count('gh release delete "$RELEASE_TAG" --yes') == 1, "draft cleanup must be singular")

release_flags = 'release_flags=(--verify-tag --draft)'
prerelease_case = '''case "$RELEASE_TAG" in
  *-*)
    release_flags+=(--prerelease --latest=false)
    ;;
esac'''
create = 'gh release create "$RELEASE_TAG" "${release_flags[@]}"'
edit = 'gh release edit "$RELEASE_TAG" --draft=false'
check(release_flags in script, "release creation must verify the existing tag and stay draft")
check(prerelease_case in script, "prerelease tags must set prerelease and latest=false together")
check(script.count("--prerelease") == 1, "prerelease flag policy must be singular")
check(script.count("--latest=false") == 1, "latest=false flag policy must be singular")
check(create in script, "release creation must use only the policy-derived flags")
check('--title "$(cat dist/release-title.txt)"' in script, "title must come from the exact title file")
check("--notes-file dist/release-notes.md" in script, "notes must come from the exact notes file")
check(edit in script, "draft must be published only after metadata-derived creation")

view_at = script.find('gh release view "$RELEASE_TAG"')
delete_at = script.find('gh release delete "$RELEASE_TAG" --yes')
create_at = script.find(create)
edit_at = script.find(edit)
check(
    -1 not in (view_at, delete_at, create_at, edit_at)
    and view_at < delete_at < create_at < edit_at,
    "release order must be inspect, draft cleanup, draft create, publish",
)

check("--generate-notes" not in text, "generated notes are forbidden")
check("gh release upload" not in text, "workflow must not upload custom release assets")
check(
    re.search(r"(?m)^\s*git\s+(?:tag|push)\b", text) is None,
    "workflow must never create or push tags",
)

if errors:
    for error in errors:
        print("FAIL: {}".format(error), file=sys.stderr)
    sys.exit(1)

print("OK: release workflow is immutable-tag, least-privilege, metadata-only, draft-first, and prerelease-aware")
PY

python3 "$validator" "$workflow"

# Reproduce actions/checkout replacing an annotated tag with github.sha, then
# prove the workflow's restore command recovers the remote tag object.
tag_origin="$tmp/tag-origin.git"
tag_source="$tmp/tag-source"
tag_runner="$tmp/tag-runner"
git init --bare -q "$tag_origin"
git init -q "$tag_source"
git -C "$tag_source" config user.name "Release fixture"
git -C "$tag_source" config user.email "release-fixture@example.invalid"
git -C "$tag_source" commit --allow-empty -q -m init
git -C "$tag_source" tag -a v4.0.0-rc.1 -m "v4.0.0-rc.1 — Verbs"
git -C "$tag_source" remote add origin "$tag_origin"
git -C "$tag_source" push -q origin HEAD:refs/heads/main refs/tags/v4.0.0-rc.1
git init -q "$tag_runner"
git -C "$tag_runner" remote add origin "$tag_origin"
git -C "$tag_runner" fetch -q origin \
  +refs/heads/main:refs/remotes/origin/main \
  +refs/tags/v4.0.0-rc.1:refs/tags/v4.0.0-rc.1
[ "$(git -C "$tag_runner" cat-file -t refs/tags/v4.0.0-rc.1)" = tag ]
tag_commit="$(git -C "$tag_runner" rev-parse refs/tags/v4.0.0-rc.1^{commit})"
git -C "$tag_runner" fetch -q --no-tags origin \
  "+$tag_commit:refs/tags/v4.0.0-rc.1"
[ "$(git -C "$tag_runner" cat-file -t refs/tags/v4.0.0-rc.1)" = commit ]
(
  cd "$tag_runner"
  RELEASE_TAG=v4.0.0-rc.1
  git fetch -q --force --no-tags origin \
    "refs/tags/$RELEASE_TAG:refs/tags/$RELEASE_TAG"
)
[ "$(git -C "$tag_runner" cat-file -t refs/tags/v4.0.0-rc.1)" = tag ]
echo "OK: annotated tag object restored after checkout-style downgrade"

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

publish_script="$tmp/publish.sh"
python3 - "$workflow" "$publish_script" <<'PY'
import sys
from pathlib import Path

source, output = map(Path, sys.argv[1:])
lines = source.read_text(encoding="utf-8").splitlines()
marker = "      - name: Publish GitHub release"
try:
    start = lines.index(marker)
except ValueError as exc:
    raise SystemExit("missing publish step") from exc

run_start = None
for index in range(start + 1, len(lines)):
    if lines[index] == "        run: |":
        run_start = index + 1
        break
if run_start is None:
    raise SystemExit("missing publish run block")

script_lines = []
for line in lines[run_start:]:
    if line and not line.startswith("          "):
        break
    script_lines.append(line[10:] if line.startswith("          ") else line)
output.write_text("\n".join(script_lines) + "\n", encoding="utf-8")
PY

fake_bin="$tmp/fake-bin"
publish_fixture="$tmp/publish-fixture"
mkdir -p "$fake_bin" "$publish_fixture/dist"
printf '%s\n' 'Release title' > "$publish_fixture/dist/release-title.txt"
printf '%s\n' 'Release notes' > "$publish_fixture/dist/release-notes.md"

cat > "$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -eu

{
  echo CALL
  for arg in "$@"; do
    printf 'ARG=%s\n' "$arg"
  done
} >> "$GH_CALL_LOG"

if [ "${1:-}" = "release" ] && [ "${2:-}" = "view" ]; then
  exit 1
fi
EOF
chmod +x "$fake_bin/gh"

run_publish_policy() {
  ref="$1"
  log="$2"
  (
    cd "$publish_fixture"
    PATH="$fake_bin:$PATH" RELEASE_TAG="$ref" GH_CALL_LOG="$log" \
      bash -e "$publish_script"
  )
}

rc_log="$tmp/rc-calls.log"
stable_log="$tmp/stable-calls.log"
run_publish_policy v4.0.0-rc.1 "$rc_log"
run_publish_policy v4.0.0 "$stable_log"

python3 - "$rc_log" "$stable_log" <<'PY'
import sys
from pathlib import Path


def parse_calls(path):
    calls = []
    current = None
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if line == "CALL":
            current = []
            calls.append(current)
        elif line.startswith("ARG=") and current is not None:
            current.append(line[4:])
    return calls


def create_call(path):
    matches = [call for call in parse_calls(path) if call[:2] == ["release", "create"]]
    if len(matches) != 1:
        raise SystemExit("expected one gh release create call in {}".format(path))
    return matches[0]


rc = create_call(sys.argv[1])
stable = create_call(sys.argv[2])
expected_rc = [
    "release", "create", "v4.0.0-rc.1", "--verify-tag", "--draft",
    "--prerelease", "--latest=false", "--title", "Release title",
    "--notes-file", "dist/release-notes.md",
]
expected_stable = [
    "release", "create", "v4.0.0", "--verify-tag", "--draft",
    "--title", "Release title", "--notes-file", "dist/release-notes.md",
]
if rc != expected_rc:
    raise SystemExit("unexpected RC release create argv: {!r}".format(rc))
if stable != expected_stable:
    raise SystemExit("unexpected stable release create argv: {!r}".format(stable))

print("OK: release create argv is exact, metadata-only, and prerelease-aware")
PY

echo "OK: no-custom-asset policy, permission/draft mutations, and RC/stable publish policy passed."
