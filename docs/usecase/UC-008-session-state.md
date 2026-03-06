# UC-008: Session 狀態管理

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-008 |
| **名稱** | Session 狀態管理 |
| **Actor** | System (Go Backend) |
| **優先級** | P0 |
| **元件** | Go Backend |
| **依賴** | UC-006 (File Watching), UC-007 (Parsing) |

---

## 目標

維護一個 in-memory 的 Session Registry，追蹤所有 session 的 metadata 和生命週期狀態，
為前端提供即時的 session 概覽資訊。

---

## 前置條件

1. Go Backend 已啟動
2. `~/.claude/projects/` 目錄可存取

---

## 主要流程（Happy Path）

### 8.1 初始化

1. Backend 啟動時掃描所有 project 目錄
2. 讀取每個 project 的 `sessions-index.json`
3. 為每個 session 建立 SessionInfo 記錄
4. 讀取 `history.jsonl` 建立 session → project 映射
5. 根據最後事件時間設定初始狀態

### 8.2 狀態更新

1. 收到新的 SessionEvent
2. 更新對應 session 的 lastEventAt 和 eventCount
3. 重新評估狀態：
   - 有新事件 → `active`
   - 超過 idle_timeout（預設 2 分鐘）→ `idle`
   - 超過 completed_timeout（預設 30 分鐘）→ `completed`
4. 若狀態發生變更，通知 WebSocket 層推送 `session_status_change`

### 8.3 新 Session 註冊

1. UC-006 偵測到新 JSONL 檔案
2. 從檔名提取 session UUID
3. 從所在目錄反推 project path
4. 建立新的 SessionInfo（狀態為 active）
5. 通知 WebSocket 層推送列表更新

---

## 替代流程

### A1: sessions-index.json 不存在

1. 某 project 目錄下沒有 sessions-index.json
2. 從 JSONL 檔名推斷 session ID
3. 摘要使用 session JSONL 檔案中第一個 type 為 `user` 的 message 文字（截取前 100 字元）
4. Git branch 標記為未知
5. 使用備用來源填補缺失欄位，確保 session 基本資訊可用

### A2: 定期狀態掃描

1. 每 30 秒執行一次全量狀態檢查
2. 將超時的 active session 降級為 idle
3. 將超時的 idle session 降級為 completed

---

## 狀態機

```
                 新事件
  +------->  [active] <---------+
  |              |              |
  |    2 min     |    新事件     |
  |   no event   |              |
  |              v              |
  |          [idle]             |
  |              |              |
  |   30 min     |              |
  |   no event   |              |
  |              v              |
  +------- [completed] --------+
```

---

## Session Metadata 來源優先級

| 欄位 | 優先來源 | 備用來源 | 最終 Fallback |
|------|---------|---------|--------------|
| sessionId | JSONL 檔名解碼 | - | - |
| projectPath | 目錄結構反推 | sessions-index.json | 編碼目錄名 |
| summary | sessions-index.json `summary` | session JSONL 第一個 user prompt（前 100 字元） | "(unnamed session)" |
| gitBranch | sessions-index.json `gitBranch` | - | "(unknown)" |
| lastEventAt | 最新 JSONL 事件 timestamp | 檔案修改時間 | 檔案建立時間 |
| eventCount | session JSONL 成功解析事件數 | sessions-index.json 記錄 | 0 |
| status | 狀態機計算（基於 timeout） | - | - |

### 優先級邏輯說明

- **Summary**（canonical 定義，UC-001 等前端 UC 應引用本定義）：優先從 sessions-index.json 讀取。若無，則解析該 session 的 JSONL 檔案（`[session-uuid].jsonl`）中第一個 type 為 `user` 的 message，截取前 100 字元作為摘要。若檔案為空或不存在，顯示預設值 "(unnamed session)"。注意：此處的來源是 per-session JSONL 檔案，而非全域的 `history.jsonl`（後者僅用於 session-to-project 映射）。
- **Git Branch**：僅來自 sessions-index.json。若無，顯示 "(unknown)"，而非空值。
- **Project Path**：優先通過目錄編碼反推。若編碼不存在或破損，可從 sessions-index.json 補救。
- **Last Active**：以 JSONL 最後事件的 timestamp 為準（最精確）。若 JSONL 為空，使用檔案修改時間。
- **Event Count**：計算 session JSONL 檔案中**成功解析為合法 JSON 物件的事件行數**，而非原始行數。空行、格式錯誤行不計入。此值動態計算，避免依賴 sessions-index.json 的過時記錄。

---

## 驗收條件

- [ ] 啟動時正確載入所有既有 session 的 metadata
- [ ] 新 session 建立時自動註冊
- [ ] 狀態自動從 active → idle → completed 轉換
- [ ] 新事件能讓 completed session 回到 active
- [ ] sessions-index.json 缺失時優雅降級，備用來源填補缺失欄位
- [ ] 狀態變更時推送通知
- [ ] 並發安全（多個 goroutine 同時存取 registry）

---

*最後更新: 2026-03-05*
