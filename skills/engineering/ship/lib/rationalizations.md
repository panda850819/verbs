# Ship — Common Rationalizations

Anti-bypass table. Each shortcut is tied to the concrete failure it causes.

| Rationalization | Reality |
|---|---|
| "Skip pre-flight, the branch looks clean" | "Looks clean" ≠ `git status` clean. Pre-flight is 2 seconds. Catches the tracked-but-unstaged file you'd otherwise leave behind. |
| "No CI on this repo, just push" | If there's no CI, ship sets up at minimum a type-check + build gate. "Push and pray" is how broken main happens. |
| "I'll write the PR description later, push first" | The PR description's draft window is the 60 seconds after commit. Later means cold context — you'll write a worse description that helps no future-you bisect. |
| "Squash everything into one commit" | Not unless the project config says so. Per-commit history is what `git bisect` needs. Squash on merge is fine; squash before push destroys the working set. |
| "`--no-verify` because hooks are slow" | Hook bypass is the skin-shed before the real bug ships. If hooks are too slow, fix the hooks, don't bypass them. |
| "Push to main directly, it's just a docs change" | Trunk-based ≠ main-direct. Even one-line docs go through the PR + CI loop in this stack — the contract is uniform so it's reliable. |
| "Skip Step 4 review gate, I already reviewed mentally" | If you can't point at the `/review` output, you didn't review. Self-review is fine; undocumented self-review is not. |
