# UC-002: Session 對話檢視

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-002 |
| **名稱** | Session 對話檢視 |
| **Actor** | Developer |
| **優先級** | P0 |
| **元件** | Flutter Frontend |
| **依賴** | UC-001 (Session List), UC-009 (WebSocket) |

---

## 目標

Developer 選擇一個 session 後，能在主區域以聊天氣泡形式閱讀完整的對話歷史，
包含 user message、assistant response、tool use/result 等各類事件。

---

## 前置條件

1. Session 列表已載入（UC-001 完成）
2. 目標 session 的 JSONL 檔案存在且可讀取

---

## 主要流程（Happy Path）

1. Developer 在 sidebar 點擊一個 session
2. Frontend 發送 `get_session_history` 請求到 Backend
3. Backend 讀取該 session 的 JSONL 檔案，回傳 `session_history` 訊息
4. Frontend 在主區域渲染對話內容：
   - User message → 靠右對齊，藍色系背景
   - Assistant text → 靠左對齊，灰色系背景，Markdown 渲染
   - Tool use → 可摺疊區塊，顯示 tool name + 簡要參數
   - Tool result → 可摺疊區塊，程式碼風格
   - Thinking → 可摺疊區塊，斜體樣式
5. 對話自動捲動到最新訊息

---

## 替代流程

### A1: 大型 Session（載入更多）

1. Backend 回傳最近 N 條事件（預設 limit=100，Backend 記憶體上限 max_history_lines=1000）
2. Frontend 頂部顯示「載入更早的訊息」按鈕
3. Developer 點擊後，Frontend 使用已載入最早事件的 timestamp 作為 `before` 參數，請求更早的事件：
   ```
   get_session_history(sessionId, limit=100, before=earliest_timestamp)
   ```
4. 使用 timestamp-based cursor 而非 offset，確保新 append 的事件不影響分頁狀態
5. 新事件 prepend 到對話頂部，保持目前閱讀位置
6. 重複直到沒有更多歷史記錄或用戶停止載入

#### 分頁連續性保證

跨分頁載入時，必須確保事件序列的完整性和連續性：

| 規則 | 說明 |
|------|------|
| 無重複 | Backend 回傳的事件以 `timestamp` 為嚴格邊界（`before` 為排他比較），確保分頁間不出現重複事件 |
| 無遺漏 | 若同一 timestamp 下有多筆事件，Backend 必須在同一批次中全部回傳，不可拆分到不同分頁 |
| 順序一致 | 每次分頁回傳的事件按 timestamp 升序排列，prepend 後與既有事件保持時間順序不中斷 |
| 結束信號 | Backend 回傳事件數量 < limit 時，表示已無更早的歷史記錄；Frontend 隱藏「載入更早的訊息」按鈕 |

### A2: 即時更新（Active Session）

1. Session 為 active 狀態，持續有新事件
2. Backend 推送 `session_event` 訊息
3. Frontend 將新事件 append 到對話底部
4. 若 Developer 在最底部 → 自動捲動
5. 若 Developer 已上捲 → 不自動捲動，底部出現「跳到最新」按鈕

#### 自動捲動與分頁載入的互動優先級

當 active session 同時觸發自動捲動和分頁載入時，適用以下優先級規則：

| 情境 | 行為 | 說明 |
|------|------|------|
| Developer 在底部 + 新事件到達 | 自動捲動到最新事件 | 正常即時追蹤行為 |
| Developer 正在頂部載入歷史 + 新事件到達 | 新事件 append 到底部，不自動捲動，不中斷分頁載入 | 分頁載入優先；避免載入歷史時畫面跳動 |
| Developer 按下「跳到最新」 | 立即捲動到底部，中止任何進行中的分頁載入請求 | 使用者明確意圖優先 |
| 分頁載入進行中 + Developer 捲動到底部 | 分頁載入繼續完成，自動捲動恢復為啟用狀態 | 兩者不衝突時可並行 |

**核心原則**：使用者的明確操作（手動捲動、按下按鈕）優先於系統自動行為（自動捲動）；正在進行的使用者請求（分頁載入）不應被系統行為中斷。

### A3: Tool Use 展開

1. Developer 點擊 tool use 區塊
2. 展開顯示完整參數（如 Bash command、Read file path 等）
3. 再次點擊摺疊

---

## 例外流程

### E1: Session 檔案不存在

1. Backend 回傳錯誤
2. Frontend 顯示「此 session 的對話記錄已不存在」

### E2: 解析錯誤

1. 某些 JSONL 行解析失敗
2. Backend 跳過失敗行，回傳可解析的事件
3. Frontend 正常渲染已解析的事件

---

## 驗收條件

- [ ] 點擊 session 後 1 秒內開始渲染對話
- [ ] User / Assistant / Tool 各類事件正確區分顯示
- [ ] Assistant 回應支援 Markdown 渲染（標題、程式碼區塊、清單等）
- [ ] Tool use / result / thinking 區塊可摺疊/展開
- [ ] 大型 session 支援分頁載入
- [ ] Active session 有新事件時即時 append
- [ ] 自動捲動邏輯正確（底部時自動捲、上捲時停止）

---

## 事件排序規則

### 主要排序

所有事件以 `timestamp` 升序排列（最早的在上方，最新的在下方）。

### 次級排序（時間戳相同時）

當多筆事件具有相同 timestamp 時，依以下規則決定顯示順序：

| 優先級 | 排序依據 | 說明 |
|--------|---------|------|
| 1 | JSONL 檔案中的行號順序 | 同一 timestamp 的事件按其在 JSONL 檔案中出現的先後順序排列（即 append 順序） |
| 2 | 語義配對順序 | tool_use 事件必須出現在對應的 tool_result 之前；thinking 必須出現在同一回合的 assistant/text 之前 |

**實作規則**：

- Backend 在解析 JSONL 時為每筆事件賦予單調遞增的序號（line index）
- 排序以 `(timestamp, line_index)` 複合鍵為準
- 此機制確保即使多筆事件在同一毫秒內寫入，顯示順序仍與原始檔案一致
- Frontend 收到的事件已由 Backend 排序完成，直接按順序渲染即可

---

## 訊息類型渲染規格

| 事件類型 | 對齊 | 背景色 | 特殊處理 |
|---------|------|--------|---------|
| user | 右 | 藍色系 | 純文字 |
| assistant/text | 左 | 灰色系 | Markdown 渲染 |
| tool_use | 左 | 淡紫色系 | 可摺疊，顯示 tool name |
| tool_result | 左 | 淡綠色系 | 可摺疊，程式碼區塊 |
| thinking | 左 | 淡黃色系 | 可摺疊，斜體 |

---

*最後更新: 2026-03-05*
