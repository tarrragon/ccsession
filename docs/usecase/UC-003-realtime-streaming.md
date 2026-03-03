# UC-003: 即時事件串流

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-003 |
| **名稱** | 即時事件串流 |
| **Actor** | Developer |
| **優先級** | P0 |
| **元件** | Go Backend + Flutter Frontend |
| **依賴** | UC-006 (File Watching), UC-007 (Parsing), UC-009 (WebSocket) |

---

## 目標

當 Claude Code agent 正在執行時，Developer 能在監控介面即時看到新的對話事件出現，
延遲不超過 1 秒，實現接近即時的監控體驗。

---

## 前置條件

1. Developer 正在檢視一個 active session（UC-002）
2. 該 session 對應的 Claude Code agent 正在運行並產生新事件
3. WebSocket 連線正常

---

## 主要流程（Happy Path）

1. Claude Code agent 產生新的對話事件
2. 事件以 JSON 行 append 到 session 的 JSONL 檔案
3. Go Backend 的 file watcher 偵測到檔案變更（UC-006）
4. Backend 讀取新 append 的行，解析為 SessionEvent（UC-007）
5. Backend 透過 WebSocket 推送 `session_event` 給已訂閱的 Client
6. Frontend 接收事件，渲染到對話檢視底部
7. 觸發自動捲動邏輯（見 UC-002 A2）

---

## 替代流程

### A1: 短時間內大量事件（Burst）

1. Agent 快速連續產生多個事件（如連續 tool calls）
2. Backend 逐一推送或批次推送（由實作決定）
3. Frontend 依序渲染，不遺漏任何事件

### A2: Developer 未訂閱該 Session

1. 事件仍由 Backend 處理和儲存
2. 不推送給未訂閱的 Client
3. Developer 之後切換到該 session 時可透過 `get_session_history` 取得完整歷史

---

## 例外流程

### E1: 檔案寫入中途讀取

1. JSONL 行尚未完整寫入
2. JSON parse 失敗
3. Backend 忽略不完整行，下次變更時重試
4. 不影響已成功解析的事件

---

## 效能需求

| 指標 | 目標值 |
|------|--------|
| 端到端延遲（寫入到 UI 顯示） | < 1 秒 |
| 事件吞吐量 | >= 100 events/sec |
| 記憶體使用（每 session） | < 10 MB |

---

## 驗收條件

- [ ] 新事件從 JSONL 寫入到 UI 顯示延遲 < 1 秒
- [ ] 連續快速事件不遺漏
- [ ] 不完整的 JSON 行不導致錯誤
- [ ] 未訂閱的 session 事件不佔用 Client 頻寬
- [ ] 長時間運行（1 小時以上）無記憶體洩漏

---

*最後更新: 2026-03-03*
