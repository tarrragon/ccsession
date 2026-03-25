---
name: spec
description: "需求完善度品質閘門 — 遞迴需求展開器。Use for: (1) Phase 1 開始時初始化功能規格骨架 (/spec init), (2) 驗證功能規格的需求完善度 (/spec validate), (3) 判斷需求是否足夠清晰可進入實作。Use when: lavender-interface-designer 在 Phase 1 進行功能設計時，作為內部工具使用。不是流程入口——/tdd 管流程編排，/spec 管產出物品質。"
---

# /spec - 遞迴需求展開器

把模糊需求展開成無歧義的行為契約。

---

## 核心抽象

/spec 是一棵**需求問題樹的遞迴展開器**：

```
模糊需求
    |
    v
展開第 1 層：拆解為可獨立驗證的子需求
    |
    v
展開第 2 層：每個子需求補充邊界、錯誤路徑、狀態轉換
    |
    v
展開第 N 層：直到每個葉節點都是一個 GWT（Given-When-Then）行為
    |
    v
無歧義的行為契約（= Phase 1 設計文件）
```

**停止條件**：葉節點可直接轉為 GWT 測試案例，無需額外假設。

---

## 定位與分工

| 工具 | 問的問題 | 階段 | 關係 |
|------|---------|------|------|
| /tdd | 「流程走到哪了？下一步做什麼？」 | Phase 0-4 全流程 | 流程編排器 |
| /spec | 「需求描述得夠不夠清楚？」 | Phase 1 內部 | 產出物品質工具 |
| SA | 「該不該做？和現有系統一致嗎？」 | Phase 0 | 架構守門人 |

**/spec 不是流程入口**：lavender 在 Phase 1 內部使用 /spec 產出功能規格。/tdd 不呼叫 /spec，/spec 不呼叫 /tdd。兩者完全解耦。

---

## 子命令總覽

| 子命令 | 用途 | 適用時機 |
|--------|------|---------|
| `/spec init` | 初始化功能規格骨架 | Phase 1 開始，lavender 收到 Ticket 後 |
| `/spec validate` | 驗證需求完善度 | 規格撰寫完成後，進入 Phase 2 前 |

---

## `/spec init` - 初始化功能規格骨架

讀取 Ticket frontmatter，自動判斷模式，產出對應模板骨架。

### 輸入

- Ticket ID（必填）：從 frontmatter 讀取 type、where、priority 等欄位

### 模式判斷（自動）

```
讀取 Ticket frontmatter
    |
    v
符合 Full 任一條件？
    |
    +-- 是 → Full 模式（6 區段）
    |
    +-- 否 → Lite 模式（3 區段）
```

**Full 模式觸發條件**（任一符合）：

| 條件 | 判斷依據 |
|------|---------|
| 新功能開發 | type == IMP 且 how.task_type == "新增" |
| 跨模組修改 | where.files 涉及 2+ 架構層級 |
| 修改檔案多 | where.files > 5 |
| API 變更 | what 含 "API"/"介面"/"protocol"/"協議" |
| 明確指定 | 用戶執行 `/spec init --mode full` |

**Lite 模式**：不符合任何 Full 條件，或用戶執行 `/spec init --mode lite`。

### 輸出

- 功能規格骨架檔案：`{ticket-id}-feature-spec.md`
- 存放位置：Ticket 所在目錄（`docs/work-logs/v{version}/tickets/`）
- **Spec 文件即 Phase 1 設計文件**（同一檔案，非額外產物）

### Lite 模式骨架（3 區段）

```markdown
# {Ticket ID} 功能規格

## 1. Purpose（目的）
<!-- 用一句話回答：這個功能解決什麼問題？為誰解決？ -->

## 2. Scenarios（行為場景）
<!-- 用 GWT 格式描述每個行為場景 -->
### 場景 1: {場景名稱}
- **Given**: {前置條件}
- **When**: {觸發動作}
- **Then**: {預期結果}

## 3. Acceptance（驗收條件）
<!-- 可直接驗證的條件清單 -->
- [ ] {條件 1}
```

### Full 模式骨架（6 區段）

```markdown
# {Ticket ID} 功能規格

## 1. Purpose（目的）
<!-- 問題背景、目標用戶、核心價值 -->

## 2. API Signatures（介面定義）
<!-- 函式簽名、輸入輸出型別、回傳值語義 -->

## 3. GWT Scenarios（行為場景）
<!-- Given-When-Then 格式，含正常流程和異常流程 -->

## 4. Error Handling（錯誤處理）
<!-- 每個錯誤情境的處理策略和回傳值 -->

## 5. Dependencies（依賴）
<!-- 外部依賴、前置條件、環境假設 -->

## 6. Acceptance（驗收條件）
<!-- 可直接驗證的條件清單，含效能指標（如適用） -->
```

> 完整模板含填寫指引和範例：`references/spec-template-lite.md`、`references/spec-template-full.md`

---

## `/spec validate` - 驗證需求完善度

兩層驗證：結構檢查（機械性）+ AI 語義推演（深度分析）。

### 輸入

- Spec 文件路徑（必填）：`{ticket-id}-feature-spec.md`

### Layer 1：結構檢查（自動，秒級）

檢查模板區段的存在性和非空性。

| 模式 | 必須存在的區段 | 檢查內容 |
|------|--------------|---------|
| Lite | Purpose, Scenarios, Acceptance | 區段標題存在且內容非空 |
| Full | 全部 6 區段 | 區段標題存在且內容非空 |

**額外結構檢查**：

| 檢查項 | 規則 |
|--------|------|
| GWT 格式 | Scenarios 區段至少 1 個 Given-When-Then 完整三元組 |
| Acceptance 可驗證性 | 每個條件以 `- [ ]` 開頭 |
| Purpose 簡潔性 | 不超過 200 字（Lite）/ 500 字（Full） |

**結構檢查失敗**：輸出缺失清單，不進入 Layer 2。

### Layer 2：AI 語義推演（深度，需思考）

沿 7 個維度掃描規格文件，找出**未被展開的需求假設**。每個維度產出一組「未回答問題」。

#### 7 個語義推演維度

| # | 維度 | 核心問題 | 適用模式 |
|---|------|---------|---------|
| 1 | 邊界完整性 | 極端值、空值、上限下限的行為定義了嗎？ | Lite + Full |
| 2 | 錯誤路徑 | 每個操作失敗時，系統如何回應？ | Lite + Full |
| 3 | 狀態完整性 | 所有狀態和轉換都定義了嗎？有不可達狀態嗎？ | Lite + Full |
| 4 | 並發安全 | 多個使用者/執行緒同時操作會怎樣？ | Full only |
| 5 | 效能約束 | 資料量增長 10x/100x 時行為如何？有回應時間要求嗎？ | Full only |
| 6 | 安全性 | 誰可以執行此操作？敏感資料如何保護？ | Full only |
| 7 | 依賴明確性 | 外部依賴的契約是否明確？依賴不可用時的降級策略？ | Full only |

**Lite 模式只掃描維度 1-3**（核心三維度 + 適用性判斷），降低小型任務的認知負擔。

#### 語義推演輸出格式

```markdown
## /spec validate 結果

### 結構檢查：通過/未通過
{缺失清單，如有}

### 語義推演：{N} 個未回答問題

#### 維度 1: 邊界完整性
- Q1: 當 {參數} 為空值時，預期行為是什麼？
- Q2: {集合} 的上限是多少？超過上限時如何處理？

#### 維度 2: 錯誤路徑
- Q3: {操作} 失敗時，是否需要回滾已完成的步驟？

#### 維度 3: 狀態完整性
（無未回答問題）

### 建議
- 必須回答：Q1, Q3（影響 GWT 設計）
- 建議回答：Q2（影響效能設計）
- 可延後：無
```

#### 反向提問策略

AI 語義推演不是機械套用維度，而是**以規格撰寫者的假設為起點**，反向提問：

1. **讀取規格** → 識別撰寫者的隱含假設
2. **針對每個假設** → 問「如果這個假設不成立呢？」
3. **針對每個 GWT** → 問「Given 的前置條件是否總是成立？When 的觸發能否被繞過？Then 的結果是否唯一？」
4. **產出未回答問題** → 每個問題對應一個可能的需求盲點

---

## 迭代機制

/spec validate 可多次執行，形成**收斂式迭代**：

```
撰寫規格 → validate → 回答問題 → validate → ... → 無新問題 → 完成
```

### 迭代上限

| 模式 | 上限 | 理由 |
|------|------|------|
| Lite | 2 次 | 小型任務不應花費過多時間在規格上 |
| Full | 3 次 | 第 3 次仍有大量問題表示需求本身不成熟，應升級 PM |

### 停止條件（任一滿足即停止）

| 條件 | 說明 |
|------|------|
| 無新問題 | validate 輸出 0 個未回答問題 |
| 達到上限 | Lite 2 次 / Full 3 次 |
| 問題收斂 | 本次問題數 <= 上次的 50% |
| 撰寫者判斷 | lavender 認為剩餘問題可在 Phase 2 解決 |

### 超過上限處理

```
第 N+1 次 validate 請求
    |
    v
輸出警告：「已達迭代上限（N 次）。剩餘 X 個問題。」
    |
    v
建議：(a) 升級 PM 評估需求成熟度
       (b) 標記剩餘問題為 Phase 2 待解決
       (c) 強制執行 validate（--force）
```

---

## 使用流程（Phase 1 內部）

```
lavender 收到 Phase 1 任務
    |
    v
/spec init {ticket-id}
    → 產出規格骨架（Lite 或 Full）
    |
    v
lavender 撰寫規格內容
    → 填充各區段
    |
    v
/spec validate {spec-file}
    → Layer 1 結構檢查
    → Layer 2 語義推演
    |
    v
有未回答問題？
    |
    +-- 是 → lavender 補充回答 → 再次 validate（迭代）
    |
    +-- 否 → 規格完成，Phase 1 產出物就緒
```

**lavender 的職責**：使用 /spec 工具，但由 lavender 決定如何回答問題、如何組織規格內容。/spec 只負責「發現問題」，不負責「解決問題」。

---

## 相關文件

- .claude/skills/tdd/SKILL.md - TDD 流程工具（流程編排）
- .claude/agents/lavender-interface-designer.md - Phase 1 設計代理人（/spec 的使用者）
- .claude/rules/flows/tdd-flow.md - TDD 完整流程定義
- references/spec-template-lite.md - Lite 模板（3 區段）
- references/spec-template-full.md - Full 模板（6 區段）

---

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Source**: 0.2.0-W3-003（Phase 3b context 耗盡 → 需求完善度品質閘門）
