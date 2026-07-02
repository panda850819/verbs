# Verify + near-neighbor route check

Reference procedure for skill-creator Phases 6 and 6.5. Run both before declaring a skill done.

## Phase 6 — Verify

Run the checks that exist in this repo. Pandastack currently has a manual resolver golden file, not Bun test files.

```bash
cd "$PANDASTACK_ROOT"

git diff --check

python - <<'PY'
from pathlib import Path
import re, sys
root = Path('skills')
errors = []
for p in root.rglob('SKILL.md'):
    s = p.read_text()
    if not s.startswith('---'):
        errors.append(f'{p}: missing frontmatter start')
        continue
    if '\n---\n' not in s[3:]:
        errors.append(f'{p}: missing frontmatter close')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print('OK skill frontmatter')
PY

# If you changed routing / descriptions, manually run the affected cases in:
# tests/resolver-golden.md
```

Do not use `bun test tests/` unless actual `.test` / `.spec` files have been added. If a check fails, read the error and fix the frontmatter / RESOLVER / body before merging.

## Phase 6.5 — Near-neighbor route check (manual — deliberately NOT a CI gate)

Whenever you add or edit a skill's trigger / description, manually confirm it did
not start stealing a **near-neighbor's** traffic (route confusion). This is a
~5-minute manual pass, not a runner + fixture + CI gate — at pandastack's N the
infra would cost more than it saves and would rot in a solo repo.

1. Pick ~6 **confusable pairs** whose trigger surfaces sit closest to the one you
   touched. Sources for the candidates: `RESOLVER.md` Disambiguation
   section, `DISPATCH.md`, each SKILL.md's `Skip` / `NOT for` frontmatter, and
   `lib/skill-decision-tree.md`. Standing examples: grill vs office-hours,
   the four review skills, ship vs handover.
2. For each pair, write ~1 short prompt that *should* route to each side (≈6
   prompts total). Read each prompt against the two descriptions and confirm it
   routes to the intended skill — and that your edited skill does NOT now also
   match the neighbor's prompt.
3. If a prompt routes wrong or matches both, tighten the trigger/`Skip` wording
   (smallest durable change) and re-check. Log nothing; the check is the gate.

This is the cheap, solo-durable version of yao-meta-skill's route-confusion guard:
steal the mechanism, refuse its harness shape.
