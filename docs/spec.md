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

### 2.3 JSONL 事件結構

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

#### 事件類型

| type | 說明 | content 格式 |
|------|------|-------------|
| `user` | 使用者訊息 | string |
| `assistant` | 助手回應 | content array |

#### Assistant content array 元素類型

| type | 說明 | 關鍵欄位 |
|------|------|---------|
| `text` | 文字回應 | `text` |
| `tool_use` | 工具呼叫 | `name`, `input` |
| `tool_result` | 工具結果 | `content` |
| `thinking` | 思考過程 | `thinking` |

### 2.4 sessions-index.json 結構

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

### 2.5 history.jsonl 結構

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
    SessionID   string          `json:"sessionId"`
    ProjectPath string          `json:"projectPath"`
    Type        string          `json:"type"`        // user, assistant, tool_use, tool_result
    Timestamp   time.Time       `json:"timestamp"`
    Content     json.RawMessage `json:"content"`
    ToolName    string          `json:"toolName,omitempty"`
}
```

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
  "limit": 100
}
```

Server → Client：

```json
{
  "type": "session_list | session_event | session_history | session_status_change",
  "data": { ... }
}
```

#### 訊息類型說明

| 類型 | 觸發時機 | data 內容 |
|------|---------|----------|
| `session_list` | Client 連線時 / 請求時 | 所有 session 列表及 metadata |
| `session_event` | 新事件寫入 JSONL | 單一 SessionEvent |
| `session_history` | Client 請求指定 session | SessionEvent 陣列 |
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
max_history_lines: 1000           # 首次載入最大行數
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

## 7. 參考資源

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

*最後更新: 2026-03-03*
*版本: 1.0.0*
