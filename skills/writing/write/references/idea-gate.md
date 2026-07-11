# Idea Gate (`/write idea-gate`)

User specifies a candidate idea source (`originals/` path, `ideas/` path, another local note, raw text, or URL). Your job: decide if/how to promote it to a draft, and (if yes) produce a writer context packet that hands off cleanly to `/write spar`.

This mode is the **upstream gate** for the writing pipeline. It exists to prevent two failure modes:
- **Originals piling up unpromoted** -- raw thinking accumulates in `originals/` but never becomes published writing
- **Wrong route picked late** -- drafting starts before "should this even be a post?" gets answered

**Input forms**:
- `/write idea-gate originals/2026-MM-DD-some-thought.md` -- specific local note
- `/write idea-gate ideas/some-half-formed.md` -- half-baked idea page
- `/write idea-gate "raw text or URL"` -- ad-hoc input (for URL, prefer `/write ref` first)

**Process**:

1. **Load source.** If local note, read full content + frontmatter. If raw text or URL, work with what's given.

2. **Stage 0 -- local overlap check (mandatory)**. Before route decision, search the configured writing/source directories for existing coverage:
   - `grep -ril <key-terms> writing/ originals/ ideas/ 2>/dev/null`
   - If existing pages cover ≥70% of the same thesis → default to **暫不寫** with "merge into existing X" suggestion
   - If existing pages are tangential but related → flag the cross-link for the brief's "open loops"

3. **Pick the route** (one of five). Ask 1-2 disambiguating questions ONLY if genuinely ambiguous; otherwise pick and explain in one line:

   | Route | When | Brief draws on |
   |-------|------|----------------|
   | **ORIGINAL** | Genuinely new take from user's own thinking / lived experience. Not previously published. | Foundation files (positioning, proof bank, pillars). No external source. High taste investment. |
   | **REPURPOSE** | Builds on existing owned content (a prior post, thread slice, essay paragraph). | Owned source + slice instruction. Format changes; spine stays user's. |
   | **REWRITE** | External material worth a teardown (article, tweet, transcript) translated through user's POV. | External source + voice rules + explicit "what to keep, what to credit". |
   | **RESEARCH+IDEATE** | Topic worth exploring but no thesis yet. | Not a draft -- outputs a sharpened idea or angle list, back into `ideas/`. |
   | **暫不寫** | Idea is half-baked / duplicates existing local coverage / thesis too vague / voice-borrowing risk too high. | One-sentence reason + suggestion (mature 1-2 weeks / merge into X / run `/write spar` first to find thesis). |

4. **If 暫不寫**: stop. Output the reason + concrete next-step suggestion. Do NOT produce a packet.

5. **If ORIGINAL / REPURPOSE / REWRITE / RESEARCH+IDEATE**: produce the writer context packet:

   ```
   writer context packet
   ─────────────────────
   route:         [original / repurpose / rewrite / research+ideate]
   source:        [local path or external URL or "raw input"]
   thesis:        [one sentence the post must prove -- pulled from source, not invented]
   reader:        [specific person who should save it -- by role + situation, not segment]
   proof:         [numbers, examples, lived evidence the source contains]
   angle:         [unexpected framing -- what makes this not generic]
   constraints:   [format (X long post / blog / essay), target length, tone]
   voice anchors: [2-3 lines from source that sound like user -- keep verbatim]
   risks:         [what would make this read as slop, hedge, or borrow-authority]
   open loops:    [what user hasn't decided, that `/write spar` should pin down]
   ```

6. **Handoff**: end output with one line:
   ```
   Next: `/write spar` with this packet, or `/write structure` if prose already drafted.
   ```

**Rules**:

- Do NOT auto-write the draft. Idea-gate produces packet, not prose. If you wrote any paragraphs of body content, restart.
- Do NOT invent proof / examples / numbers. If source lacks them, mark `proof: missing -- needs interview / data / lived example` and flag to user before they proceed to spar.
- For Chinese sources, keep `voice anchors` verbatim in Chinese -- never translate when quoting back.
- If 4 active routes genuinely all fit (rare), default to **ORIGINAL** (highest leverage on user's voice).
- **暫不寫 is a real option, not a hedge**. Roughly 30-40% of raw originals/ entries should sit longer or merge with existing pages, not become posts. Defaulting everything to ORIGINAL inflates draft queue with weak ideas.
- If source is someone else's tweet/essay and route is REWRITE, flag the "voice-borrowing risk" in `risks:` explicitly -- writing user's own POV on someone else's frame is the slop trap.
- Cap packet at 400-900 tokens (Shann's discipline). If you need more, the idea is too broad -- split or downgrade to RESEARCH+IDEATE.

Origin and adaptation notes: `[[media/articles/shann-content-os-bookmarkable-personalized]]`.
