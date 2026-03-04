# UC-011: JSONL/事件格式變動偵測

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-011 |
| **名稱** | JSONL/事件格式變動偵測 |
| **Actor** | System (Go Backend + Flutter Frontend) |
| **優先級** | P0 |
| **元件** | Both |
| **依賴** | UC-007 (JSONL 事件解析), UC-010 (結構化日誌輸出) |

---

## 目標

當 Claude Code 版本更新導致 JSONL 格式或 WebSocket 事件結構改變時，
系統自動偵測未知欄位/類型並輸出帶有提示的 WARN log，
讓開發者能在最短時間內定位需要更新的程式碼層級。

> **背景**：Claude Code JSONL 格式為 undocumented，任何版本更新都可能新增、修改或移除欄位。

---

## 前置條件

1. UC-010 log 基礎設施已初始化
2. 系統正在解析 JSONL 行或 WebSocket 事件

---

## 主要流程：Go Backend 未知 JSONL 欄位偵測

1. JSONL Parser 讀取一行 JSON
2. 解析頂層欄位，比對已知欄位列表
3. 發現不在列表中的欄位
4. 輸出 WARN log，包含：
   - `unknownField`：欄位名稱
   - `sessionID`：來源 session
   - `hint`：`"Claude format may have changed"`
5. 繼續解析已知欄位，不中斷流程

```go
// 範例實作概念
knownTopLevelFields := map[string]bool{"type": true, "message": true, "timestamp": true}
for key := range rawJSON {
    if !knownTopLevelFields[key] {
        logger.Warn("unknown JSONL field detected",
            "field", key,
            "sessionID", sessionID,
            "hint", "Claude format may have changed")
    }
}
```

---

## 替代流程

### A1: content array 出現未知元素類型

1. assistant content array 中的元素 type 不在已知列表
2. 輸出 WARN log：
   - `unknownElementType`：元素的 type 值
   - `rawElement`：原始 JSON（截斷至 200 字元）
   - `hint`：`"New content type may need support"`
3. 以 `unknown` 類型保留 raw JSON 繼續傳遞
4. UI 以「未知區塊」樣式呈現

### A2: Flutter Event Mapper 收到未知事件類型

1. WebSocket 收到的訊息 type 不在 Flutter 已知列表
2. Flutter Event Mapper 輸出 WARN log：
   - `unknownType`：事件 type 值
   - `rawData`：原始資料（截斷至 200 字元）
   - `hint`：`"Backend event type may have changed"`
3. UI 忽略該事件，不崩潰

### A3: Flutter Event Mapper 收到未知欄位

1. 已知事件類型，但包含未知欄位
2. 輸出 WARN log：
   - `eventType`：事件類型
   - `unknownField`：未知欄位名稱
   - `hint`：`"Backend event schema may have changed"`
3. 正常處理已知欄位，忽略未知欄位

---

## 例外流程

### E1: WARN log 量過多

1. 同一個未知欄位連續出現多次
2. 後端可實作 deduplication（相同欄位只 log 一次）
3. 避免 log 爆炸影響可讀性

---

## 開發者使用場景：規格變動快速定位

當開發者發現解析異常（功能不正常、資料顯示有誤）時：

```
1. 查詢 WARN log（關鍵字: "format may have changed" / "unknown field"）

2. 確認 layer 欄位：
   - layer: "jsonl_parser"   → 更新 Go Parser 欄位解析邏輯
   - layer: "event_mapper"   → 更新 Flutter event 映射
   - layer: "file_watcher"   → 確認目錄結構是否變更

3. 對照 WARN log 中的 rawLine/rawData 確認新格式

4. 更新對應層的解析邏輯 + 補充測試
```

---

## 驗收條件

### Go Backend

- [ ] JSONL Parser：頂層出現未知欄位時輸出 WARN log，含 `unknownField` 和 `hint`
- [ ] JSONL Parser：content array 出現未知元素 type 時輸出 WARN log，含 `unknownElementType`
- [ ] WARN log 含 `layer: "jsonl_parser"` 便於快速識別來源
- [ ] WARN 不中斷解析流程，系統繼續正常運行
- [ ] 相同未知欄位連續出現時，log 有去重機制（不無限重複）

### Flutter Frontend

- [ ] Event Mapper：收到未知 type 時輸出 WARN log，含 `unknownType` 和 `hint`
- [ ] Event Mapper：已知 type 出現未知欄位時輸出 WARN log，含 `unknownField`
- [ ] WARN log 含 `layer: "event_mapper"` 便於快速識別來源
- [ ] 未知事件不導致 Flutter 崩潰或例外
- [ ] UI 對未知事件顯示降級呈現（「未知區塊」）而非空白或錯誤

### 整合驗證

- [ ] 模擬 Claude 格式更新（新增一個假的未知欄位），確認 WARN log 可被搜尋到
- [ ] WARN log 的 `hint` 欄位文字一致，便於 grep 查詢

---

*最後更新: 2026-03-05*
