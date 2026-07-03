# lib/diagnosis.md — debug detail (catalogs the SKILL.md points to)

Loaded by `debug` when the cause is not obvious. SKILL.md carries the three reflex-overrides; this
file is the reference: the few method-specifics worth consulting when stuck, plus the lore.

## Diagnosis discipline (reach here only when the obvious pass failed)

The non-generic moves, the ones easy to skip under momentum:
- **The hypothesis must explain every symptom**, not the first one reported. Explains only some → it is
  still a symptom-level guess. Timing bug (flicker, intermittent, race) → reproduce reliably first.
- **Run the one probe that would FAIL if the hypothesis were wrong.** Contradicts → discard it
  completely; do not stack a fix onto a disproven hypothesis. Same symptom after a fix → the hypothesis
  was unfinished, re-read the path from scratch.
- **3 failed hypotheses → stop** and hand off (format below).
- **Deflection tell**: when someone says "that part doesn't matter", look there — the avoided area is
  often where the bug lives.

## Instrument-first, by bug class

- **Visual / rendering** (layout, paint, stacking, font): static analysis first — trace layers /
  stacking contexts / order in DevTools. Logs cannot see what the compositor does.
- **Behavioral / lifecycle / async** (event delivery, focus, timers, navigation, state machines,
  ordering, "is this object still alive"): instrument **immediately**, as part of forming the
  hypothesis, before writing any fix. Static reading alone almost never resolves these.
- **Pure logic** (wrong formula, off-by-one): static reading is enough.

## Logging playbook (behavioral / async bugs)

- **Binary-search the midpoint.** Don't log every line. Log halfway down the suspect path; the result
  halves the search space.
- **Log what discriminates.** A log that prints the same value whether the hypothesis is true or false
  tells you nothing. Log the one value/state that differs between the two worlds.
- **Log the boundary.** Lifecycle/async bugs live at boundaries: callback enter/exit, await before/after,
  state X before/after Y runs, "is this object alive here". Log both sides of the boundary.
- **The log changed the behavior = timing/concurrency bug.** If adding a log makes the bug move or vanish,
  you have a race, not a logic error. Treat the Heisenbug as the diagnosis, not a nuisance.
- **Prefix discipline.** Tag every temporary probe with one shared marker such as `[DEBUG-a4f2]`;
  cleanup is one grep, and leftovers are impossible to miss.
- **Removal discipline.** Strip every diagnostic log before claiming done. A left-behind probe is debt.

Distinct from the `review` test-loop alarm "my added log didn't show up = the build under test isn't mine":
that is a *pipeline* tell (owned by `review` / `lib/verify-the-test-loop.md`); the rules above are about
*reading* the runtime, not trusting the loop.

## Bisect ("used to work")

0. **Protect the worktree.** `git status -sb -uall`. Modified/staged/untracked present → do NOT bisect in
   this checkout. Create a temp detached worktree from the same HEAD, bisect there, then `git bisect reset`
   and remove it. Temp worktree impossible → stop and ask for explicit stash/cleanup approval.
1. Candidate good tag: `git tag --sort=-version:refname | head -10`, or ask for the last known-good commit.
2. **Diff-first shortcut.** Last-good only one/few releases back → `git diff <last-good-tag>..HEAD -- <suspect path>`
   and read the delta directly. The culprit is usually visible there; reading costs far less than driving a bisect.
   Fall through to bisect only when the diff is too large or the culprit is not obvious.
3. Define a non-interactive pass/fail test command before starting. Bisect is worthless without a reproducible check.
4. `git bisect start && git bisect bad HEAD && git bisect good <tag-or-hash>`; run the test at each step;
   mark `good`/`bad`. Let bisect drive — do not skip commits unless asked.
5. Culprit named → read only that diff, find the exact line that introduced the regression.
6. `git bisect reset`. Read large files once and reference from notes, not at every step.

## 3-failure handoff format

After three failed hypotheses, stop and emit:

```
Symptom:    every observed symptom, in the user's concrete words where useful
Tested:     each hypothesis tried
Evidence:   what each probe showed
Ruled out:  what the evidence eliminated, and how
Unknowns:   what is still unexplained
Next:       the cheapest probe that would discriminate the remaining hypotheses
```

Done definition for a real fix: a test fails on the old code and passes on the new, and the commit message
says why it recurred. Not "compiles" and not "looks right".

## Known bug classes (full)

### Listener owns lifetime
Any function that registers `fs.watch` / `setInterval` / event listeners AND receives an external resource
(engine / connection / lock) MUST return a Promise that resolves only on close. Returning early lets the
caller's `finally`-cleanup race the callbacks.
- Smell: a `// long-running` comment with no awaitable shutdown handle.
- Smoke before merge: run the command for real with a `--once`-style flag, trigger the event, confirm the
  done-marker in the log. Helper-only unit tests miss this class entirely.

### Running aggregate, not re-processed accumulator
`for (x of list) { fn([...acc, x]) }` is O(N²) when fn's cost grows with input (slice / tokenize / hash /
join / sort). Maintain a running sum / size / hash alongside the accumulator and update additively.
AI-generated chunkers, validators, dedup loops trip this.
- Smoke: real-data run, not a tiny fixture. Add a perf regression test on the largest realistic input,
  ceiling = 10x linear baseline.

### Alert schema category leak
Reporting bots that extract `tickers` / `companies` from an LLM classifier often let generic buckets leak
into concrete-label fields, e.g. `Prescription drug companies` rendered as `公司`. Trace the output schema
through the formatter before blaming the classifier.
- Fix: separate concrete instruments (`tickers`), named entities (`companies`), and generic impact buckets
  (`sectors` / `themes`); filter generic phrases out of concrete fields.
- Smoke: a formatting test that asserts generic buckets do not render under concrete labels.

### CLI archetypes (Panda's surface: Mole bash, bird/defuddle Node, gbrain, reporting bots)
- **PATH / wrapper drift** — a tool resolves to a different binary under cron / a subshell / a stripped
  env than in your interactive shell. Symptom: "works when I run it, fails from the bot." Print
  `command -v <tool>` and the effective `PATH` from inside the failing context before blaming the tool.
- **stdout/stderr stream-contract regression** — a command that used to put data on stdout starts mixing
  diagnostics in, or a caller string-matches output captured with `stdio:'inherit'`. Separate the streams;
  assert the data stream, not the merged transcript.
- **Subprocess pipe backpressure** — a child fills the pipe buffer and blocks because the parent is not
  draining stdout while waiting on the child to exit. Drain the stream or use a file, do not `await` exit
  before reading.
- **Multi-sample cold-start** — single-sample probes (`top -l 1`, first-request latency) read a cold
  number. Take ≥2 samples and use the warm one (`top -l 2`, discard sample 1).

## Cross-references

- `../../../lib/learning-format.md` — the `type: learning` / `type: pitfall` shape for the On-close gate.
- `review` owns the build/deploy test-loop trust rules (`../review/lib/...` and the shared
  `../../../lib/verify-the-test-loop.md`); debug owns the diagnosis method. No overlap: trust-the-loop vs find-the-cause.
