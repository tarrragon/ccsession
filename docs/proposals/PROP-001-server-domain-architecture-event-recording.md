---
id: PROP-001
title: "Server Domain Architecture, Event Normalization, and Recording Boundary"
status: draft
source: "spec"
proposed_by: "codex"
proposed_date: "2026-04-22"
confirmed_date: null
target_version: "v0.3.0"
priority: "P1"

outputs:
  spec_refs: []
  usecase_refs: []
  ticket_refs: []

related_proposals: []
supersedes: null
---

# PROP-001: Server Domain Architecture, Event Normalization, and Recording Boundary

## 需求來源

核心需求是先為 v0.3 Agent Graph 與後續互動能力建立 server 架構提案，而不是立即改動實作。現有 server 已能完成本地監控工具的主要任務：讀取外部 JSONL、接收 HTTP Hooks、融合事件、更新 session 狀態，並透過 WebSocket 推送給 UI。

這個架構在 v0.2 情境下合理，因為資料主要來自外部檔案與 hooks，server 本身不需要擁有資料庫或複雜 request lifecycle。然而 `docs/spec.md` §8 已規劃 v0.3 Agent Graph 即時動畫元件，該功能會引入更明確的互動需求、agent 拓撲、標準化事件記錄與可重播資料流。

本提案同時作為 Go 教材規劃輸入：後續 `go/06-practical` 與 `go/07-refactoring` 不應只教「如何修改目前平面檔案」，而應教工程師如何從簡單後端逐步走向 domain-oriented、event-driven、hexagonal architecture 的可維護結構。

## 問題描述

核心問題是現有 server 的檔案結構與事件模型已足夠支撐 v0.2 監控，但不足以作為 v0.3 Agent Graph 與後續互動功能的長期邊界。現在的 server 檔案大多平行展開在 `server/`，domain、transport、application flow、observability 與 state storage 混在同一個 package 中。

這會帶來四個風險：

| 風險 | 說明 |
|------|------|
| Domain 邊界模糊 | session、agent、event、websocket、file watching 都在同一層，新增功能時容易不知道該改哪裡 |
| Event 語意不夠正規化 | JSONL event、HookEvent、DispatchedEvent、WebSocket message 各自服務不同目的，缺少共同的 domain event envelope |
| 記錄邊界不足 | 目前以記憶體 registry 為主，缺少 append-only event log 或 repository port，未來難以支援 replay、graph reconstruction、標準化記錄 |
| 教材容易變成維護手冊 | 若 practical/refactoring 直接照目前平面檔案教，讀者會學到專案內部改法，而不是 Go 後端架構思考 |

## 影響範圍

| 影響項目 | 說明 |
|---------|------|
| 模組 | Go server、WebSocket protocol、event processing、session/agent state、logging |
| 檔案 | `server/*.go` 現有平面檔案；未來可能拆成 `cmd/`、`internal/domain/`、`internal/application/`、`internal/adapters/` |
| 用例 | UC-009 WebSocket 通訊、UC-010 結構化日誌、UC-011 格式變動偵測、spec §8 v0.3 Agent Graph |
| 教材 | `go/06-practical`、`go/07-refactoring`、`go-advanced/04-architecture-boundaries`、`go-advanced/06-production-operations` |

## 範圍界定

### 本提案要做的（In Scope）

- 定義 server 未來的 domain-oriented 分層方向。
- 定義 v0.3 前置的 event-driven 正規化模型。
- 定義記錄邊界：structured log、event log、state repository 的責任分工。
- 定義 Clean Architecture / Hexagonal Architecture 在本專案中的建議目錄與依賴方向。
- 定義 practical/refactoring 教材在後續撰寫時應覆蓋的主題。
- 明確列出哪些項目目前只做設計，不落地實作。

### 本提案不做的（Out of Scope）

- 不改動 `server/` 實作檔案。理由：本輪目標是提案與教材規劃，不是架構遷移。
- 不新增資料庫依賴。理由：目前產品仍是本地監控工具，資料來源主要外部生成；DB 應等 event log/replay 需求確認後再獨立提案。
- 不實作 Agent Graph。理由：spec §8 已是 v0.3 功能規劃，本提案只建立 server 端前置架構決策。
- 不建立 tickets。理由：提案仍為 draft，尚未確認拆分範圍與版本波次。
- 不重寫既有 use case。理由：目前先提出對應關係與缺口，待提案 confirmed 後再轉化 spec/usecase。

## 提案方案

核心方案是把 server 從「平面 package + 元件檔案」逐步演進為「domain-oriented hexagonal structure」。這不是要求一次大重構，而是先建立目標結構與依賴規則，讓 v0.3 新功能與教材都能沿同一套邊界思考。

### 方案 A：維持現有平面結構，只補功能

| 面向 | 評估 |
|------|------|
| 優點 | 最快；短期改動少；符合目前小型工具規模 |
| 缺點 | v0.3 Agent Graph 會把 agent/session/event/status 語意塞回同一層；教材容易變成專案操作手冊 |
| 適用時機 | 只修 bug、只補小型 WebSocket action |

### 方案 B：按技術層分目錄

| 面向 | 評估 |
|------|------|
| 優點 | 比平面結構清楚；例如 `http/`、`websocket/`、`watcher/` 容易定位 |
| 缺點 | domain 邊界仍可能分散；agent graph 狀態會被 transport 形狀牽著走 |
| 適用時機 | 中小型服務、domain 規則很少 |

### 方案 C：Domain-oriented Hexagonal Structure（建議）

| 面向 | 評估 |
|------|------|
| 優點 | domain 規則集中；transport 與 storage 可替換；適合教學說明 Go 的小介面、event-driven、repository 與 usecase 邊界 |
| 缺點 | 初期檔案數增加；需要嚴格避免過度抽象 |
| 適用時機 | v0.3 Agent Graph、event replay、標準化記錄、未來互動功能 |

### 建議方案

建議採用方案 C，但以漸進式遷移為原則。核心規則是先讓新功能沿著新邊界落地，舊功能只在需要修改時逐步搬移，不為了形式一次性搬所有檔案。

建議目錄方向：

```text
server/
├── cmd/ccsession-monitor/
│   └── main.go
├── internal/
│   ├── domain/
│   │   ├── session/
│   │   ├── agent/
│   │   ├── event/
│   │   └── graph/
│   ├── application/
│   │   ├── ports/
│   │   └── usecases/
│   ├── adapters/
│   │   ├── inbound/
│   │   │   ├── filewatch/
│   │   │   ├── hooks/
│   │   │   ├── http/
│   │   │   └── websocket/
│   │   └── outbound/
│   │       ├── memory/
│   │       └── eventlog/
│   └── observability/
└── go.mod
```

依賴方向：

```text
adapters -> application -> domain
observability <- adapters/application/domain use interfaces or logger boundary
domain 不依賴 adapters
application 定義 ports，adapters 實作 ports
```

## 建議 Domain 邊界

### Session Domain

Session domain 的核心責任是描述對話 session 的生命週期。它處理 `active / idle / completed` 這類 session lifecycle，不應承擔 graph 視覺狀態。

可能包含：

- `SessionID`
- `SessionStatus`
- `SessionInfo`
- `SessionHistory`
- status transition policy

### Agent Domain

Agent domain 的核心責任是描述 agent/subagent 的身份、拓撲與視覺狀態。它應與 session lifecycle 分離，避免把 `SessionStatus` 和 `AgentStatus` 混用。

可能包含：

- `AgentID`
- `AgentNode`
- `AgentStatus`：`idle / thinking / active / error`
- `ParentAgentID`
- `AgentLabel`
- graph topology policy

### Event Domain

Event domain 的核心責任是統一不同來源的事件語意。JSONL、HTTP hooks、future client actions 都應先轉成共同 envelope，再進入 processing。

建議 envelope：

```go
type DomainEvent struct {
	ID            string
	Source        EventSource
	Type          EventType
	SubjectID     string
	SubjectKind   SubjectKind
	CorrelationID string
	CausationID   string
	OccurredAt    time.Time
	ReceivedAt    time.Time
	SchemaVersion int
	Payload       json.RawMessage
}
```

欄位語意：

| 欄位 | 核心用途 |
|------|----------|
| `ID` | event log 去重與追蹤 |
| `Source` | JSONL、hook、websocket action、system timer |
| `Type` | 領域事件類型 |
| `SubjectID` | 被事件描述的 session/agent/tool |
| `SubjectKind` | session、agent、tool、graph |
| `CorrelationID` | 串起同一次流程 |
| `CausationID` | 描述事件因果鏈 |
| `OccurredAt` | 外部事件發生時間 |
| `ReceivedAt` | server 收到時間 |
| `SchemaVersion` | 支援未來 event schema 演進 |
| `Payload` | 來源特定資料，留在 adapter/usecase 邊界解析 |

### Graph Domain

Graph domain 的核心責任是把 agent event 轉成 UI 可消費的 graph projection。它不應直接讀 WebSocket，也不應依賴 JSONL 原始格式。

可能包含：

- `AgentGraph`
- `GraphNode`
- `GraphEdge`
- `GraphMessage`
- topology reconstruction policy
- transcript path inference policy

## 記錄邊界設計

記錄邊界的核心原則是分清三種「記錄」：

| 類型 | 核心問題 | 建議機制 |
|------|----------|----------|
| Structured Log | 系統發生了什麼，如何除錯？ | `slog` JSON log |
| Event Log | 哪些 domain event 發生過，可否重播？ | append-only event store |
| State Repository | 目前狀態是什麼？ | memory repository，未來可替換 SQLite |

### Structured Log

Structured log 的核心責任是 operational observability。它不應保存完整對話內容，也不應當成產品資料庫。

建議標準欄位：

| 欄位 | 說明 |
|------|------|
| `layer` | `filewatch`、`hooks`、`event_processor`、`websocket`、`repository` |
| `event_type` | domain event type |
| `source` | event source |
| `session_id` | 如適用 |
| `agent_id` | 如適用 |
| `correlation_id` | 串起一次流程 |
| `reason` | 穩定錯誤/降級原因 |

### Event Log

Event log 的核心責任是支援 replay、Agent Graph reconstruction、debug 與未來互動回放。它應保存標準化 domain event，而不是直接保存 transport message。

第一階段可以只定義 port，不落地 DB：

```go
type EventLog interface {
	Append(ctx context.Context, event DomainEvent) error
	List(ctx context.Context, query EventQuery) ([]DomainEvent, error)
}
```

實作策略可分兩階段：

| 階段 | 實作 | 說明 |
|------|------|------|
| v0.3 前置 | in-memory event log 或 no-op port | 先確立邊界 |
| 後續提案 | SQLite append-only table | 支援重播、查詢、重啟後保留 |

### State Repository

State repository 的核心責任是提供目前 projection，例如 session list、agent graph、subscription state。它可由 event processor 更新，也可由 event log replay 重建。

建議不要讓 WebSocket handler 直接修改 domain state。WebSocket action 應轉成 command/usecase，再由 application layer 決定狀態或事件。

## Clean Architecture / Hexagonal 拆分策略

### Inbound Adapters

Inbound adapter 的核心責任是接收外部輸入並轉成 application command/event。

| Adapter | 目前對應 | 未來責任 |
|---------|----------|----------|
| filewatch | `file_watcher.go` + `jsonl_parser.go` | JSONL raw input -> DomainEvent |
| hooks | `hooks_handler.go` | HookEvent -> DomainEvent |
| websocket | `websocket_server.go` | ClientMessage -> Command |
| http | `main.go` route handlers | health、diagnostics、future REST |

### Application Layer

Application layer 的核心責任是協調 usecase，不保存 transport 細節。

建議 usecase：

- `IngestExternalEvent`
- `ProcessDomainEvent`
- `GetSessionList`
- `GetSessionHistory`
- `SubscribeToTopic`
- `BuildAgentGraphProjection`
- `ApplyClientCommand`

### Outbound Ports

Outbound port 的核心責任是讓 application 不依賴具體儲存或推送技術。

建議 ports：

- `SessionRepository`
- `AgentRepository`
- `EventLog`
- `GraphProjectionRepository`
- `Publisher`
- `Clock`
- `Logger` 或 structured logging helper

## Event-Driven 正規化策略

Event-driven 正規化的核心原則是讓「外部來源事件」和「領域事件」分離。外部來源事件不穩定，領域事件是 server 內部合約。

建議流程：

```text
Raw JSONL / Hook / Client Action
        |
        v
Inbound Adapter
        |
        v
Normalize / Validate
        |
        v
DomainEvent
        |
        +--> EventLog.Append
        |
        v
EventProcessor
        |
        +--> Session Projection
        +--> Agent Graph Projection
        +--> WebSocket Publisher
```

事件分類：

| 類型 | 說明 | 範例 |
|------|------|------|
| ExternalEvent | 外部原始來源 | JSONL line、HTTP hook payload |
| DomainEvent | 內部標準化事件 | `agent.started`、`session.updated` |
| IntegrationEvent | 對外推送事件 | WebSocket `agent_status_change` |
| Command | client 或內部主動意圖 | `subscribe_topic`、`get_history` |

這個分類可以直接轉化為教材：讀者能學到 event-driven 不是「到處傳 channel」，而是先定義事件語意、來源邊界、處理規則與投影。

## Practical / Refactoring 教材規劃影響

後續教材不應從「修改某個專案檔案」出發，而應從 Go 工程師會遇到的通用任務出發。

### Practical 章節應覆蓋

| 章節 | 建議教材主題 | 需要帶出的 Go 精神 |
|------|--------------|-------------------|
| 新增即時訊息 action | Client command -> usecase -> response | handler 薄化、小介面、錯誤回應 |
| 新增事件類型 | Raw input -> DomainEvent -> processor | event envelope、validation、dedup |
| 擴展狀態資料欄位 | domain model -> repository -> projection -> API | source of truth、copy boundary、相容性 |
| 新增背景工作流程 | ticker/queue worker -> context -> event ingestion | goroutine lifecycle、shutdown、testability |

### Refactoring 章節應覆蓋

| 章節 | 建議教材主題 | 需要帶出的架構能力 |
|------|--------------|-------------------|
| handler boundary | transport 和 usecase 分離 | HTTP/WebSocket 不直接做 domain mutation |
| interface boundary | ports 由 application 定義 | 小介面、依賴反轉 |
| dedup refactor | dedup key 從來源格式改為 domain key | event-driven 正規化 |
| state boundary | repository + projection + copy | 並發安全、future DB readiness |

這些章節可以使用中立範例，不需要提到本專案名稱。專案只作為背後的教材靈感。

## 驗收條件

- [ ] 提案明確說明為什麼現有平面 server 結構不足以支撐 v0.3 Agent Graph 與後續互動能力。
- [ ] 提案列出 domain-oriented 目錄方向與依賴規則。
- [ ] 提案區分 structured log、event log、state repository 三種記錄責任。
- [ ] 提案定義 event-driven 正規化流程與 DomainEvent envelope。
- [ ] 提案指出 v0.3 Agent Graph 需要 session domain 與 agent domain 分離。
- [ ] 提案列出 practical/refactoring 教材應覆蓋的架構主題。
- [ ] 提案明確標示本輪不落地實作、不新增 DB、不開 ticket。

## 風險與權衡

| 風險 | 影響 | 緩解措施 |
|------|------|---------|
| 過度架構化 | 小型本地工具被拆得太複雜 | 採漸進式遷移；新功能先走新邊界，舊功能不一次搬移 |
| 教材偏離 Go 入門 | practical/refactoring 太像企業架構課 | 教材先講 Go 語言精神，再用後端架構做延伸 |
| Event log 被誤解成必須上 DB | 提早引入儲存成本 | 先定義 port；實作可用 in-memory/no-op，DB 另開提案 |
| DomainEvent 過度抽象 | 新增事件時需要填太多欄位 | envelope 欄位分 required/optional；先支援 v0.3 必要欄位 |
| Agent/session 語意混淆 | Graph 狀態和 session lifecycle 互相污染 | 明確拆分 SessionStatus 與 AgentStatus |

## 討論記錄

### 2026-04-22

建立 draft 提案。背景是 Go 教材已完成大部分入門與進階章節，只剩 practical/refactoring 待規劃；同時 `docs/spec.md` §8 已規劃 v0.3 Agent Graph，server 端需要先思考 domain 分層、event 正規化與記錄邊界。

本次只建立提案，不改 server，不開 ticket。

## 轉化記錄

| 轉化類型 | 檔案 | 日期 | 狀態 |
|---------|------|------|------|
| 規格 | `docs/spec/{domain}/server-domain-architecture.md` | | pending |
| 規格 | `docs/spec/{domain}/event-normalization.md` | | pending |
| 用例 | Agent Graph server event projection UC | | pending |
| Ticket | v0.3 architecture migration tickets | | pending |
