# AskUserQuestion 強制使用規則

本文件定義所有需要使用 AskUserQuestion 工具的場景和規範。這是 AskUserQuestion 規則的唯一 Source of Truth。

---

## 通用觸發原則（行為驅動，優先於場景枚舉）

> **任何時候，只要你正在向用戶輸出選項供其選擇，就必須使用 AskUserQuestion 工具。**

**判斷方法**：問自己「我的回覆中是否包含讓用戶選擇的選項？」

- **是** → 必須使用 AskUserQuestion（不需要對照場景清單確認）
- **否** → 一般文字回覆即可

**重要**：下方 17 個場景是常見情境的範例，**不是**觸發條件的完整清單。觸發條件只有一個：輸出含選項供用戶選擇。

---

## 背景

### 為什麼需要 AskUserQuestion

PM 用開放式提問（如「要並行處理嗎？」）時，用戶的自然語言回答可能被 Hook 系統誤判為開發命令（觸發 command-entrance-gate-hook）。使用 Claude Code 原生的 AskUserQuestion 工具可消除此風險。

### AskUserQuestion 是 Deferred Tool

AskUserQuestion 是 deferred tool，使用前**必須**先載入：

```
ToolSearch("select:AskUserQuestion")
```

載入後即可直接呼叫。每個 Hook 提醒訊息都包含此提示。

---

## 強制規則

### 規則 1：決策確認必須使用 AskUserQuestion

PM 需要用戶確認決策時，**必須使用 AskUserQuestion 工具**，而非文字提問。

### 規則 2：ToolSearch 前置載入

使用 AskUserQuestion 前必須先執行 `ToolSearch("select:AskUserQuestion")` 載入。

### 規則 3：禁止文字提問替代

禁止使用開放式文字問句讓用戶自由回答可能觸發 Hook 的詞彙。

---

## 場景列表

### 17 個強制使用場景

| # | 場景 | 觸發條件 | 決策點 | Hook 提醒 |
|---|------|---------|--------|-----------|
| 1 | 驗收方式確認 | ticket track complete 前 | ticket-lifecycle 驗收階段 | acceptance-gate-hook |
| 2 | Complete 後下一步 | ticket track complete 後 | ticket-lifecycle 完成階段 | acceptance-gate-hook |
| 3 | Wave/任務收尾確認 | Wave 無 pending Ticket | ticket-lifecycle 收尾 | parallel-suggestion-hook |
| 4 | 方案選擇 | 多個技術方案 | 決策樹第負一層 | prompt-submit-hook |
| 5 | 優先級確認 | 多任務排序 | 決策樹第負一層 | prompt-submit-hook |
| 6 | 任務拆分確認 | 認知負擔 > 10 | 決策樹第負一層 | prompt-submit-hook |
| 7 | 派發方式選擇 | Task subagent / Agent Teams / 序列 | 決策樹第負一層 | askuserquestion-reminder-hook |
| 8 | 執行方向確認 | 並行/序列、先後順序 | 決策樹第負一層 | - |
| 9 | Handoff 方向選擇 | 多個兄弟/子任務可選 | ticket-lifecycle 完成階段 | - |
| 10 | 開始/收尾確認 | 確認是否開始執行 | 決策樹第負一層 | - |
| 11 | Commit 後情境感知 Handoff | git commit 後依情境路由（11a/11b，或轉 #3） | 決策樹第八層 | commit-handoff-hook |
| 12 | 流程省略確認 | 省略意圖偵測 | 決策樹第八層 | process-skip-guard-hook |
| 13 | 後續任務路由確認 | 任務完成後 | 決策樹第八層 | phase-completion-gate（擴充） |
| 14 | parallel-evaluation 觸發確認 | 階段完成後 | 決策樹第八層 | phase-completion-gate（擴充） |
| 15 | Bulk 變更前備份確認 | 批量修改前 | 決策樹第八層 | parallel-suggestion-hook（擴充） |
| 16 | 錯誤學習經驗確認 | commit 完成後（#11 之前） | 決策樹第八層 Checkpoint 1.5 | commit-handoff-hook（擴充） |
| 17 | 錯誤經驗改進追蹤 | ticket complete 時有新增 error-pattern | ticket-lifecycle 完成階段 | acceptance-gate-hook（擴充） |

**Hook 覆蓋狀態**：12/17 場景有 Hook 自動提醒（從 10/15 提升到 12/17 = 71%）。

### AskUserQuestion 工具能力

- 2-4 個選項，帶標籤和描述
- 單選（`multiSelect: false`）或多選（`multiSelect: true`）
- 自動提供「Other」選項供自由輸入
- markdown 預覽（方案比較時使用）

---

> 各場景完整操作細節：.claude/references/askuserquestion-scene-details.md

## 違規處理

| 違規行為 | 處理方式 |
|---------|---------|
| 文字提問替代 AskUserQuestion | 停止，改用 AskUserQuestion |
| 跳過確認直接執行 | 提醒後繼續 |
| 未載入就使用 AskUserQuestion | ToolSearch 載入後重試 |

---

## Hook 提醒機制

以下 Hook 在關鍵決策點自動輸出 AskUserQuestion 提醒：

| Hook | 觸發時機 | 覆蓋場景 |
|------|---------|---------|
| parallel-suggestion-hook | 繼續請求但無 pending Ticket | #3 Wave 收尾 + #15 批量備份 |
| prompt-submit-hook | 用戶提問含決策關鍵字 | #4 方案 + #5 優先級 + #6 拆分 |
| askuserquestion-reminder-hook | Task 派發含多個 Ticket ID | #7 派發方式 |
| commit-handoff-hook | git commit 成功後 | #11 Commit Handoff + #16 錯誤學習 |
| process-skip-guard-hook | 用戶輸入含省略關鍵字 | #12 流程省略 |
| phase-completion-gate-hook | Phase 完成偵測後 | #13 後續路由 + #14 parallel-evaluation |
| acceptance-gate-hook | ticket track complete 命令 | #1 驗收方式 + #2 下一步 + #17 錯誤經驗改進 |

---

## 相關文件

- .claude/rules/core/decision-tree.md - 主線程決策樹
- .claude/rules/flows/ticket-lifecycle.md - Ticket 生命週期
- .claude/references/askuserquestion-scene-details.md - 場景 1-17 完整操作細節
- .claude/references/ticket-askuserquestion-templates.md - AskUserQuestion 模板
- .claude/rules/guides/parallel-dispatch.md - 並行派發指南

---

**Last Updated**: 2026-03-08
**Version**: 2.5.0 - 場景 1-17 詳細說明移至 references/askuserquestion-scene-details.md（0.1.0-W13-004）
**Purpose**: AskUserQuestion 規則唯一 Source of Truth
