# BDD 整合測試場景設計文件

本目錄包含 Claude Code Multi-Agent Session Monitor v0.1.0 的端對端整合測試場景，採用 Gherkin 語法（BDD 格式）設計。

## 檔案清單

### UC 單元測試場景（9 個）

| 檔案 | UC | 場景數 | 描述 |
|------|-----|--------|------|
| `UC-001-session-list.feature` | UC-001 | 12 | Session 列表瀏覽：分組顯示、狀態轉換、動畫規範 |
| `UC-002-session-conversation.feature` | UC-002 | 20 | Session 對話檢視：事件渲染、分頁載入、捲動邏輯 |
| `UC-003-realtime-streaming.feature` | UC-003 | 10 | 即時事件串流：延遲目標、吞吐量、記憶體管理 |
| `UC-004-multi-session-view.feature` | UC-004 | 18 | 多 Session 分割畫面：佈局模式、拖拉、持久化 |
| `UC-005-search-filter.feature` | UC-005 | 12 | 搜尋與篩選：列表篩選、全文搜尋、高亮導航 |
| `UC-006-file-watching.feature` | UC-006 | 12 | JSONL 檔案監控：掃描、增量讀取、跨平台 |
| `UC-007-jsonl-parsing.feature` | UC-007 | 15 | JSONL 事件解析：子事件拆分、Boundary 信號 |
| `UC-008-session-state.feature` | UC-008 | 16 | Session 狀態管理：狀態機、Metadata 優先級 |
| `UC-009-websocket-communication.feature` | UC-009 | 22 | WebSocket 通訊：連線、訂閱、心跳機制 |

### 端對端整合場景

| 檔案 | 場景數 | 描述 |
|------|--------|------|
| `E2E-integration-scenarios.feature` | 18 | 跨 UC 的完整流程：從啟動到實時監控、多 session 並行、狀態轉換、分頁搜尋、錯誤恢復 |

## 場景統計

- **總場景數**：157 個
- **UC 單元場景**：139 個
- **端對端場景**：18 個

## 場景設計原則

### 1. Gherkin 格式標準

每個場景遵循以下結構：

```gherkin
Feature: [功能名稱]
  Background:
    Given [前置條件]
    And [額外前置條件]

  Scenario: [場景名稱]
    Given [初始狀態]
    When [執行動作]
    Then [預期結果]
    And [額外驗證]
```

### 2. 繁體中文編寫

- 所有場景描述使用繁體中文（zh-TW）
- 技術名詞保留英文（如 WebSocket、sessionId、JSONL 等）
- 無 emoji 符號，狀態標示使用文字（`[x]`, `[ ]`, `→` 等）

### 3. 完整覆蓋

- **Happy Path**：主流程正常執行場景
- **替代流程**：邊界情況、使用者選項場景
- **例外流程**：錯誤恢復、異常條件場景
- **性能約束**：效能指標、資源限制場景

### 4. W1 補充內容納入

本設計文件完整納入 W1-007~015 補充的所有新規則：
- UC-001：狀態回升（completed/idle → active）的動畫規範
- UC-001：摘要來源優先級定義
- UC-002：自動捲動與分頁載入的互動優先級
- UC-007：Boundary 信號方案（messageId、contentIndex、isLastContent）
- UC-004：Phase 1 vs Phase 4 持久化範圍
- UC-008：Metadata 來源優先級和 canonical 定義

## 場景複雜度分類

### 簡單場景（單一責任）
- 驗證單一功能是否正常運作
- 場景數：50 個左右
- 範例：「顯示 session 列表」、「解析 user message 事件」

### 中等複雜場景（多步驟互動）
- 涉及多個步驟的使用者操作或系統流程
- 場景數：80 個左右
- 範例：「分頁載入對話歷史」、「WebSocket 重連」

### 複雜場景（跨系統整合）
- 涉及多個 UC 或多個系統元件的協調
- 場景數：27 個（主要在 E2E）
- 範例：「從啟動到實時監控的完整流程」、「4 個 session 並行監控」

## 使用指南

### 給 Phase 3a 策略規劃者

1. 讀取本設計文件的場景列表
2. 為每個場景設計對應的測試策略（單元、整合、e2e）
3. 將 Gherkin 場景轉換為虛擬碼或測試框架的 pseudo code
4. 識別 mock 物件和測試資料需求
5. 評估測試覆蓋率和執行時間預算

### 給 Phase 3b 實作者

1. 逐個實現 feature files 中的場景
2. 建立測試環境和 fixture
3. 實現每個場景的 Given-When-Then 步驟
4. 驗證測試能正確通過或失敗（雙向驗證）
5. 記錄測試執行時間和覆蓋率

### 給 Phase 4 重構評估者

1. 檢查測試程式碼是否遵循品質標準
2. 評估測試與實作的耦合程度
3. 識別重複的測試邏輯和可提取的公共步驟
4. 優化測試執行時間和資源使用
5. 評估測試框架和工具的適用性

## 測試依賴關係

```
UC-006（File Watching）
    ↓
UC-007（JSONL Parsing）
    ↓
UC-008（Session State）
    ↓
UC-009（WebSocket）
    ↓
UC-001（Session List）← UC-003（Realtime）
    ↓
UC-002（Conversation） ← UC-003
    ↓
UC-004（Multi-Session）
    ↓
UC-005（Search）
```

實作順序應遵循此依賴關係，後面的 UC 測試才能正常執行。

## 性能指標參考

本設計文件中明確列出的性能目標：

| 指標 | 目標值 | 場景位置 |
|------|--------|--------|
| 端到端延遲 | < 500ms（上限 1s） | UC-003 #1, E2E #7 |
| 事件吞吐量 | >= 100 events/sec | UC-003 #2, UC-007 |
| 檔案偵測延遲 | < 100ms | UC-006 #2 |
| JSONL Parser | <= 50ms | UC-003 預算 |
| Session List 顯示 | <= 3 秒 | UC-001 #1 |
| 搜尋回應時間 | < 200ms | UC-005 #9 |
| 單連線記憶體 | < 32 KB | UC-009 #19 |
| 廣播延遲（10 連線） | < 10ms | UC-009 #20 |

## 已知限制與預留設計

### Phase 1 不實作的功能

- UC-005：後端全文搜尋（Phase 3+ 預留）
- UC-004：scrollPosition 持久化（Phase 4）
- 面板自訂大小比例持久化（Phase 4）
- 最大化面板狀態持久化（Phase 4）

### 可配置參數

| 參數 | 預設值 | 位置 |
|------|--------|------|
| idle_timeout | 2 分鐘 | UC-008 |
| completed_timeout | 30 分鐘 | UC-008 |
| max_history_lines | 1000 | UC-003, UC-009 |
| limit（單次分頁） | 100 | UC-002, UC-009 |
| WebSocket port | 8765 | UC-009 |
| 心跳間隔 | 30 秒 | UC-009 |
| 單 project 最大檔案監控 | 50 | UC-006 |

## 相關文件

- [spec.md](../spec.md) - 完整的技術規格
- [UC-001~009 設計文件](../usecase/) - 各 UC 的完整要求
- [W1 工作日誌](../work-logs/v0.1.0/) - 版本設計和決策記錄
- [Ticket 0.1.0-W1-002](../work-logs/v0.1.0/tickets/0.1.0-W1-002.md) - 本設計的執行記錄

---

**最後更新**：2026-03-05
**版本**：1.0.0（Phase 2 測試設計完成）
**負責人**：sage-test-architect（TDD Phase 2）
