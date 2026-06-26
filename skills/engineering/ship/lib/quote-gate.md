# Quote gate (no phantom quotes)

Before writing ANY drafted learning / SOP / rule, every verbatim quote (「...」 / "...") and every `[Source: <file>]` attribution in it MUST be verified greppable in the cited source:

```bash
grep -F "<a distinctive substring of the quote>" <cited-source-path>
```

If it does not match, do NOT write it as a quote: paraphrase without quotation marks, or drop the attribution. Reconstructing a quote from session/context memory instead of grepping the real source is the exact failure this gate prevents (audited 2026-05-30: backflow had been fabricating verbatim quotes attributed to non-existent sessions).
