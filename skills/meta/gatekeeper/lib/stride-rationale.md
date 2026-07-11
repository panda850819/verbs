# STRIDE — worked example and why-before-routing

Reference for Step 0 of the gatekeeper SKILL.md. Cold-loaded; the SKILL.md classifier protocol is the live process.

## Worked example (skill installation)

Artifact: `random-mcp-server` from `npm install`.

```
S (spoofing):              confirmed (publisher is 2-day-old account, no GH link)
T (tampering):             confirmed (postinstall script downloads + executes shell)
R (repudiation):           none
I (info disclosure):       suspect (reads ~/.aws/credentials per code grep)
D (DoS):                   none
E (eop):                   confirmed (writes to /usr/local/bin/, escalates beyond declared scope)
```

Output: `stride_categories: [spoofing, tampering, eop, info-disclosure-suspect]` → 🔴 HIGH floor → reject without explicit user override.

## Why STRIDE before routing

The four review templates (skill-mcp / repository / url-document /
product-service) ask similar questions in domain-specific language. STRIDE is
the common vocabulary that lets findings be aggregated and ranked. Without it,
each review is an island.
