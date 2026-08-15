# Architecture report contract

Generate one static HTML document that remains readable offline and without
JavaScript. Repository evidence determines the content; this file determines its
shape.

## Required structure

1. **Header:** repository, scan scope, path-selection basis, commit range when
   used, and evidence gaps.
2. **Legend:** solid box = module, dashed stroke = seam, red = leaked knowledge,
   dark thick box = deep module.
3. **Candidate cards:** ordered by strength and payoff evidence.
4. **Top recommendation:** one non-Speculative candidate and one sentence naming
   its strongest locality, leverage, or net-deletion evidence. Omit when none qualifies.

Each candidate card contains:

- title and `Strong`, `Worth exploring`, or `Speculative` badge;
- repository-relative files;
- observed friction with file-backed evidence;
- proposed deepening or simplification without a final method or type design;
- production-consumer or tests/docs-only evidence;
- locality, leverage, net-deletion, and test-surface effects as applicable;
- explicit deletion-test result and current-decision check;
- ADR warning when applicable;
- side-by-side Before / After diagram.

## Diagram rules

Use inline SVG or semantic HTML boxes. Choose the pattern that carries the
claim: dependency flow, call-graph collapse, layered pass-through, or interface
mass. Label arrows and seams; color alone cannot carry meaning. Keep the same
actors in Before and After so the change can be compared. The After view may
show a proposed seam, but must not invent method names or signatures.

Every diagram needs a concise text alternative in `aria-label` or adjacent
visually hidden text. Keep labels readable at 1280px and stack Before above
After below 760px.

## Offline scaffold

Use inline CSS only. Include at least:

```html
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  :root { color-scheme: light; --ink:#172033; --muted:#667085;
    --line:#d8dee9; --paper:#f7f5f1; --card:#fff; --accent:#087f5b;
    --warn:#a15c00; --leak:#c92a2a; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--paper); color:var(--ink);
    font:16px/1.5 ui-sans-serif,system-ui,sans-serif; }
  main { width:min(1120px,calc(100% - 32px)); margin:0 auto; padding:48px 0; }
  article { margin:28px 0; padding:24px; background:var(--card);
    border:1px solid var(--line); border-radius:14px; }
  .comparison { display:grid; grid-template-columns:1fr 1fr; gap:18px; }
  .files { font-family:ui-monospace,SFMono-Regular,monospace; }
  .sr-only { position:absolute; width:1px; height:1px; overflow:hidden;
    clip:rect(0,0,0,0); white-space:nowrap; }
  @media (max-width:760px) { .comparison { grid-template-columns:1fr; } }
</style>
```

Add only styles the report uses. Do not load fonts, CSS, images, Mermaid, or
scripts from remote origins. Do not include JavaScript.

## Safety and truthfulness

HTML-escape every repository-derived value, including file paths, code symbols,
commit subjects, ADR titles, and domain terms. Use repository-relative display
paths. Never embed source file contents, secrets, environment values, or links
that execute commands. A diagram edge represents a traced dependency, not an
inference; visually mark unresolved relations as unknown.

Sparse evidence must remain sparse. Prefer one well-proven card over several
plausible cards. When no candidate survives, render a valid report whose main
finding is `No investment-worthy architecture candidate found in this scope.`
