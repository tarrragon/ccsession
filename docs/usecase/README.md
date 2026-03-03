# Use Case Index

## 概述

本目錄定義 Claude Code Multi-Agent Session Monitor 的所有 Use Case。
Use Case 是後續 BDD/整合測試、單元測試和實作的基礎。

---

## Use Case 分類

### 使用者面向（User-Facing）

使用者直接互動的功能場景。

| ID | 名稱 | Actor | 優先級 |
|----|------|-------|--------|
| UC-001 | [Session 列表瀏覽](./UC-001-session-list.md) | Developer | P0 |
| UC-002 | [Session 對話檢視](./UC-002-session-conversation.md) | Developer | P0 |
| UC-003 | [即時事件串流](./UC-003-realtime-streaming.md) | Developer | P0 |
| UC-004 | [多 Session 分割畫面](./UC-004-multi-session-view.md) | Developer | P1 |
| UC-005 | [搜尋與篩選](./UC-005-search-filter.md) | Developer | P1 |

### 系統面向（System-Level）

後端系統的核心行為，不直接對應 UI 操作但支撐所有使用者功能。

| ID | 名稱 | 元件 | 優先級 |
|----|------|------|--------|
| UC-006 | [JSONL 檔案監控](./UC-006-file-watching.md) | Go Backend | P0 |
| UC-007 | [JSONL 事件解析](./UC-007-jsonl-parsing.md) | Go Backend | P0 |
| UC-008 | [Session 狀態管理](./UC-008-session-state.md) | Go Backend | P0 |
| UC-009 | [WebSocket 通訊](./UC-009-websocket-communication.md) | Both | P0 |

---

## Use Case 之間的依賴關係

```
UC-006 (File Watching)
    |
    v
UC-007 (JSONL Parsing)
    |
    v
UC-008 (Session State) ---> UC-009 (WebSocket)
                                |
                +---------------+---------------+
                |               |               |
                v               v               v
           UC-001          UC-002          UC-003
        (Session List)  (Conversation)  (Realtime)
                                |
                    +-----------+-----------+
                    |                       |
                    v                       v
               UC-004                  UC-005
           (Split View)            (Search/Filter)
```

---

## 開發流程

```
Use Case 定義（本階段）
    |
    v
整合測試 / BDD 規格設計
    |
    v
單元測試設計
    |
    v
前後端各自測試
    |
    v
專案實作
```

---

*最後更新: 2026-03-03*
