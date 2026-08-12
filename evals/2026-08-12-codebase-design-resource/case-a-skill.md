Panda，我會設計成一個深模組，讓 14 個呼叫端只跨越同一個 seam：

```ts
type Job =
  | { kind: "send-email"; payload: SendEmailPayload; idempotencyKey: string }
  | { kind: "rebuild-index"; payload: RebuildIndexPayload; idempotencyKey: string };

type SubmitResult =
  | { ok: true; jobId: string }
  | { ok: false; reason: "invalid-job" | "unavailable" | "timed-out" };

interface JobRunner {
  submit(job: Job): Promise<SubmitResult>;
}
```

呼叫端只需要知道：

- 合法的 `Job` 種類及其 payload。
- `idempotencyKey` 的不變條件。
- `submit` 回傳的三種穩定錯誤模式。
- 呼叫可能等待至設定好的提交 timeout。
- 成功代表 provider 已接受工作，不代表工作已完成。

以下全部留在 implementation：

- 根據 job kind 選 queue。
- Payload serialization 與 schema/version metadata。
- Retry 次數、可重試錯誤分類、backoff 與 jitter。
- Provider error translation。
- Timeout enforcement。
- Metrics、attempt tags 與 latency measurement。
- Provider-specific identifiers、設定與例外。

正式 implementation 接受依賴，不自行建立：

```ts
createJobRunner({
  queue: productionQueueAdapter,
  clock,
  sleeper,
  metrics,
  policy,
});
```

`queue` 是內部 seam，不是 14 個呼叫端的 interface。正式 queue adapter 與 scripted test adapter 提供了兩個實際 adapter；`clock` 和 `sleeper` 也可用 deterministic adapter。這使 timeout 與 retry 可以改變，而不必編輯 `JobRunner` 的行為測試。

測試仍透過外部 interface 呼叫 `submit`：

- Script queue adapter 依序回傳 transient error、transient error、success。
- Deterministic clock/sleeper 立即推進時間並記錄 backoff。
- 從 `SubmitResult` 驗證錯誤翻譯與 timeout。
- 從 adapter 記錄驗證嘗試次數、queue、serialization 和 metrics。
- 不直接呼叫 retry、serialization 或 error-mapping helper；那些不是 test surface。

這個抽象有足夠 depth，也通過 deletion test：若刪除它，queue selection、serialization、retry/backoff、錯誤翻譯和 metrics 會重新散落到 14 個呼叫端。小 interface 隱藏大量共同行為，為呼叫端提供 leverage，也讓變更、錯誤與驗證集中，形成 locality。
