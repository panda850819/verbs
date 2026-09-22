# lib/review-convergence.md — make escalated review converge

> Shared module. Load when an escalated review has an earlier report, opens an
> isolated reviewer, or verifies remediation. It bounds review work without
> treating a budget limit as approval.

## Epoch and artifact identity

The first escalated review opens one epoch bound to the intent and base. Name it
`<base-short>-<intent-slug>`. A patch change alone does not open a new epoch.
Materially changed intent or scope requires an explicit rebind and a new epoch.

Hash the exact diff bytes under review and report `patch: sha256:<digest>`. A
prior conclusion applies only to its recorded patch. If the requested patch is
unchanged, return the prior result instead of running another reviewer.

## Round budget

An epoch permits at most:

1. `PRIMARY` — one owning-context review.
2. `COLD` — one isolated read-only review, only when the Review skill earns it.
3. `VERIFY` — one focused check after the patch changes to remediate an open
   P0/P1 or a load-bearing disputed finding.

`VERIFY` traces only the recorded trigger and changed mechanism plus interaction
with touched code. It is not another whole-diff review. P2/P3 remediation uses
narrow deterministic checks unless it changes a trust boundary or the bound
intent. A cold result never launches another cold reviewer.

When the next requested round is already spent, or `VERIFY` discovers an
unresolved/new load-bearing finding after the budget is spent, return
`BLOCKED_REVIEW_LOOP`. Name the unresolved finding IDs and require an owning
context or human to rebind scope; never translate the stop into `CLEAN`.

## Finding lifecycle

Keep stable IDs across rounds. Merge reports by mechanism, not title. IDs from
an isolated result are proposals; the owning context remaps collisions and
preserves the epoch's existing ID for a known mechanism.

```text
OPEN -> REMEDIATED -> VERIFIED
OPEN -> DISPUTED
OPEN -> SUPERSEDED
REMEDIATED -> OPEN       # original trigger still fails
```

Only observed evidence moves `REMEDIATED` to `VERIFIED`. `DISPUTED` and
`SUPERSEDED` require a reason and evidence reference.

## Typed isolated-review result

When the host supports typed subagent output, pass this as its structured output
schema. Otherwise require an equivalent JSON object and validate every required
field before merging it.

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["epoch", "round", "patch", "decision", "findings", "coverage_gaps", "scope_drift"],
  "properties": {
    "epoch": {"type": "string", "minLength": 1},
    "round": {"const": "COLD"},
    "patch": {"type": "string", "pattern": "^sha256:[0-9a-f]{64}$"},
    "decision": {"enum": ["CLEAN", "FINDINGS", "BLOCKED", "BLOCKED_REVIEW_LOOP"]},
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "severity", "status", "title", "file", "line", "trigger", "mechanism", "consequence", "direction", "evidence"],
        "properties": {
          "id": {"type": "string", "pattern": "^F-[0-9]{3}$"},
          "severity": {"enum": ["P0", "P1", "P2", "P3"]},
          "status": {"enum": ["OPEN", "REMEDIATED", "VERIFIED", "DISPUTED", "SUPERSEDED"]},
          "status_reason": {"type": "string", "minLength": 1},
          "title": {"type": "string", "minLength": 1},
          "file": {"type": "string", "minLength": 1},
          "line": {"type": "integer", "minimum": 1},
          "trigger": {"type": "string", "minLength": 1},
          "mechanism": {"type": "string", "minLength": 1},
          "consequence": {"type": "string", "minLength": 1},
          "direction": {"type": "string", "minLength": 1},
          "evidence": {"type": "array", "minItems": 1, "items": {"type": "string", "minLength": 1}}
        },
        "allOf": [
          {
            "if": {"properties": {"status": {"enum": ["DISPUTED", "SUPERSEDED"]}}, "required": ["status"]},
            "then": {"required": ["status_reason"]}
          }
        ]
      }
    },
    "coverage_gaps": {"type": "array", "items": {"type": "string"}},
    "scope_drift": {"type": "array", "items": {"type": "string"}}
  }
}
```

## Owning report

Every escalated report emits these machine-readable lines before prose:

```text
Review epoch: <id> | round: <PRIMARY|VERIFY> | patch: sha256:<digest>
Decision: <CLEAN|FINDINGS|BLOCKED|BLOCKED_REVIEW_LOOP>
Finding state: <F-001 OPEN, F-002 VERIFIED, or none>
```

Evidence remains repository paths, command results, tests, or traces. Model
confidence is not evidence.
