# Gatekeeper

Pre-adoption trust review for software artifacts. This Panda Verbs adaptation is
derived from SlowMist's `slowmist-agent-security` under MIT.

Current routes:

- skill and MCP installation;
- GitHub repository;
- URL or document;
- software product, service, API, or SDK.

Every route starts with STRIDE classification, follows a domain review under
`reviews/`, checks the shared `patterns/`, and returns the matching report under
`templates/`. Missing evidence stays unresolved. High-risk and reject verdicts
require an explicit human decision.

On-chain, DeFi, social-channel, private-overlay, and connector-specific reviews
are outside the public Panda Verbs scope.

See `SKILL.md` for the live process, `LICENSE` for the upstream license, and the
repository `THIRD_PARTY_NOTICES.md` for attribution.
