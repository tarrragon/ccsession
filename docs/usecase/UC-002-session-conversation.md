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

1. Backend 回傳最近 N 條事件（預設 1000）
2. Frontend 頂部顯示「載入更早的訊息」按鈕
3. Developer 點擊後，Frontend 請求更早的事件
4. 新事件 prepend 到對話頂部，保持目前閱讀位置

### A2: 即時更新（Active Session）

1. Session 為 active 狀態，持續有新事件
2. Backend 推送 `session_event` 訊息
3. Frontend 將新事件 append 到對話底部
4. 若 Developer 在最底部 → 自動捲動
5. 若 Developer 已上捲 → 不自動捲動，底部出現「跳到最新」按鈕

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

## 訊息類型渲染規格

| 事件類型 | 對齊 | 背景色 | 特殊處理 |
|---------|------|--------|---------|
| user | 右 | 藍色系 | 純文字 |
| assistant/text | 左 | 灰色系 | Markdown 渲染 |
| tool_use | 左 | 淡紫色系 | 可摺疊，顯示 tool name |
| tool_result | 左 | 淡綠色系 | 可摺疊，程式碼區塊 |
| thinking | 左 | 淡黃色系 | 可摺疊，斜體 |

---

*最後更新: 2026-03-03*
