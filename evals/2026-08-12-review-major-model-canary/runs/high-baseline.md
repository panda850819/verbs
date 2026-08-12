Panda，發現 3 個可執行問題。

1. **P1 — 引號參數可繞過 ticket gate**
   檔案：[pretooluse-ticket-gate-guard.sh:127](<hooks/pretooluse-ticket-gate-guard.sh:127>)
   觸發：`git -C "/path/to/main-repo" commit` 或 `"/usr/bin/git" commit`。
   機制：第 129 行先刪除所有引號內容，再從刪除後的 segment 找 `git` 與 `-C`。前者把 repo path 變成 `git -C commit`，後者連 executable 都消失。
   後果：實際指向 `main` 的 commit 會被放行；兩個案例均實測回傳 `0`。這比註解承認的「含空格 quoted `-C` path」範圍更大。
   修正方向：以保留 quoted argv 的 shell lexer 解析 executable、subcommand、`-C` 與 refspec；只把確認屬於資料參數的內容排除。加入 quoted `-C`、quoted executable 回歸案例。

2. **P2 — 所有非-main refspec push 都被當成 bare push**
   檔案：[pretooluse-ticket-gate-guard.sh:147](<hooks/pretooluse-ticket-gate-guard.sh:147>)
   觸發：在 `main` 執行 `git push origin HEAD:refs/heads/feature`。
   機制：只要正規式沒看到 `main/master`，第 154–159 行就依目前 branch 套用「bare push」規則，沒有確認命令是否真的沒有 refspec。正規式也會把名為 `main` 的 remote 誤認成目標 branch。
   後果：合法的 feature push 被硬擋；上述命令與 `git push main feat/203-guard` 均實測回傳 `2`。
   修正方向：解析 remote、options 與 refspec；只有完全沒有 refspec 時才套用 bare-push 規則，並只檢查 refspec 的 destination。

3. **P2 — 提示的單次 emergency bypass 無法生效**
   檔案：[pretooluse-ticket-gate-guard.sh:37](<hooks/pretooluse-ticket-gate-guard.sh:37>)
   觸發：`PSTICKET_FORCE=1 git commit -m msg`。
   機制：PreToolUse hook 在 Bash 命令執行前啟動；第 37 行只讀 hook process 的環境，命令前綴尚未被 shell 套用。
   後果：block message 宣告的正常單次 bypass 仍回傳 `2`；只能用設定 host process 環境並重啟等非直覺方式繞過。
   修正方向：支援經嚴格解析的 leading assignment 或明確 trailing override marker；若刻意只支援 host-level environment，錯誤訊息需給出可操作的啟用方式。

驗證範圍：

- 檢查完整 `31b055bfac7664760205000eb57a6fd92984ad3d..14f4cd5fc5ad52e7125fcfc1dd99dfaa93d50fbc` intent 與全部 13 個變更檔。
- 檢查新 guard 的 29 個測試案例、hook manifest、單次解析重構及版本同步。
- `bash -n`、JSON parse、`git diff --check` 通過。
- `python3 scripts/verbs sync --check` 通過：v0.7.1、11 skills、derived files 同步。
- 工作樹保持乾淨。
- 未執行會建立 fixture repo、暫存檔的完整測試套件，以遵守此次非變更性限制。

最高風險且已自我推翻的假設：我懷疑 destructive guard 合併成單次 Python parse 後會改變 fail-open 或危險命令辨識；直接探測確認 non-Bash、malformed、missing/empty command 仍按契約放行並提示，`git reset --hard` 仍回傳 `2`，quoted danger data 仍放行。
