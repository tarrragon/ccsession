# UC-001: Session 列表瀏覽

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-001 |
| **名稱** | Session 列表瀏覽 |
| **Actor** | Developer |
| **優先級** | P0 |
| **元件** | Flutter Frontend |
| **依賴** | UC-008 (Session State), UC-009 (WebSocket) |

---

## 目標

Developer 開啟應用程式後，能在 sidebar 看到所有 Claude Code session，
按狀態（Active / Idle / Completed）分組顯示，快速掌握所有 agent 的運行狀況。

---

## 前置條件

1. Go Backend 已啟動且 WebSocket server 正在監聽
2. Flutter Frontend 已成功建立 WebSocket 連線
3. `~/.claude/projects/` 目錄下存在至少一個 session JSONL 檔案

---

## 主要流程（Happy Path）

1. Developer 開啟應用程式
2. Frontend 自動連線到 Backend WebSocket server
3. Backend 推送 `session_list` 訊息，包含所有 session 的 metadata
4. Frontend 在 sidebar 渲染 session 列表，按狀態分組
5. 每個 session 項目顯示：
   - 摘要文字（來自 sessions-index.json 或第一個 user prompt）
   - 專案名稱（project path 最後一段）
   - Git branch（如有）
   - 最後活動時間（相對時間格式）
   - 狀態指示燈（綠/黃/灰）
6. Developer 點擊某個 session → 觸發 UC-002

### 摘要顯示邏輯

Session 摘要顯示遵循 UC-008 定義的元資料來源優先級：
- 優先來源：sessions-index.json 的 `summary` 欄位
- 備用來源：該 session 的 JSONL 檔案中第一個 user prompt（截取前 100 字元）
- 最終 Fallback：無有效摘要時顯示 "(unnamed session)"

若 sessions-index.json 無 `summary` 欄位，Frontend 應顯示第一個 user prompt 的前 100 字元，提供有意義的 session 識別。此處「第一個 user prompt」來自該 session 對應的 JSONL 對話紀錄檔，由 Backend 解析後透過 metadata 提供（詳見 UC-008 Session Metadata 來源優先級）。

---

## 替代流程

### A1: 新 Session 出現

1. Backend 偵測到新的 JSONL 檔案建立
2. Backend 推送 `session_status_change` 訊息
3. Frontend 動態新增 session 到列表中（Active 群組）

### A2: Session 狀態降級（active → idle → completed）

1. Backend 偵測到某 session 超過閾值無新事件
2. Backend 推送 `session_status_change` 訊息（active → idle 或 idle → completed）
3. Frontend 將該 session 從原群組移除，以動畫過渡插入到目標狀態群組
4. 動畫建議：使用 slide + fade 過渡（約 300ms），讓使用者能追蹤 session 的位置變化

### A4: Session 從 completed 回到 active（狀態回升）

1. Backend 偵測到已 completed 的 session 出現新事件（使用者重新開啟對話）
2. Backend 推送 `session_status_change` 訊息（completed → active）
3. Frontend 將該 session 從 Completed 群組移除，以動畫過渡插入到 Active 群組頂部
4. 建議以視覺強調（如短暫高亮 1 秒）標示該 session 剛回到 active，幫助使用者注意到變化
5. 同理適用於 idle → active 的回升情境

### A3: 無任何 Session

1. Backend 推送空的 `session_list`
2. Frontend 顯示空狀態提示：「目前沒有 Claude Code session」

---

## 例外流程

### E1: WebSocket 連線失敗

1. Frontend 顯示連線狀態為「已斷線」
2. 啟動重連機制（詳見 UC-009）
3. Session 列表顯示最後已知狀態（如有快取）或空狀態

---

## 驗收條件

- [ ] 應用程式啟動後 3 秒內顯示 session 列表
- [ ] Session 按 Active / Idle / Completed 正確分組
- [ ] 每個 session 項目顯示完整的 metadata 資訊
- [ ] 新 session 出現時列表即時更新
- [ ] Session 狀態變更時自動移動到正確群組
- [ ] 無 session 時顯示友善的空狀態提示
- [ ] 無摘要時正確顯示第一個 user prompt 或 "(unnamed session)"

---

## 列表動畫規範

Session 列表在狀態變更時應提供視覺過渡，幫助使用者追蹤 session 位置變化。

| 事件 | 動畫類型 | 時長 | 說明 |
|------|---------|------|------|
| 新 Session 加入 | fade-in + slide-down | 300ms | 新項目從 Active 群組頂部滑入 |
| 狀態降級（active→idle, idle→completed） | slide + fade 過渡 | 300ms | 從原群組移除，插入目標群組 |
| 狀態回升（completed→active, idle→active） | slide + fade 過渡 + 短暫高亮 | 300ms 過渡 + 1000ms 高亮 | 插入 Active 群組頂部，高亮提示使用者注意 |
| Session 移除（JSONL 檔案刪除） | fade-out + slide-up | 200ms | 項目從列表中淡出 |

**設計原則**：
- 動畫應輔助使用者感知變化，不應造成視覺干擾
- 當短時間內發生多次狀態變更（如批量 session 到期），應合併動畫避免列表頻繁跳動
- 動畫期間使用者仍可點擊其他 session（不阻擋互動）

---

## UI 草圖

```
+-- Session List --------+
|                         |
| [Active] (2)            |
|  > [G] my-project       |
|    feat/auth - 30s ago  |
|  > [G] api-server       |
|    main - 1m ago        |
|                         |
| [Idle] (1)              |
|  > [Y] docs-site        |
|    main - 15m ago       |
|                         |
| [Completed] (3)         |
|  > [X] cli-tool         |
|    main - 2h ago        |
|  ...                    |
+-------------------------+

[G] = 綠色指示燈
[Y] = 黃色指示燈
[X] = 灰色指示燈

若無摘要：在摘要位置顯示第一個 user prompt 的前 100 字元
```

---

*最後更新: 2026-03-05 (W1-009: 補充 H3 狀態回升 + M11 摘要來源統一 + L1 列表動畫)*
