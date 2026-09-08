---
name: prototype
description: Build a disposable logic or UI probe to answer one unresolved design question; capture the decision without silently expanding into production work.
user-invocable: true
---
# Prototype

Identify the single question the artifact must answer. Use [LOGIC.md](LOGIC.md) for an interactive state/logic probe or [UI.md](UI.md) for visual alternatives. Ask only when that choice cannot be derived from the request and repository.

Mark the artifact as a prototype, follow the project's existing location and runner conventions, and make it runnable with one command. Keep state in memory unless persistence is the question; use only an explicitly disposable store in that case. Expose the state needed to judge the result and avoid production infrastructure or unrelated polish.

Capture the question and validated answer in the driving brief or plan. Issue updates and publication still require authorization. Production implementation is separate unless already requested; never treat choosing a mock as shipping it. If retaining prototype code in Git, use a throwaway non-default branch.
