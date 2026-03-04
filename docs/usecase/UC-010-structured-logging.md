# UC-010: 結構化日誌輸出

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-010 |
| **名稱** | 結構化日誌輸出 |
| **Actor** | System (Go Backend + Flutter Frontend) |
| **優先級** | P0 |
| **元件** | Both |
| **依賴** | 無（橫切關注點，其他所有 UC 依賴本 UC 提供的 log 能力） |

---

## 目標

系統在前後端各層的關鍵執行點輸出結構化 JSON log，
確保所有環節都有可查詢的紀錄，支援除錯與規格變動偵測。

---

## 前置條件

1. 系統啟動時 log 輸出已初始化

---

## Log 等級規範

| 等級 | 使用場景 |
|------|---------|
| `DEBUG` | 正常流程的詳細執行記錄（讀取行數、事件路由、state 更新） |
| `INFO` | 重要里程碑（啟動、session 新增/結束、連線建立） |
| `WARN` | 非預期但可繼續執行（未知欄位、未知事件類型、解析跳過） |
| `ERROR` | 需要關注的失敗（解析錯誤、檔案讀取失敗、連線異常） |

---

## 主要流程：Go Backend

### Go Backend 各層 Log 點

#### File Watcher 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| 偵測到新 session 檔案 | INFO | `filePath`, `sessionID` |
| 讀取新 append 行 | DEBUG | `sessionID`, `offset`, `bytesRead`, `lineCount` |
| 不完整 JSON 行（等待下次讀取） | DEBUG | `sessionID` |
| 檔案讀取失敗 | ERROR | `filePath`, `error` |
| Session 檔案被刪除 | INFO | `sessionID` |

#### JSONL Parser 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| 開始解析一行 | DEBUG | `sessionID`, `lineIndex`, `type` |
| 解析成功 | DEBUG | `sessionID`, `type`, `toolName` (if tool_use) |
| JSON parse 失敗 | ERROR | `sessionID`, `rawLine`, `error` |

#### Session Manager 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| Session 狀態轉換 | INFO | `sessionID`, `from`, `to`, `reason` |
| 新增 session | INFO | `sessionID`, `projectPath` |
| Session 移除 | INFO | `sessionID`, `reason` |

#### WebSocket Server 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| Client 連線建立 | INFO | `clientAddr`, `totalClients` |
| Client 連線斷開 | INFO | `clientAddr`, `reason` |
| 推送事件給 Client | DEBUG | `clientAddr`, `eventType`, `sessionID` |
| 廣播失敗 | ERROR | `clientAddr`, `error` |

---

## 主要流程：Flutter Frontend

### Flutter 各層 Log 點

#### WebSocket Client 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| 連線建立 | INFO | `serverUrl` |
| 連線斷開 | INFO | `reason`, `willRetry`, `retryIn` |
| 收到訊息 | DEBUG | `type`, `dataSize` |
| 解析失敗 | ERROR | `rawMessage`, `error` |

#### Event Mapper 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| 成功映射事件 | DEBUG | `type`, `sessionID` |

#### State Management 層

| 事件 | 等級 | 必填欄位 |
|------|------|---------|
| Session 列表更新 | DEBUG | `sessionCount`, `activeCount` |
| Session 狀態變更 | INFO | `sessionID`, `from`, `to` |
| UI 狀態不一致 | WARN | `sessionID`, `detail` |

---

## Log 輸出格式

兩端均採用結構化 JSON log：

```json
{
  "level": "INFO",
  "time": "2026-03-05T10:00:00Z",
  "layer": "file_watcher",
  "msg": "new session file detected",
  "filePath": "~/.claude/projects/-Users-tarragon/abc-123.jsonl",
  "sessionID": "abc-123"
}
```

**Go**：`log/slog`（標準庫，Go 1.21+），輸出到 stderr
**Flutter**：`package:logging`，Release 模式只輸出 INFO 以上

---

## 替代流程

### A1: Release 模式 Log 輸出降級

1. Flutter 在 release build 時關閉 DEBUG log
2. 仍輸出 INFO / WARN / ERROR
3. 確保關鍵問題在 production 仍可見

---

## 例外流程

### E1: Log 輸出失敗

1. stderr 無法寫入（極少見）
2. 主要業務流程繼續執行
3. Log 失敗不影響系統功能

---

## 驗收條件

- [ ] Go Backend 啟動時 log 初始化完成，level 可由 CLI flag 或環境變數設定
- [ ] Flutter 啟動時 log 初始化完成，release 模式自動降級為 INFO 以上
- [ ] File Watcher 層：偵測到新檔案時輸出 INFO log
- [ ] File Watcher 層：每次讀取新行時輸出 DEBUG log（含 offset）
- [ ] JSONL Parser 層：解析失敗時輸出 ERROR log（含 rawLine）
- [ ] Session Manager 層：每次狀態轉換輸出 INFO log（含 from/to）
- [ ] WS Server 層：Client 連線/斷線輸出 INFO log
- [ ] Flutter WS Client：連線/斷線輸出 INFO log
- [ ] Flutter Event Mapper：收到訊息時輸出 DEBUG log
- [ ] 所有 log 為結構化 JSON 格式
- [ ] Log 不包含使用者對話內容（避免敏感資料外洩）

---

*最後更新: 2026-03-05*
