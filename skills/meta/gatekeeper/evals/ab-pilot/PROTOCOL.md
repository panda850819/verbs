# A/B Eval Protocol — does loading this skill help, hurt, or do nothing?

> Nisi principle (media/videos/nisi-deleted-95-percent-skills-personalized):
> "Load this skill 77% correct / no skill 97% correct — I was actively making
> it worse, and I only knew because I measured it." This protocol produces that
> number for a Panda Verbs skill instead of guessing.

## Design

For a target skill S, fix a set of FIXTURES (tasks S claims to handle). Run each
fixture through two arms with the SAME model:

- **arm WITHOUT** — fixture only, no S injected. Baseline model capability.
- **arm WITH**    — S's full SKILL.md prepended, then the fixture.

A neutral JUDGE (skill-agnostic rubric, scores task CORRECTNESS not "did it
follow S's format") rates each arm's output. Compare pass rates.

Outcome reading:
- WITH > WITHOUT → skill earns its tokens.
- WITH ≈ WITHOUT → skill is noise; the model already knew. Candidate to cut.
- WITH < WITHOUT → skill actively hurts (over-constrains / sends on goose chase). Cut or fix.

## Rubric must be NEUTRAL

The judge scores the *answer*, not adherence to S. Scoring "did it use S's
template" rigs the test for WITH. Score: correct verdict, real issues found,
false issues invented, no unsafe action. A skill that makes the model invent
false issues scores WORSE even if its output is prettier.

## Fixtures pick spread

Include at least one fixture where the *naive* answer is correct and the skill
might over-fire (here: a benign-but-suspicious-looking artifact). That is where
"skill makes it worse" shows up — an all-malicious fixture set hides it because
both arms say HIGH.
