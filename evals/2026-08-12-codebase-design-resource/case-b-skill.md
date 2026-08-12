Panda，我會把 **seam** 放在六個 handlers 與旗標判定之間，建立一個具體的 `Flags` **module**；目前不建立 provider **adapter**。

```ts
type FlagName = /* six known flags */
type FlagSubject = { key: string }

class Flags {
  static fromEnvironment(
    env: Readonly<Record<string, string | undefined>>
  ): Flags

  isEnabled(flag: FlagName, subject: FlagSubject): boolean
}
```

### Interface

呼叫者只需知道：

- `flag` 必須是已宣告的 `FlagName`。
- `subject.key` 必須非空且長期穩定；百分比分流會對同一組 `flag + key` 產生確定結果。
- `isEnabled` 回傳 boolean，不改動輸入，也不直接讀取 process state。
- 設定在建立 `Flags` 時擷取；同一 instance 的結果不會因後續環境變動而改變。
- 缺少或格式錯誤的設定不會拋錯，而是套用該旗標已宣告的 fallback。各旗標的 fallback 是 **interface** 的可觀察行為，不由 handlers 臨時指定。
- 單次判定應是固定成本，不進行 I/O。

### Implementation

留在 module 裡的內容：

- 環境變數名稱與查找方式。
- boolean、百分比及其合法格式。
- 正規化、驗證與錯誤處理。
- bucketing 演算法及 hash 細節。
- 每個旗標的 fallback 規則。
- 判定所需的內部資料結構。

這使 module 具有足夠 **depth**：六個 handlers 學會一個小 **interface**，卻取得解析、驗證、bucketing 與 fallback 的完整行為。其 **leverage** 是所有呼叫點及測試共用一次 implementation；其 **locality** 是規則變更、缺陷與驗證集中在同一處。若刪除 module，這些複雜度會重新散落到六個 handlers，因此它不是 pass-through。

### Test surface

測試透過同一個 **seam** 呼叫 `isEnabled`：

- 用普通 immutable map 建立 `Flags`，不 patch `process.env`。
- 表格化測試 true/false 變體、百分比端點、無效值、缺值與 fallback。
- 驗證相同 subject 的結果穩定，以及不同 subject 的分布。
- handler 測試也注入以小型設定建立的真實 `Flags`；不需要碰 process state，也不需要測到 **interface** 後面。

解析與 bucketing 可以有 implementation-private 的內部 seams，但不暴露給 handlers。

### Adapter 決定

現在不要建立 `FlagProvider` 或 remote-provider **adapter**。目前只有環境來源；尚未承諾的遠端來源不足以證明變化真的存在。一個 adapter 只會形成 hypothetical seam。

等遠端 provider 確定後，再依它真正的語義決定 seam：若它直接做使用者判定，就讓 environment 與 remote 兩個 adapters 滿足旗標判定 interface；若它只供應設定，則把 provider seam 放在設定載入處。現階段先凍結 handlers 面向的 `Flags.isEnabled` seam。
