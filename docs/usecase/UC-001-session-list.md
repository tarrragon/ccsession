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

---

## 替代流程

### A1: 新 Session 出現

1. Backend 偵測到新的 JSONL 檔案建立
2. Backend 推送 `session_status_change` 訊息
3. Frontend 動態新增 session 到列表中（Active 群組）

### A2: Session 狀態變更

1. Backend 偵測到某 session 超過閾值無新事件
2. Backend 推送 `session_status_change` 訊息（active → idle 或 idle → completed）
3. Frontend 將該 session 移動到對應的狀態群組

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
```

---

*最後更新: 2026-03-03*
