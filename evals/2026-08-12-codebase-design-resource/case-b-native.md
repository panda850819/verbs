Use one injected, synchronous feature-flag service. The seam belongs at handler construction; `process.env` must not cross it.

```ts
export type FlagKey =
  | "newCheckout"
  | "recommendations"
  | "anotherFlag";

export interface FlagContext {
  /** Stable, non-secret identifier used for percentage rollout bucketing. */
  subjectId?: string;
}

export interface FeatureFlags {
  isEnabled(flag: FlagKey, context?: FlagContext): boolean;
}
```

Composition root:

```ts
const flags = createEnvironmentFeatureFlags({
  environment: process.env,
});

const handler = createCheckoutHandler({ flags });
```

Handler:

```ts
export function createCheckoutHandler(
  dependencies: { flags: FeatureFlags },
) {
  return async function handle(request: Request) {
    const enabled = dependencies.flags.isEnabled("newCheckout", {
      subjectId: request.user.id,
    });

    // Business behavior only.
  };
}
```

Keep flag definitions private to the environment implementation:

```ts
const definitions = {
  newCheckout: {
    environmentVariable: "FLAG_NEW_CHECKOUT",
    fallback: false,
    bucketSalt: "new-checkout-v1",
  },
  recommendations: {
    environmentVariable: "FLAG_RECOMMENDATIONS",
    fallback: true,
    bucketSalt: "recommendations-v1",
  },
} satisfies FlagDefinitions;
```

The environment-backed implementation owns:

- Reading or snapshotting environment values.
- Boolean normalization such as `true`, `false`, `1`, `0`, `on`, and `off`.
- Percentage parsing and range validation.
- Deterministic bucketing from `flag + salt + subjectId`.
- Behavior when a percentage flag has no `subjectId`.
- Missing and malformed-value fallbacks.
- Optional diagnostics for invalid configuration.
- Keeping the hashing algorithm stable so deployments do not reshuffle users.

Callers know only:

- The semantic flag key.
- Whether a stable subject identifier is available.
- The business behavior selected by the resulting boolean.

Callers do not know environment-variable names, accepted syntax, percentages, hashing, fallback values, or provider failure behavior.

Test surface:

```ts
const flags = createEnvironmentFeatureFlags({
  environment: {
    FLAG_NEW_CHECKOUT: "25%",
  },
});
```

Unit-test the implementation with injected plain objects—never patched process state:

- Every supported boolean spelling.
- `0%`, `100%`, and representative intermediate percentages.
- Stable results for the same subject.
- Expected boundary buckets using fixed hash fixtures.
- Different flag salts preventing correlated rollouts.
- Missing, empty, malformed, negative, and over-100 values.
- Percentage values without a subject identifier.
- Configured fallback behavior.

Test handlers with a tiny fake:

```ts
const flags: FeatureFlags = {
  isEnabled: flag => flag === "newCheckout",
};
```

Also run the environment implementation through a provider-neutral contract suite. A future implementation must satisfy the same observable semantics, particularly fallback and stable bucketing.

Abstraction verdict: introduce the narrow `FeatureFlags` seam and the environment-backed implementation now because six handlers already justify consolidation. Do not introduce a generic provider framework or speculative remote adapter. If a remote provider is approved later, implement this interface using locally cached evaluations; only make the interface asynchronous if the committed provider genuinely requires request-time I/O.
