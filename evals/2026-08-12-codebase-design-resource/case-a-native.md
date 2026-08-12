## Concrete interface

Callers submit a typed job, not queue-provider options:

```ts
type JobName = keyof JobPayloads;

interface JobPayloads {
  "email.send": { messageId: string };
  "invoice.generate": { invoiceId: string };
}

interface JobClient {
  enqueue<N extends JobName>(
    name: N,
    payload: JobPayloads[N],
    context?: {
      idempotencyKey?: string;
      correlationId?: string;
    },
  ): Promise<{ jobId: string }>;
}
```

Job-specific infrastructure policy lives in one catalog:

```ts
const jobDefinitions = {
  "email.send": {
    queue: "outbound",
    codec: emailCodec,
    timeoutMs: 5_000,
    retry: { maxAttempts: 4, backoff: exponential(200, 5_000) },
  },
  "invoice.generate": {
    queue: "documents",
    codec: invoiceCodec,
    timeoutMs: 30_000,
    retry: { maxAttempts: 2, backoff: fixed(1_000) },
  },
} satisfies JobDefinitions;
```

The provider seam is deliberately narrow:

```ts
interface QueueTransport {
  publish(request: {
    queue: string;
    body: Uint8Array;
    idempotencyKey?: string;
    correlationId?: string;
  }): Promise<{ providerJobId: string }>;
}
```

The module depends on explicit time seams:

```ts
interface Clock {
  now(): number;
}

interface Sleeper {
  sleep(ms: number): Promise<void>;
}
```

If backoff uses jitter, inject a `Random` interface too. Do not hide nondeterminism behind global timers or `Math.random()`.

## What callers know

Callers know:

- The job name and typed business payload.
- Optional business-level idempotency and correlation identifiers.
- Whether enqueueing succeeded or failed with a stable module error.

Callers do not know:

- Queue names.
- Serialization formats.
- Provider SDK types or error codes.
- Timeout implementation.
- Retry count, backoff, or jitter.
- Metric names and labels.

Avoid an `enqueue(payload, { queue, retries, serializer, ... })` escape hatch; that would preserve all 14 duplications behind a new function name.

## What stays inside

`JobClient` owns:

- Looking up the job definition.
- Payload validation and serialization.
- Queue selection.
- Per-attempt timeout enforcement.
- Provider error translation into a small taxonomy such as:
  - `Unavailable`
  - `TimedOut`
  - `RateLimited`
  - `Rejected`
  - `Misconfigured`
- Retry eligibility and backoff.
- Attempt and terminal-outcome metrics.
- Stable logging fields and correlation propagation.
- Returning one final domain-facing error after retries are exhausted.

The provider adapter owns only SDK mechanics and provider-specific error classification. Retry policy belongs to `JobClient`, where job policy and deterministic time are available.

## Test surface

Use three layers:

1. Pure policy tests

   Test job lookup, codecs, error classification, retry eligibility, and backoff calculations as ordinary functions.

2. `JobClient` contract tests with fakes

   Supply a scripted `QueueTransport`, fake clock/sleeper, and metric recorder. Verify exact behavior:

   - First-attempt success.
   - Timeout at the configured boundary.
   - Retryable failure followed by success.
   - Non-retryable failure with no retry.
   - Retry exhaustion.
   - Exact backoff sequence.
   - Queue and serialized bytes selected from the catalog.
   - One attempt metric per attempt and one terminal metric.
   - No real sleeping or wall-clock dependence.

3. Thin provider-adapter integration tests

   Verify request mapping and representative provider-error translation. Do not repeat the retry suite against the real provider.

Define timeout semantics precisely—for example, “each attempt gets `timeoutMs`; backoff does not consume that attempt’s budget”—so tests do not encode an accidental interpretation.

## Abstraction verdict

The abstraction earns its keep now, even with one provider. Its justification is not hypothetical provider swapping; it removes five infrastructure responsibilities from 14 callers and creates the deterministic timeout/retry seam the tests require.

Keep it as one opinionated job module plus a narrow transport port. Do not build a general queue framework, expose arbitrary policies per call, or design for unknown providers until a second concrete provider forces that extension.
