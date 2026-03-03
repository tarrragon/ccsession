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
3. 摘要使用第一個 user message 的文字
4. Git branch 標記為未知

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

## Session Metadata 來源

| 欄位 | 主要來源 | 備用來源 |
|------|---------|---------|
| sessionId | JSONL 檔名 | - |
| projectPath | 目錄路徑解碼 | history.jsonl |
| summary | sessions-index.json | 第一個 user prompt |
| gitBranch | sessions-index.json | 無 |
| lastEventAt | 最新事件 timestamp | 檔案修改時間 |
| eventCount | 累計計數 | JSONL 行數 |
| status | 狀態機計算 | - |

---

## 驗收條件

- [ ] 啟動時正確載入所有既有 session 的 metadata
- [ ] 新 session 建立時自動註冊
- [ ] 狀態自動從 active → idle → completed 轉換
- [ ] 新事件能讓 completed session 回到 active
- [ ] sessions-index.json 缺失時優雅降級
- [ ] 狀態變更時推送通知
- [ ] 並發安全（多個 goroutine 同時存取 registry）

---

*最後更新: 2026-03-03*
