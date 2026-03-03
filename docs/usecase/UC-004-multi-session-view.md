# UC-004: 多 Session 分割畫面

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-004 |
| **名稱** | 多 Session 分割畫面 |
| **Actor** | Developer |
| **優先級** | P1 |
| **元件** | Flutter Frontend |
| **依賴** | UC-002 (Conversation View), UC-003 (Realtime Streaming) |

---

## 目標

Developer 能同時檢視 2-4 個 session 的即時對話內容，
這是本產品的核心賣點，直接解決 CLI 下無法同時看多個 agent 的痛點。

---

## 前置條件

1. 至少有 2 個 session 存在
2. Session 對話檢視功能正常（UC-002）

---

## 主要流程（Happy Path）

1. Developer 在 sidebar 選擇第一個 session（佔滿主區域）
2. Developer 選擇分割模式（Split Horizontal / Split Vertical / Grid 2x2）
3. 主區域分割為多個面板
4. Developer 在每個面板獨立選擇要監控的 session
5. 每個面板獨立運行 UC-002 和 UC-003 的邏輯
6. 所有面板同時即時更新

---

## 替代流程

### A1: 從 Sidebar 拖拉到面板

1. Developer 在 sidebar 長按某 session
2. 拖拉到某個空面板
3. 該面板開始顯示該 session 的對話

### A2: 最大化/還原面板

1. Developer 雙擊某面板的標題列
2. 該面板最大化，其他面板暫時隱藏
3. 再次雙擊還原為分割佈局

### A3: 調整面板大小

1. Developer 拖拉面板間的分隔線
2. 面板大小即時調整
3. 對話內容自適應新寬度

### A4: 關閉面板

1. Developer 點擊面板的關閉按鈕
2. 面板關閉，剩餘面板自動填滿空間
3. 若只剩一個面板，回到單一 session 檢視模式

---

## 佈局模式

| 模式 | 面板數 | 佈局描述 |
|------|--------|---------|
| Single | 1 | 單一 session 全螢幕 |
| Split Horizontal | 2 | 左右並列 |
| Split Vertical | 2 | 上下並列 |
| Grid 2x2 | 4 | 四格網格 |

```
Split Horizontal:        Split Vertical:        Grid 2x2:
+--------+--------+     +----------------+     +--------+--------+
|        |        |     |                |     |        |        |
| Sess A | Sess B |     |    Sess A      |     | Sess A | Sess B |
|        |        |     |                |     |        |        |
+--------+--------+     +----------------+     +--------+--------+
                         |                |     |        |        |
                         |    Sess B      |     | Sess C | Sess D |
                         |                |     |        |        |
                         +----------------+     +--------+--------+
```

---

## 驗收條件

- [ ] 支援 4 種佈局模式切換
- [ ] 每個面板獨立選擇 session
- [ ] 所有面板同時即時更新
- [ ] 面板大小可拖拉調整
- [ ] 面板可最大化/還原
- [ ] 面板可關閉，剩餘面板自動填滿
- [ ] 分割狀態在應用重啟後可恢復（Phase 4 配置持久化）

---

*最後更新: 2026-03-03*
