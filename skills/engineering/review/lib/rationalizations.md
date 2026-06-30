# Review — Common Rationalizations

Anti-bypass table. Each shortcut is tied to the concrete failure it causes.

| Rationalization | Reality |
|---|---|
| "Step 0 audit takes too long, skip it" | The audit is 5 commands and 30 seconds. It catches the stash you forgot, the TODO marker still in the diff, the file you've touched 12 times this month — the structural drift signals you can't see while head-down in the patch. |
| "No need to load learnings, I remember the patterns" | Past-you wrote them down precisely because future-you doesn't remember them in fresh context. Confidence decay is part of the format — read them, don't reconstruct them. |
| "Cold review duplicates Step 5" | Same context produces same blind spots. Cold review with no diff context catches assumptions that Step 5 already absorbed and stopped questioning. The whole point is decorrelated context. |
| "Codex unavailable, just skip Step 6.5" | Mark `unavailable` in the completion box. Skipping silently turns a missing gate into an invisible gate. The box says what ran and what didn't — that's the contract. |
| "P2 is just nits, skip them" | P2 nits are the texture readers feel. List them in the box even if you defer. Done = P0/P1 zero, P2 listed and triaged, not P0/P1 zero and P2 hidden. |
| "I already reviewed this in my head while writing" | Writing the review forces the form. Half the issues surface only when you have to phrase them as findings. In-head review is a vibe, not a review. |
| "Patch-and-pray once more, no need to brief Codex with full picture" | After 3-4 failed patches the next patch is statistical noise. Stop, dump the full failure picture (what was tried, what broke, what's still broken), let a fresh-context reviewer (Codex) frame it. Recovery from "one more patch" loop is the longest debug. |
