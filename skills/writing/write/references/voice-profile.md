# Voice profile resolution contract

Panda Verbs does not bundle an author's identity. Resolve an optional voice
profile from the host project before making voice-specific judgments.

## Resolution order

1. A path explicitly supplied by the user for this task.
2. A `voice_profile:` path under the project's `## verbs` section in
   `CLAUDE.md` or `AGENTS.md`.
3. `docs/voice-profile.md` when the project already contains it.
4. No profile. Continue in voice-neutral mode.

Do not inspect global identity, memory, or knowledge-store files to discover a
profile. Do not copy a bundled example into the project automatically.

## Minimum useful profile

A profile should contain evidence, not adjectives alone:

```markdown
# Voice profile

## Traits
- <named trait>: <observable behavior>

## Rhythm
- <sentence and paragraph habits>

## Language
- <language mix, terminology, punctuation>

## Positive anchors
- "<exact line written by the author>"

## Avoid
- <pattern the author has explicitly rejected>
```

Quoted anchors must be present in a source the host can read. Never reconstruct
or invent a representative line.

## Voice-neutral mode

When no profile resolves:

- preserve terminology and language choices already established in the draft;
- check structure, evidence, rhythm variation, clarity, and slop patterns;
- do not claim that a line "sounds like" or "does not sound like" the author;
- report `voice profile: unavailable; voice-specific checks skipped` once.
