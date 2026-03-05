# Claude Code Multi-Agent Session Monitor - 技術規格

## 1. 專案概述

### 1.1 問題定義

在 CLI 環境下同時運行多個 Claude Code agent/subagent 時，缺乏統一的即時監控介面。
開發者無法同時觀察所有 session 的進度與對話內容，導致多 agent 協作時的可觀測性不足。

### 1.2 解決方案

建立一個跨平台的即時監控系統，透過監控 Claude Code 的本地 JSONL 對話記錄檔案，
提供即時的多 session 並列檢視功能。

### 1.3 技術架構

```
+-------------------+       WebSocket        +--------------------+
|   Go Backend      | <--------------------> |  Flutter Frontend   |
|                   |                         |                    |
|  - File Watcher   |   session_list          |  - Session List    |
|  - JSONL Parser   |   session_event         |  - Chat View       |
|  - Session Mgr    |   session_history       |  - Split View      |
|  - WS Server      |                         |  - WS Client       |
+-------------------+                         +--------------------+
        |
        | fsnotify
        v
+-------------------+
|  ~/.claude/       |
|  projects/        |
|    *.jsonl        |
+-------------------+
```

---

## 2. 資料來源：Claude Code JSONL 格式

### 2.1 目錄結構

```
~/.claude/
├── history.jsonl                          # 全域索引
├── projects/
│   └── [encoded-directory-path]/          # 專案路徑（/ 替換為 -）
│       ├── [session-uuid].jsonl           # 完整對話歷史
│       ├── [summary-uuid].jsonl           # 對話摘要
│       └── sessions-index.json           # Session metadata
```

### 2.2 路徑編碼規則

專案絕對路徑中的 `/` 替換為 `-`：

| 專案路徑 | 編碼後目錄名 |
|---------|------------|
| `/home/user/my-project` | `-home-user-my-project` |
| `/Users/tarragon/Projects/ccsession` | `-Users-tarragon-Projects-ccsession` |

### 2.3 時間戳格式定義

本系統所有時間戳統一使用 **ISO 8601 格式（UTC，毫秒精度）**：

```
格式：YYYY-MM-DDTHH:mm:ss.sssZ
範例：2026-03-05T10:30:45.937Z
```

| 使用位置 | 格式 | 說明 |
|---------|------|------|
| JSONL 來源 `timestamp` 欄位 | ISO 8601 UTC（毫秒） | Claude Code 原生格式，直接沿用 |
| WebSocket 協議所有時間欄位 | ISO 8601 UTC（毫秒） | 包含 session_event、session_history、session_list 中的時間 |
| Go Backend 內部 | `time.Time` | 解析 ISO 8601 字串為 Go 原生型別 |
| Flutter Frontend | `DateTime.parse()` | 解析 ISO 8601 字串為 Dart DateTime |
| `get_session_history` 的 `before` 參數 | ISO 8601 UTC（毫秒） | 用於 timestamp-based cursor 分頁 |

**選擇 ISO 8601 而非 Unix 毫秒的理由**：Claude Code JSONL 原生使用 ISO 8601 格式，沿用可避免轉換成本和精度損失，且人類可讀性更佳，便於除錯。

### 2.4 JSONL 事件結構

每行一個 JSON 物件，基本結構：

```json
{
  "type": "user|assistant",
  "message": {
    "role": "user|assistant",
    "content": "string | array"
  },
  "timestamp": "2025-06-02T18:46:59.937Z"
}
```

#### 頂層事件類型

| type | 說明 | message.content 格式 |
|------|------|---------------------|
| `user` | 使用者訊息 | string（純文字） |
| `assistant` | 助手回應 | content array（見下表） |
| `tool_result` | 工具執行結果 | content array，元素含 `tool_use_id` + `type: "tool_result"` |

> 注意：JSONL 中還存在 `progress`、`queue-operation`、`file-history-snapshot` 等輔助類型，
> 這些類型不包含對話內容，Backend 解析時應忽略。

#### JSONL 頂層常見欄位

每個 JSONL 行除了 `type` 和 `message` 之外，還包含以下常見欄位：

| 欄位 | 說明 | 範例 |
|------|------|------|
| `uuid` | 該行的唯一識別符 | `"3809ab6c-f022-4e5b-87bb-a2c8bab2d5db"` |
| `sessionId` | 所屬 session UUID | `"f635f2ad-9e19-4fca-ba65-4f836ab7b737"` |
| `timestamp` | ISO 8601 UTC 毫秒時間戳 | `"2026-03-05T04:44:24.361Z"` |
| `parentUuid` | 父訊息 UUID（對話樹結構） | `"0adb42a3-..."` 或 `null` |
| `version` | Claude Code 版本號 | `"2.1.69"` |
| `gitBranch` | 當前 Git 分支 | `"feat/my-feature"` |
| `cwd` | 當前工作目錄 | `"/Users/user/project"` |

#### Assistant content array 元素類型

| type | 說明 | 關鍵欄位 |
|------|------|---------|
| `text` | 文字回應 | `text`（string） |
| `tool_use` | 工具呼叫 | `id`（工具呼叫 ID）, `name`（工具名稱）, `input`（參數 object） |
| `thinking` | 思考過程 | `thinking`（string） |

### 2.5 sessions-index.json 結構

```json
{
  "sessions": [
    {
      "sessionId": "uuid",
      "summary": "session description",
      "messageCount": 42,
      "gitBranch": "feat/my-feature",
      "projectPath": "/Users/tarragon/Projects/ccsession",
      "lastActiveAt": "2025-06-02T18:46:59.937Z"
    }
  ]
}
```

### 2.6 history.jsonl 結構

每行包含：

```json
{
  "prompt": "user prompt text",
  "timestamp": "2025-06-02T18:46:59.937Z",
  "projectPath": "/path/to/project",
  "sessionId": "uuid"
}
```

---

## 3. Go Backend 規格

### 3.1 檔案監控層

#### 職責

- 使用 `fsnotify` 監控 `~/.claude/projects/` 目錄下所有 `.jsonl` 檔案變更
- 每個被監控的 session file 用一個 goroutine 處理
- 記錄已讀取的 offset，只讀取新 append 的行
- 支援動態偵測新建立的 session 檔案

#### 關鍵設計

```go
type FileWatcher struct {
    claudeHome    string
    watchers      map[string]*SessionFileReader  // path -> reader
    eventCh       chan SessionEvent              // 統一事件通道
}

type SessionFileReader struct {
    filePath   string
    offset     int64      // 已讀取位置
    sessionID  string
}
```

#### 容錯處理

| 情境 | 處理方式 |
|------|---------|
| 不完整的 JSON 行 | 忽略，等下次讀取完整行 |
| 檔案被刪除 | 移除 watcher，標記 session 為 completed |
| 權限不足 | 記錄警告，跳過該檔案 |

### 3.2 JSONL 解析層

#### 職責

- 逐行 parse JSON，提取關鍵欄位
- 對 assistant response 中的 content array 做分類處理
- 轉換為統一的內部事件格式

#### 內部事件格式

```go
type SessionEvent struct {
    SessionID     string          `json:"sessionId"`
    ProjectPath   string          `json:"projectPath"`
    Type          string          `json:"type"`         // user, assistant, tool_use, tool_result, thinking
    Timestamp     time.Time       `json:"timestamp"`
    MessageID     string          `json:"messageId"`    // JSONL 行的 uuid，用於去重和排序
    ContentIndex  int             `json:"contentIndex"` // 在 assistant content array 中的索引（非 assistant 類型為 -1）
    IsLastContent bool            `json:"isLastContent"` // 是否為該 messageId 下的最後一個子事件
    Content       EventContent    `json:"content"`
    ToolName      string          `json:"toolName,omitempty"`
}
```

#### EventContent 定義

SessionEvent.Content 的結構依 Type 而異：

| Type | Content 結構 | 欄位說明 |
|------|-------------|---------|
| `user` | `{ "text": string }` | `text`: 使用者輸入的完整文字 |
| `assistant` | `{ "text": string }` | `text`: 助手的文字回應內容 |
| `tool_use` | `{ "toolName": string, "toolInput": object, "toolUseId": string }` | `toolName`: 工具名稱（如 "Read", "Bash"）；`toolInput`: 工具呼叫參數（原始 JSON）；`toolUseId`: 工具呼叫的唯一識別符，用於與 tool_result 配對 |
| `tool_result` | `{ "toolUseId": string, "output": string, "isError": bool }` | `toolUseId`: 對應 tool_use 的 ID；`output`: 工具執行結果文字；`isError`: 是否為錯誤結果 |
| `thinking` | `{ "text": string }` | `text`: 模型的思考過程文字 |

**ContentIndex 說明**：一個 assistant JSONL 行的 `message.content` 陣列可能包含多個元素（例如先 text 再 tool_use）。Backend 將陣列展開為多個 SessionEvent 時，`contentIndex` 記錄該元素在原始陣列中的位置（0-based）。非 assistant 類型（user、tool_result）的 `contentIndex` 固定為 -1。

**MessageID 說明**：對應 JSONL 行的 `uuid` 欄位。用於：(1) 事件去重（同一 JSONL 行展開的多個 SessionEvent 共享同一 messageId）；(2) 配合 contentIndex 可精確定位原始資料。

**IsLastContent 說明**：當一個 assistant JSONL 行的 `message.content` 陣列包含多個元素時，Backend 會為每個元素產生一個子事件。`isLastContent` 在最後一個子事件上設置為 true（即 contentIndex == len(content) - 1），其餘為 false。Frontend 可根據此信號知道何時 message 完整，進行最終組裝和呈現。此欄位實現了「Boundary 信號方案」（詳見 UC-007 A2 和 W1-008 設計決策），使 Backend 主動告知 Frontend message 邊界。

### 3.3 WebSocket Server

#### 端點

| 端點 | 說明 |
|------|------|
| `ws://localhost:{port}/ws` | WebSocket 連線端點 |

#### 訊息協議

Client → Server：

```json
{
  "action": "subscribe_session | unsubscribe_session | get_session_list | get_session_history",
  "sessionId": "uuid (optional)",
  "limit": 100,
  "before": "ISO 8601 timestamp (optional)"
}
```

Server → Client：

```json
{
  "type": "session_list | session_event | session_history | session_status_change",
  "data": { ... }
}
```

#### get_session_history 參數說明

| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|-------|------|
| `sessionId` | string | 是 | - | 目標 session 的 UUID |
| `limit` | int | 否 | 100 | 回傳的最大事件數量，上限為 `max_history_lines`（預設 1000） |
| `before` | string | 否 | null | ISO 8601 時間戳，回傳此時間之前的事件（用於向前分頁） |

**before=null 語義**：當 `before` 為 null 或未提供時，回傳該 session **最新的** `limit` 筆事件（從尾端算起）。等同於「載入最近的對話」。

**首次載入 vs 分頁載入**：
- 首次開啟 session 時，Frontend 發送 `get_session_history(sessionId)`（不帶 before），Backend 回傳最新 100 筆事件
- 使用者點擊「載入更早的訊息」時，Frontend 以已載入最早事件的 timestamp 作為 `before` 參數，每次載入 100 筆
- `max_history_lines`（配置值，預設 1000）為 Backend 單一 session 在記憶體中保留的最大事件數上限

#### 訊息類型說明

| 類型 | 觸發時機 | data 內容 |
|------|---------|----------|
| `session_list` | Client 連線時 / 請求時 | 所有 session 列表及 metadata |
| `session_event` | 新事件寫入 JSONL | 單一 SessionEvent |
| `session_history` | Client 請求指定 session | SessionEvent 陣列（依 timestamp 升序排列） |
| `session_status_change` | Session 狀態變更 | session ID + 新狀態 |

#### 連線管理

- 支援多個 Client 同時連線
- 新連線時推送完整 session 列表快照
- Client 可訂閱/取消訂閱特定 session 的即時事件
- 心跳機制（30 秒 ping/pong）

### 3.4 Session 狀態管理

#### Session Registry

```go
type SessionRegistry struct {
    sessions map[string]*SessionInfo
    mu       sync.RWMutex
}

type SessionInfo struct {
    ID          string
    ProjectPath string
    Summary     string
    GitBranch   string
    Status      SessionStatus  // active, idle, completed
    LastEventAt time.Time
    EventCount  int
}
```

#### 狀態判定

| 狀態 | 條件 |
|------|------|
| `active` | 最近 2 分鐘內有新事件 |
| `idle` | 2-30 分鐘內無新事件 |
| `completed` | 30 分鐘以上無新事件，或檔案不再寫入 |

### 3.5 配置

```yaml
# config.yaml
claude_home: "~/.claude"          # Claude Code 資料目錄
port: 8765                        # WebSocket 監聽 port
project_filter: []                # 限制監控的專案路徑（空 = 全部）
idle_timeout: "2m"                # active -> idle 閾值
completed_timeout: "30m"          # idle -> completed 閾值
max_history_lines: 1000           # 單一 session 記憶體保留最大事件數上限
```

支援 CLI flag 覆蓋：

```bash
./ccsession-monitor --port 9999 --claude-home /custom/path
```

---

## 4. Flutter Frontend 規格

### 4.1 Session Dashboard（主畫面）

#### 佈局

```
+--sidebar--+-------main-area--------+
|            |                        |
| [Active]   |   Session Chat View    |
|  > sess-1  |   or                   |
|  > sess-2  |   Split View           |
|            |                        |
| [Idle]     |                        |
|  > sess-3  |                        |
|            |                        |
| [Completed]|                        |
|  > sess-4  |                        |
+------------+------------------------+
```

#### Sidebar Session 項目

每個 session 項目顯示：

| 欄位 | 來源 |
|------|------|
| 摘要 | sessions-index.json `summary` 或第一個 user prompt |
| 專案名稱 | project path 最後一段 |
| Git branch | sessions-index.json `gitBranch` |
| 最後活動時間 | 相對時間（如 "2 分鐘前"） |
| 狀態指示燈 | 綠色（active）/ 黃色（idle）/ 灰色（completed） |

#### 互動

- 點擊 session 在主區域顯示對話內容
- 拖拉 session 到分割面板
- 支援文字搜尋過濾 session 列表

### 4.2 Session 對話檢視

#### 訊息呈現

| 類型 | 樣式 |
|------|------|
| User message | 靠右對齊，藍色系背景 |
| Assistant text | 靠左對齊，灰色系背景，支援 Markdown 渲染 |
| Tool use | 可摺疊區塊，顯示 tool name + 簡要參數摘要 |
| Tool result | 可摺疊區塊，程式碼區塊風格 |
| Thinking | 可摺疊區塊，斜體樣式 |

#### 自動捲動

- 新事件 append 時自動捲動到底部
- 使用者手動上捲時暫停自動捲動
- 底部出現「跳到最新」按鈕

#### 搜尋

- 支援對話內容全文搜尋
- 搜尋結果高亮顯示
- 上/下導航搜尋結果

### 4.3 Multi-Session 分割畫面

#### 佈局模式

| 模式 | 說明 | 最大面板數 |
|------|------|-----------|
| Single | 單一 session 全螢幕 | 1 |
| Split Horizontal | 左右分割 | 2 |
| Split Vertical | 上下分割 | 2 |
| Grid 2x2 | 四格 | 4 |

#### 面板互動

- 每個面板獨立選擇要監控的 session
- 面板間可拖拉調整大小
- 雙擊面板標題列可最大化/還原

### 4.4 WebSocket 連線管理

#### 連線狀態

| 狀態 | UI 呈現 |
|------|---------|
| Connected | 綠色圓點 + "已連線" |
| Connecting | 黃色圓點 + "連線中..." |
| Disconnected | 紅色圓點 + "已斷線" |
| Reconnecting | 黃色閃爍 + "重新連線中..." |

#### 重連策略

- 斷線後 1 秒首次重試
- 指數退避：1s, 2s, 4s, 8s, 16s, 最大 30s
- 重連成功後重新取得 session 列表

---

## 5. 開發計畫

### Phase 1：Go Backend MVP

| 步驟 | 說明 | 驗收條件 |
|------|------|---------|
| 1.1 | 專案初始化（Go module, 目錄結構） | `go build` 成功 |
| 1.2 | JSONL parser | 能正確解析各類事件 |
| 1.3 | File watcher | 偵測到新 append 的行 |
| 1.4 | Session registry | 正確追蹤 session 狀態 |
| 1.5 | WebSocket server | Client 能收到即時事件 |

### Phase 2：Flutter Frontend MVP

| 步驟 | 說明 | 驗收條件 |
|------|------|---------|
| 2.1 | 專案初始化 + WebSocket client | 成功連線到 backend |
| 2.2 | Session list sidebar | 顯示 session 列表，狀態正確 |
| 2.3 | 單一 session 對話檢視 | 即時顯示新事件 |

### Phase 3：核心功能

| 步驟 | 說明 | 驗收條件 |
|------|------|---------|
| 3.1 | Multi-session split view | 同時檢視 2-4 個 session |
| 3.2 | Session 搜尋與過濾 | 搜尋結果高亮 |
| 3.3 | Session 狀態自動偵測 | 狀態指示燈正確 |

### Phase 4：Polish

| 步驟 | 說明 | 驗收條件 |
|------|------|---------|
| 4.1 | 跨平台測試 | macOS / Windows / Linux 正常運行 |
| 4.2 | 效能最佳化 | 大量 session / 長對話流暢 |
| 4.3 | 配置持久化 | 視窗佈局、偏好設定保存 |

---

## 6. 注意事項

### 6.1 容錯設計

- JSONL 格式為 undocumented，可能隨 Claude Code 版本更新而改變
- Parser 必須有良好的容錯能力，未知欄位應忽略而非報錯
- 檔案可能在寫入中途被讀取，需處理不完整的 JSON 行

### 6.2 效能考量

- Session UUID 就是 `.jsonl` 的檔名（去掉副檔名）
- 大型 session 的 JSONL 檔案可能很大
- 首次載入只讀取最近 N 行，提供「載入更多」功能
- 對長時間運行的 session，考慮內存使用量上限

### 6.3 安全考量

- 對話記錄可能包含敏感資訊（API keys、密碼等）
- WebSocket server 預設只監聽 localhost
- 不提供遠端存取功能（除非明確配置）

---

## 7. 可觀測性設計

> **設計動機**：Claude Code 的 JSONL 規格為 undocumented，隨版本更新可能新增、修改或移除欄位。
> 完整的 log 可觀測性確保每個解析環節都有記錄，規格變動時可快速定位需調整的層級。

### 7.1 Log 等級規範

| 等級 | 使用場景 |
|------|---------|
| `DEBUG` | 正常流程的詳細執行記錄（讀取行數、事件路由、state 更新） |
| `INFO` | 重要里程碑（啟動、session 新增/結束、連線建立） |
| `WARN` | 非預期但可繼續執行（未知 JSONL 欄位、未知事件類型、解析跳過） |
| `ERROR` | 需要關注的失敗（解析錯誤、檔案讀取失敗、連線異常） |

### 7.2 Go Backend Log 設計

#### File Watcher 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| 偵測到新 session 檔案 | INFO | `filePath`, `sessionID` |
| 讀取新 append 行 | DEBUG | `sessionID`, `offset`, `bytesRead`, `lineCount` |
| 不完整 JSON 行（等待下次讀取） | DEBUG | `sessionID`, `rawLine` |
| 檔案讀取失敗 | ERROR | `filePath`, `error` |
| Session 檔案被刪除 | INFO | `sessionID`, `reason: file_deleted` |

#### JSONL Parser 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| 開始解析一行 | DEBUG | `sessionID`, `lineIndex`, `type` |
| 發現未知 `type` 值 | WARN | `sessionID`, `unknownType`, `rawLine` |
| content array 出現未知 element type | WARN | `sessionID`, `unknownElementType`, `rawElement` |
| 遇到未知頂層欄位 | WARN | `sessionID`, `unknownField`, `fieldValue` |
| 解析成功 | DEBUG | `sessionID`, `type`, `toolName (if tool_use)` |
| JSON parse 失敗 | ERROR | `sessionID`, `rawLine`, `error` |

```go
// 未知欄位的 WARN log 範例
if _, known := knownFields[key]; !known {
    logger.Warn("unknown JSONL field detected",
        "field", key,
        "sessionID", r.sessionID,
        "hint", "Claude format may have changed")
}
```

#### Session Manager 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| Session 狀態轉換 | INFO | `sessionID`, `from`, `to`, `reason` |
| 新增 session 到 registry | INFO | `sessionID`, `projectPath` |
| Session 移除 | INFO | `sessionID`, `reason` |

#### WebSocket Server 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| Client 連線建立 | INFO | `clientAddr`, `totalClients` |
| Client 連線斷開 | INFO | `clientAddr`, `reason` |
| 推送事件給 Client | DEBUG | `clientAddr`, `eventType`, `sessionID` |
| 未知 Client action | WARN | `clientAddr`, `unknownAction` |
| 廣播失敗 | ERROR | `clientAddr`, `error` |

### 7.3 Flutter Frontend Log 設計

#### WebSocket Client 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| 連線建立 | INFO | `serverUrl`, `timestamp` |
| 連線斷開 | INFO | `reason`, `willRetry`, `retryIn` |
| 收到訊息 | DEBUG | `type`, `dataSize` |
| 解析失敗 | ERROR | `rawMessage`, `error` |

#### Event Mapper 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| 收到未知 event type | WARN | `unknownType`, `rawData` |
| 收到未知 content 欄位 | WARN | `eventType`, `unknownField` |
| 成功映射事件 | DEBUG | `type`, `sessionID` |

#### State Management 層

| 事件 | 等級 | 記錄內容 |
|------|------|---------|
| Session 列表更新 | DEBUG | `sessionCount`, `activeCount` |
| Session 狀態變更 | INFO | `sessionID`, `from`, `to` |
| UI 狀態不一致 | WARN | `sessionID`, `detail` |

### 7.4 Log 輸出格式

兩端均採用結構化 JSON log，方便工具解析：

```json
{
  "level": "WARN",
  "time": "2026-03-05T10:00:00Z",
  "layer": "jsonl_parser",
  "msg": "unknown JSONL field detected",
  "field": "newUnknownField",
  "sessionID": "abc-123",
  "hint": "Claude format may have changed"
}
```

**Go**：使用 `log/slog`（標準庫，Go 1.21+）
**Flutter**：使用 `package:logging`

### 7.5 規格變動偵測流程

當 Claude Code 更新後出現格式異動，可依以下流程快速定位：

```
發現功能異常
    |
    v
查詢 WARN log（關鍵字: "format may have changed" / "unknown field"）
    |
    v
確認哪個 layer 發出 WARN
    |
    +-- jsonl_parser WARN → 更新 Parser 欄位解析邏輯
    +-- event_mapper WARN → 更新 Flutter event 映射
    +-- file_watcher WARN → 確認目錄結構是否變更
    |
    v
對照 WARN log 中的 rawLine/rawData 確認新格式
    |
    v
更新對應層的解析邏輯 + 補充測試
```

---

## 8. 參考資源

### 社群類似專案

| 專案 | 說明 | 連結 |
|------|------|------|
| claude-esp | Go TUI，串流隱藏輸出 | github.com/phiat/claude-esp |
| claude-code-hooks-multi-agent-observability | Hook-based 監控 dashboard | github.com/disler/claude-code-hooks-multi-agent-observability |
| claude-code-monitor | 即時 dashboard + 手機 Web UI | github.com/onikan27/claude-code-monitor |
| claude-JSONL-browser | Web-based JSONL 閱讀器 | github.com/withLinda/claude-JSONL-browser |
| claude-code-transcripts | JSONL 轉 HTML 工具 | github.com/simonw/claude-code-transcripts |
| crystal | 完整桌面應用 | github.com/stravu/crystal |

---

*最後更新: 2026-03-05*
*版本: 1.3.0 - 新增 IsLastContent 欄位（Boundary 信號方案，W1-008 決策）；補充 thinking 事件類型*
