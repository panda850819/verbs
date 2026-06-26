---
name: freeze
description: |
  Use when you want to lock editing scope to specific paths.
  Blocks edits outside the allowed directories for this session.
  Run /unfreeze to remove restrictions.
---

# Freeze

Lock editing scope to prevent accidental changes outside the working area.

## Usage

`/freeze src/api/` — only allow edits inside `src/api/`
`/freeze src/api/ tests/api/` — allow edits in both directories
`/unfreeze` — remove all restrictions

## On Invoke

1. Parse the arguments as a list of allowed paths (files or directories).
2. If no arguments: ask the user which paths to freeze to.
3. Announce:
   ```
   FREEZE active. Edits restricted to:
   - {path1}
   - {path2}
   All other files are read-only for this session.
   ```
4. For the remainder of this session, before any file edit (Edit, Write, NotebookEdit):
   - Check if the target file falls under an allowed path.
   - If not: **refuse the edit** and say: "FROZEN: {file} is outside freeze scope. Run /unfreeze to remove restrictions."
   - Never silently skip — always surface the block.

## Unfreeze

When the user says `/unfreeze`:
1. Remove all path restrictions.
2. Announce: "UNFREEZE: all files are editable again."
