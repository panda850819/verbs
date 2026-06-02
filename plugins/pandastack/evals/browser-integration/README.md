# Browser Integration Harness — qa + agent-browser

`qa` and `agent-browser` scored **needs-integration** in the 2026-06-02 non-A/B
eval: their value is a live browser side-effect (navigate, interact, DOM/a11y
assert, screenshot) that paper A/B cannot reach. This harness runs the real
`agent-browser` CLI against `fixture.html` and asserts on actual side-effects —
the correct axis for these skills.

## Run

```
./run.sh      # exit 0 = all pass · 1 = assertion failed · 3 = no browser on host
```

## What it asserts (the real axis, not single-output text)

- DOM read: initial `#counter` == `Counter: 0`
- click side-effect: clicking `#inc` mutates `#counter` to `Counter: 1`
- form-input side-effect: filling `#name` updates `#greeting`
- screenshot artifact is produced and non-empty

## The pattern (how to eval any browser-driven skill)

Persistent `--session <name>` keeps one browser across CLI calls; `eval` reads
the live DOM; assertions check the side-effect, not chat prose. To eval a real
`qa` scenario, point the fixture (or `open`) at a local dev-server URL and add
assertions for the flow under test. Single-output A/B is the wrong axis for
these skills; these side-effect assertions are the right one.
