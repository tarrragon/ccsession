# IMP-035: Guard Clause 與篩選狀態衝突

## 錯誤摘要

| 項目 | 說明 |
|------|------|
| **分類** | Implementation |
| **嚴重性** | 中（功能邏輯錯誤，非崩潰） |
| **發現版本** | v0.1.1 |
| **相關 Ticket** | 0.1.1-W9-002.1 |

## 症狀

- 函式在「篩選後只剩一個結果」時，誤觸「無結果」的 guard clause
- 使用者查詢特定項目時得到「找不到任何項目」的錯誤訊息
- 測試中 mock 正確設定但斷言失敗（輸出為空結果提示）

## 根因分析

**行為模式**：函式同時承擔「全量列表」和「篩選查詢」兩種模式，但 guard clause 只考慮了全量列表場景。篩選後的合法單一結果被 guard clause 誤判為「無資料」。

**具體案例**：

```python
# cmd_status 同時支援：
# 1. 無參數 → 列出全部 worktree
# 2. 有 ticket_id → 篩選特定 worktree

# Step 2: 篩選（正確找到目標）
if ticket_id is not None:
    worktrees = [target_worktree]  # 篩選後長度 = 1

# Step 3: guard clause（只考慮全量場景）
if len(worktrees) <= 1:  # 篩選結果也觸發了！
    print("目前沒有任何 worktree")  # 錯誤訊息
```

**衝突本質**：guard clause 的條件 `len <= 1` 在全量模式下語義正確（只有主倉庫 = 無額外 worktree），但在篩選模式下語義錯誤（找到 1 個 = 有結果）。

## 解決方案

在 guard clause 加入模式判斷條件，區分「全量無結果」和「篩選有結果」：

```python
# 修復：guard clause 只在未篩選時生效
if ticket_id is None and len(worktrees) <= 1:
    print("目前沒有任何 worktree")
```

## 預防措施

### 設計時檢查（函式支援多模式時）

當一個函式同時支援「列出全部」和「篩選特定」兩種模式時：

1. **guard clause 必須考慮所有模式**：每個 early return / guard clause 都要問「這個條件在篩選模式下是否也成立？」
2. **優先拆分函式**：如果模式差異大，考慮拆為 `list_all()` 和 `get_one()` 兩個函式
3. **測試覆蓋所有模式**：每個 guard clause 至少有「全量」和「篩選」兩個測試案例

### 附帶模式：dry-run 語義定位

同一 Ticket 也發現 `cmd_create` 的 dry-run 放在 git 狀態檢查之後，導致 dry-run 依賴外部狀態。

**原則**：dry-run 應在「格式驗證後、副作用前」返回。如果 dry-run 需要真實外部狀態才能執行，它就不是真正的 dry-run。

## 偵測方式

- Code review 時搜尋「同一函式內有 optional 參數控制不同模式 + guard clause」的組合
- 測試時確保每個 guard clause 在「有參數」和「無參數」兩種呼叫方式下都有測試

---

**記錄日期**: 2026-03-18
**記錄者**: rosemary-project-manager
