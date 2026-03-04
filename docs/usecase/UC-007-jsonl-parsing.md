# UC-007: JSONL 事件解析

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-007 |
| **名稱** | JSONL 事件解析 |
| **Actor** | System (Go Backend) |
| **優先級** | P0 |
| **元件** | Go Backend |
| **依賴** | UC-006 (File Watching) |

---

## 目標

將 JSONL 檔案中的原始 JSON 行解析為結構化的 SessionEvent，
支援所有已知的事件類型，對未知類型容錯處理。

---

## 前置條件

1. UC-006 已偵測到檔案變更並傳送原始行

---

## 主要流程（Happy Path）

1. 接收一行 JSON 文字
2. 嘗試 parse 為 JSON 物件
3. 提取共通欄位：type, timestamp
4. 根據 type 分支處理：
   - `user` → 提取 message.content（string）
   - `assistant` → 遍歷 message.content array，分類處理各元素
5. 對 assistant content array 的每個元素：
   - `text` → 提取 text 欄位
   - `tool_use` → 提取 name, input
   - `tool_result` → 提取 content
   - `thinking` → 提取 thinking 欄位
6. 組裝為統一的 SessionEvent 結構
7. 傳送到 event channel

---

## 替代流程

### A1: 未知事件類型

1. type 欄位值不在已知列表中
2. 以 generic 方式處理：保留 raw JSON
3. 輸出 WARN log（含 `unknownType`, `hint: "Claude format may have changed"`）
4. 詳見 UC-011（JSONL 格式變動偵測）

### A2: 巢狀 Content Array

1. assistant content array 包含多個不同類型的元素
2. 為每個元素產生一個子事件
3. 保持原始順序

---

## 例外流程

### E1: JSON Parse 失敗

1. 行內容不是有效的 JSON（可能是寫入中途被讀取）
2. 忽略該行
3. 記錄 debug 日誌
4. 不影響後續行的處理

### E2: 缺少必要欄位

1. JSON 物件缺少 type 或 timestamp
2. 盡可能填入預設值（如當前時間）
3. 若無法補救則跳過

### E3: 非預期的 Content 格式

1. content 不是 string 也不是 array
2. 嘗試 toString() 處理
3. 記錄 warning 日誌

---

## 支援的事件類型矩陣

| JSONL type | content 格式 | 產出 SessionEvent type | 提取欄位 |
|------------|-------------|----------------------|---------|
| `user` | string | `user` | message.content |
| `assistant` | array[text] | `assistant_text` | text |
| `assistant` | array[tool_use] | `tool_use` | name, input |
| `assistant` | array[tool_result] | `tool_result` | content |
| `assistant` | array[thinking] | `thinking` | thinking |
| 其他 | any | `unknown` | raw JSON |

---

## 驗收條件

- [ ] 正確解析 user message 事件
- [ ] 正確解析 assistant text 回應
- [ ] 正確解析 tool_use 事件（含 tool name 和 input）
- [ ] 正確解析 tool_result 事件
- [ ] 正確解析 thinking 事件
- [ ] 不完整 JSON 行不導致崩潰
- [ ] 未知事件類型保留 raw JSON 通過
- [ ] 缺少欄位時優雅降級

---

*最後更新: 2026-03-03*
