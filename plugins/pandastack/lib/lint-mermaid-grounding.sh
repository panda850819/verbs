#!/usr/bin/env bash
# lint-mermaid-grounding.sh — code-level enforcement of deepwiki's source-grounding rule.
#
# Nisi principle: enforce, don't instruct. deepwiki's prose rule "no wired diagram
# without read source" leaked TWICE — the model re-smuggles directional edges via a
# "canonical / conventional / likely layout" block. A prompt can't hold this; a lint can.
#
# Checks a deepwiki markdown output: if it contains directional mermaid/flow edges
# (A --> B, A -> B, boxed arrows) but NO concrete source grounding (a file path with
# line ref, or an explicit "Source:"/"read from" citation), it FAILS — the edges
# assert relationships that were never verified from source.
#
# Usage: lint-mermaid-grounding.sh <markdown-file>
# Exit:  0 grounded or no edges · 2 ungrounded edges found · 1 file missing
set -euo pipefail

F="${1:-}"
[ -n "$F" ] && [ -f "$F" ] || { echo "lint-mermaid-grounding: file '$F' not found" >&2; exit 1; }

# Directional-edge signals: mermaid (-->, -.->,  ==>), ascii/box flow (->), and the
# smuggle pattern (canonical/conventional/likely/typical layout near an arrow).
EDGES=$(grep -nE '(-->|-\.->|==>|[]A-Za-z0-9_)] *-> *[[A-Za-z0-9_(])' "$F" || true)

[ -z "$EDGES" ] && { echo "GROUNDING OK: no directional edges in '$F'."; exit 0; }

# Smuggle-back-in pattern: a "canonical/conventional/likely/typical/standard layout"
# claim is never grounding — flag it regardless.
SMUGGLE=$(grep -nEi '(canonical|conventional|typical|likely|standard)[ -]+(go |rust |node |python )?(layout|flow|pipeline|order|structure)' "$F" || true)

# Grounding evidence: a concrete source citation — path/file.ext:line, or an explicit
# Source:/read-from marker pointing at a real file.
GROUND=$(grep -nE '([A-Za-z0-9_./-]+\.[A-Za-z]{1,4}:[0-9]+)|([Ss]ource:[^A-Za-z]*[A-Za-z0-9_./-]+\.[A-Za-z]{1,4})|read (from )?(the )?source' "$F" || true)

if [ -n "$SMUGGLE" ]; then
  echo "GROUNDING FAIL: '$F' restates edges via a canonical/likely-layout block (the smuggle pattern). Bar it — directional edges on unread source ship anyway." >&2
  echo "$SMUGGLE" >&2
  exit 2
fi

if [ -z "$GROUND" ]; then
  echo "GROUNDING FAIL: '$F' draws directional edges with NO source citation (no path:line, no 'Source:' marker). Either cite the read import/call, or use an edgeless inventory." >&2
  echo "$EDGES" | head -8 >&2
  exit 2
fi

echo "GROUNDING OK: '$F' has directional edges AND source citations."
exit 0
