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

# Grounding evidence: a CONCRETE source citation — path/file.ext:line or
# "Source: path.ext". Prose like "I read the source" does NOT count (trivially
# writable smuggle). Require a real file token.
GROUND=$(grep -nE '([A-Za-z0-9_./-]+\.[A-Za-z]{1,4}:[0-9]+)|([Ss]ource:[[:space:]]*[A-Za-z0-9_./-]+\.[A-Za-z]{1,4})' "$F" || true)

# Grounded → pass, even if the prose happens to say "canonical" descriptively.
# The smuggle check only matters when there is NO citation (the deepwiki leak).
if [ -n "$GROUND" ]; then
  echo "GROUNDING OK: '$F' has directional edges AND source citations."
  exit 0
fi

SMUGGLE=$(grep -nEi '(canonical|conventional|typical|likely|standard)[ -]+(go |rust |node |python )?(layout|flow|pipeline|order|structure)' "$F" || true)
if [ -n "$SMUGGLE" ]; then
  echo "GROUNDING FAIL: '$F' restates edges via a canonical/likely-layout block with NO source citation (the smuggle pattern)." >&2
  echo "$SMUGGLE" >&2
  exit 2
fi
echo "GROUNDING FAIL: '$F' draws directional edges with NO source citation (no path:line, no 'Source:' marker). Cite the read import/call, or use an edgeless inventory." >&2
echo "$EDGES" | head -8 >&2
exit 2
