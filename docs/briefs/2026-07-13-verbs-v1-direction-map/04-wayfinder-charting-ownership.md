# Wayfinder charting ownership

Date: 2026-07-31
Entry: Wayfinder charting ownership
Status: resolved
Issue: #281

## The entry asked about the wrong skill

The entry framed this as a `wayfinder` problem: should it own charting end to
end — run the grilling inline, create the map and its entries itself — instead
of delegating to `grill` and stopping. That was the "轉接員" complaint from the
charting session that produced this map.

`wayfinder`'s charting mode is three steps, and two of them are "call `grill`"
and "stop" (`skills/productivity/wayfinder/SKILL.md`, Chart a new map). The map
file is not even written by `wayfinder`: `grill`'s routing gate writes
`docs/briefs/{YYYY-MM-DD}-{slug}-map.md` and defines its format
(`skills/productivity/grill/SKILL.md:152-158`), and `wayfinder` states it
"consumes that format and never forks it".

But `wayfinder`'s working mode — orient, claim, resolve by type, record,
graduate the fog, stop — is six substantial steps that no other skill
duplicates. The thin half and the thick half sit in the same skill.

The reason the charting half is thin is not that `wayfinder` was written lazily.
It is that the thing `wayfinder` needs — the interview — is not reachable on its
own. Verbs' `grill` bundles the interview protocol, forced alternatives, premise
refresh, and a routing gate that writes maps and calls `to-spec`. A skill that
wants only the interview must invoke all of it and then stop at someone else's
routing gate. That is precisely what being a switchboard operator means.

**Verbs' `wayfinder` is thin because Verbs' `grill` is fat.**

## The reference model decomposes the other way

`mattpocock/skills`, read directly:

| Skill | Body |
|---|---|
| `productivity/grilling` | The interview protocol. The only one of these that is model-invocable. |
| `productivity/grill-me` | One line: "Run a `/grilling` session." |
| `engineering/grill-with-docs` | One line: "Run a `/grilling` session, using the `/domain-modeling` skill." |
| `engineering/wayfinder` | Owns the map and its decision tickets on the issue tracker; invokes `grilling` inline during charting. |

`grill-me` and `grill-with-docs` are each a single line with
`disable-model-invocation: true`. They are not three interview skills. They are
one primitive plus thin named entry points, each composing that primitive with
something else.

So his `wayfinder` is fat because his `grilling` is thin. The composition is
inverted relative to Verbs, and the inversion is the whole finding.

The video (`https://www.youtube.com/watch?v=F3lL98Pj90o`) confirms the intended
flow: invoking `wayfinder` with a description leads it to explore the repository,
invoke the grilling skill, ask what done looks like, recommend a destination, and
then create the map and its tickets itself. Charting and walking are the same
skill — `wayfinder <ticket>` advances one. When the map is complete, `to-spec`
consumes the whole map and `to-tickets` decomposes it. As he puts it, wayfinder
sits in exactly the place `grill-with-docs` otherwise occupies.

## Decision

Extract the interview protocol from `grill` into its own primitive. `grill` and
`wayfinder` each compose it rather than one invoking the other wholesale.

This dissolves the escalation question that the composition otherwise raises. If
a `grill` session discovers the effort is larger than one session, there is no
need for `grill` to own map-writing as an escape hatch: `wayfinder` takes over
and re-enters the same primitive without re-interviewing. Today that escape
hatch is why `grill`'s routing gate writes maps at all, which is what inverted
the ownership in the first place.

Rejected: moving only the map-writing into `wayfinder` while leaving `grill`
monolithic. It relocates the artifact without giving `wayfinder` access to the
interview, so charting still means invoking all of `grill`. The switchboard
stays, it just forwards to a different extension.

Also rejected for now: doing this together with the tracker move. Adopting the
reference model fully means the map and its decision tickets live on GitHub
Issues, which is entry 6 and is blocked on what remains of entry 1. Extraction
does not depend on it, and bundling them doubles the blast radius of a change
that already touches a core skill.

## Consequence

The restructuring is spec-sized — it changes a core skill, `manifest.toml`,
dispatch, the Resolver, and the suite — so it does not happen here. It gets a
canonical Spec Issue via `to-spec`; this note is the decision record, that Issue
is the buildable specification.

Entry 6 inherits a sharpened question. Under the reference model, "does
frontier-by-query beat the markdown file" is not only a tracker question: the
decision tickets it describes are typed issues that `wayfinder` creates during
charting. Whether Verbs adopts that depends on this extraction landing first.

## Prerequisite found while routing

`to-spec` requires one unambiguous `tracker: github` under `## verbs`. This
repository's `CLAUDE.md` did not have it. Verbs shipped `setup-verbs`,
`to-spec`, and `to-tickets` and never configured its own tracker; every Issue in
this workstream so far was opened by hand, so nothing had exercised the path.
The line is added with this issue.
