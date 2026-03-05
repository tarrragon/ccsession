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

## 狀態持久化定義

### 持久化資料模型

應用關閉或重啟後需恢復的多 Panel 版面狀態：

| 欄位 | 型別 | 說明 | 範例值 |
|------|------|------|--------|
| layoutMode | enum | 當前分割模式 | `single`, `splitHorizontal`, `splitVertical`, `grid2x2` |
| panels | list | 各面板狀態清單（依顯示順序） | 見下方 Panel 結構 |

**Panel 結構**：

| 欄位 | 型別 | 說明 | 範例值 |
|------|------|------|--------|
| panelIndex | int | 面板位置索引（0-based） | `0`, `1`, `2`, `3` |
| sessionId | string? | 面板綁定的 session UUID，null 表示空面板 | `"abc-123-def"` |
| scrollPosition | double? | 捲動位置（Phase 4） | `0.85` |

### 持久化行為規則

| 事件 | 持久化動作 |
|------|-----------|
| 切換分割模式 | 立即寫入新的 layoutMode + 更新 panels 清單 |
| 面板選擇/切換 session | 立即寫入該 panel 的 sessionId |
| 面板關閉 | 移除該 panel，更新 layoutMode（若面板數變化導致模式降級） |
| 應用關閉 | 無額外動作（所有變更已即時寫入） |

### 恢復行為規則

| 情境 | 恢復行為 |
|------|---------|
| 正常重啟 | 讀取持久化狀態，還原 layoutMode 和各 panel 的 sessionId |
| 持久化 sessionId 對應的 session 已不存在 | 保留面板位置，sessionId 設為 null（空面板），由使用者重新選擇 |
| 持久化檔案不存在或損壞 | 回退到預設狀態：layoutMode = `single`，panels 為空 |
| 持久化面板數與 layoutMode 不一致 | 以 layoutMode 為準，多餘面板捨棄，不足面板補空 |

### Phase 1 vs Phase 4 持久化範圍

| 持久化項目 | Phase 1 | Phase 4 |
|-----------|---------|---------|
| layoutMode（分割模式） | 納入 | 納入 |
| panels[].sessionId（面板綁定的 session） | 納入 | 納入 |
| panels[].scrollPosition（捲動位置） | 不納入 | 納入 |
| 面板自訂大小比例 | 不納入 | 納入 |
| 最大化面板狀態 | 不納入 | 納入 |

**Phase 1 最小可用範圍**：僅持久化分割模式和各面板的 sessionId，重啟後能恢復「誰在看哪個 session」的基本佈局。面板大小、捲動位置等細節留待 Phase 4 補充。

### 儲存位置

持久化資料儲存於 Flutter 端本地（如 `shared_preferences` 或本地 JSON 檔案），不經過 Go Backend。這是純前端的 UI 偏好設定，與後端的 session 資料無關。

---

## 驗收條件

- [ ] 支援 4 種佈局模式切換
- [ ] 每個面板獨立選擇 session
- [ ] 所有面板同時即時更新
- [ ] 面板大小可拖拉調整
- [ ] 面板可最大化/還原
- [ ] 面板可關閉，剩餘面板自動填滿
- [ ] 分割模式（layoutMode）在應用重啟後可恢復
- [ ] 各面板綁定的 sessionId 在應用重啟後可恢復
- [ ] 持久化 sessionId 對應的 session 不存在時，面板顯示為空（優雅降級）
- [ ] 持久化檔案不存在或損壞時，回退到預設單面板模式

---

*最後更新: 2026-03-05*
