# lib/outside-voice-rule.md — Third-party / cross-model finding integration

> Shared module. Loaded by skills that consult an outside voice (codex adversarial review, second-model cross-check, external linter, peer review) and need to integrate findings without auto-elevating them to mandate.
>
> Origin: pandastack `review/SKILL.md` Step 6.5 had auto-elevate-to-P1-on-cross-model-consensus rule that contradicted "user sovereignty" principle. 2026-05-03 self-audit caught this drift. Rule extracted here so all outside-voice integrations follow the same gate.

## Core rule

**Outside-voice findings are informational only. Never auto-elevate, never auto-apply. Always per-finding gate.**

This applies regardless of:

- How prestigious the outside voice is (a Codex finding is informational, an Anthropic-internal-tool finding is informational, a senior reviewer comment is informational)
- Whether the outside voice agrees with our assessment (consensus is signal, not mandate)
- Whether the finding looks objectively correct on first read (apply gate exists for a reason; the reason is asymmetry between "looks right" and "is right in context")

## Prior-direction conflict rule (added 2026-05-04)

**When integrating outside-voice findings, cross-check against prior user direction in the same session. If a finding contradicts a prior explicit user statement, surface the conflict — do not silently apply via gate-Y.**

The integrating skill must:

1. Before presenting any finding's `Apply? [Y/N/edit]` gate, scan the session for prior user statements on the same axis
2. If a finding suggests reverting / qualifying a stated direction, prepend the gate with the conflict:

   ```
   ⚠ CONFLICT: Codex suggests {patch}. Earlier in session you said {prior-statement}.
   These are incompatible. Confirm intent:
   [reverse]  apply codex patch (you are reversing earlier direction)
   [hold]     keep prior direction, codex finding routes to OPEN_QUESTIONS
   [edit]     supply a different reconciliation
   ```

3. Do NOT default to standard `Y/N/edit` gate on a contradiction — the user's `Y` would be ambiguous between "agree with codex" and "ack the input". The reverse/hold/edit triad forces explicit reversal-or-hold disambiguation.

### What counts as "prior user direction"

- Explicit statements in current session ("我未來也沒有要用 agent")
- Explicit statements in `~/.agents/AGENTS.md` (substrate is durable user direction)
- Explicit statements in project CLAUDE.md / AGENTS.md (project-level direction)
- Prior session memory under `~/.claude/projects/.../memory/feedback_*.md` (validated patterns)

Not "prior direction":
- One-off chat preferences from a different topic (don't confuse general routing with topical decisions)
- Decisions made before model's knowledge cutoff that were since explicitly reversed
- AI's own prior statements (those have no authority)

### Detection pattern

When a codex finding lands, before drafting the gate, ask:

> "Does this finding suggest reverting / qualifying anything the user said explicitly earlier in this session or in substrate?"

If yes → use the reverse/hold/edit gate. If no → standard Y/N/edit gate.

### Origin

- 2026-05-04 session — codex Q3 hybrid suggested keeping agents alongside skills. User had said earlier "未來也沒有要用 agent". I executed hybrid via standard Y gate, ate ~30 min of work that was reverted at session end. Learning: `docs/learnings/architecture/2026-05-04-skill-only-vs-hybrid-pandastack.md`

## When to load

Any skill that integrates outputs from a separate model / tool / human:

- `review` Step 6.5 (codex adversarial cross-check)
- `boardroom` (B4) — 4 voices critiquing one plan
- `gatekeeper` — when external security analysis is consulted
- `office-hours` (B5) — when bringing external research findings into a session
- `scout` — when surveying external repos / SKILL.md / agents
- Future: any skill that calls a sub-agent or fetches a third-party assessment

## Integration protocol

For each outside-voice finding:

```
1. Quote the finding verbatim (no paraphrase that loses nuance)
2. Compute pandastack-side context (what does THIS finding mean given our setup, constraints, prior decisions)
3. Print:

   ## Finding {n}: {short summary}
   **Outside voice says**: "{verbatim quote}"
   **Verdict (informational)**: {agree / disagree / partial / unknown}
   **Counterargument** (if disagree or partial): {why we don't simply apply}
   **Suggested patch** (if agree or partial-apply): {concrete change}

   Apply to final output? [Y / N / edit]

4. Wait for user response on the gate.
   - Y → apply patch as suggested, log to applied list
   - N → log to OPEN_QUESTIONS (NOT silent discard — the user might want to revisit)
   - edit → user supplies the modified patch, apply that, log
   - (no response after escape-hatch trigger) → log all remaining as OPEN_QUESTIONS, stop
```

## What this prevents

The drift mode this exists to block: **finding looks compelling → model auto-incorporates → user is presented with a "done" output → user can't tell what was the model's judgment vs the outside voice's**. Symptoms:

- "Updated based on review feedback" with no indication which feedback was applied
- Findings silently P1-elevated because "two models agreed"
- N (rejected) findings disappear with no trace, so re-running the review surfaces them again as if novel
- Outside-voice voice replaces inside voice in the final output

## Required output contract

The integrating skill must produce a section listing:

```markdown
## Outside-voice integration (skill: {parent-skill}, source: {outside-voice})

### Applied (Y)
- Finding {n}: {summary} — {patch summary}

### Edited (edit)
- Finding {n}: {summary} — {user's modified patch}

### OPEN_QUESTIONS (N)
- Finding {n}: {summary} — {why user rejected, if stated}

### Skipped (escape-hatch)
- Finding {n}: {summary} — not gated, user stopped early
```

Never combine "Applied" and "Outside voice findings" into one undifferentiated list. The user must be able to grep "what did I apply vs what did I reject vs what's still open".

## Anti-patterns

- ❌ "The outside voice raised 5 findings, I've incorporated them all" — no gate, no audit
- ❌ "Cross-model consensus reached on X, auto-applying" — consensus is signal, not mandate
- ❌ "Rejected findings discarded" — no, route to OPEN_QUESTIONS for next session pickup
- ❌ "Outside voice was right, your concern was wrong" — outside voice is informational, you don't have authority to overrule the user's concern based on it
- ❌ Re-asking on the same finding after Y/N answered ("are you sure about Finding 3?") — that's escape-hatch territory

## Why "informational only" is non-negotiable

Three failure cases observed:

1. **Authority laundering** — model uses the outside voice to bypass user's own judgment ("but Codex said...")
2. **Drift accumulation** — auto-applied findings compound across sessions, gradually moving the system away from user's intent
3. **Rejection invisibility** — user rejects a finding once, model surfaces it again as if novel because there's no log

The per-finding `Y/N/edit` gate plus OPEN_QUESTIONS log fixes all three.

## Origin

- pandastack `review/SKILL.md` Step 6.5 — auto-elevate rule (drift)
- 2026-05-03 self-audit — author wrote rule that contradicts own principle
- pandastack 2026-05-03 review SKILL.md patched: codex findings informational only, per-finding gate, N → OPEN_QUESTIONS
- 2026-05-04 — extracted to `lib/outside-voice-rule.md` for cross-skill ref
