# Codebase Design matched cases

## Case A — job runner
A job runner has 14 call sites. Every caller selects a queue, serializes payloads, chooses retry/backoff, translates provider errors, and emits metrics. There is one queue provider today, but tests need deterministic timeout and retry behavior. Design the module interface and seam. State what callers know, what stays inside, how tests exercise it, and whether the abstraction earns its keep.

## Case B — feature flags
Six handlers read environment variables directly, parse boolean/percentage variants, apply user bucketing, and choose fallback behavior. Production uses environment-backed flags; tests repeatedly patch process state. A remote flag provider is planned next quarter but not committed. Design the module interface and seam. State what callers know, what stays inside, how tests exercise it, and whether to introduce an adapter now.
