# Output Validation

> Mandatory pre-response checks for `/write`. Run BEFORE sending ANY response. If any check fails, fix BEFORE responding. Do not mention the self-check to the user.

| Mode | Check | Violation = |
|---|---|---|
| Spar | Spine identified (one of 5 types) | Ask user to pick spine before proceeding |
| Spar | Opening check passed (no generic intro) | Suggest number-first or thesis-first alternative |
| Spar | No paragraph longer than 2 sentences | Rewrite as outline bullets |
| Structure | Zero new sentences not in original | Delete any new content |
| Structure | Closing check passed (ending adds something new) | Flag and suggest alternatives |
| Edit | 3-layer slop detection completed (vocab → structure → voice) | Run all layers now |
| Edit | Conditional zh references checked against trigger signals | Load matched ones; explicitly note "no zh signals matched" if none fired |
| Edit | No consecutive 3+ sentences of new prose outside `→` annotations | Convert to annotations |
| Edit | Multi-version alternatives were generated | Add them now |
| Edit | Voice profile was resolved, or voice-neutral mode was stated | Resolve per contract; never infer identity |
| Edit | At least one rhythm variation flagged or confirmed | Check paragraph lengths |
| Spar / Structure / Edit | For pieces >500 words (or X long posts >200 words): Four-Quadrant Check completed | Flag missing quadrants; do not auto-fill |
| Postmortem | Every category has an exact line quoted (or explicit "no line earns this row") | Restart and quote actual lines |
| Postmortem | Zero banned generic-praise words ("great post", "strong hook", "compelling", "engaging", "powerful", "thought-provoking", "well-crafted") | Restart |
| Postmortem | Chinese drafts quoted in source Chinese, not translated | Re-quote in source language |
| Postmortem | "Weakest part" includes a specific fix, not just "consider X" | Add concrete rewrite/cut/proof-add direction |
| Idea Gate | Stage-0 local overlap check ran against configured source directories | Run the local check now; if substantial overlap, default route → 暫不寫 |
| Idea Gate | Route is one of: original / repurpose / rewrite / research+ideate / 暫不寫 | Pick one or ask 1-2 disambiguating questions |
| Idea Gate | If route ≠ 暫不寫, full packet produced with ≤2 `missing` fields | If >2 missing, downgrade to 暫不寫 or flag user for specific info |
| Idea Gate | No prose body in output (packet only) | Convert any prose to packet bullets |
| Idea Gate | Packet ≤900 tokens (Shann's discipline) | Compress or split idea |
| Idea Gate | Voice anchors quoted verbatim in source language (not translated) | Re-quote in source language |
