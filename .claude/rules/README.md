# 規則系統

本目錄包含**通用規則**（所有角色自動載入）。只放「不管你是誰都必須知道」的規則。

> **平台機制**：Claude Code 啟動時自動載入 `CLAUDE.md` + `.claude/rules/**/*.md`，這是平台硬編碼行為。其他 `.claude/` 子目錄（pm-rules/、references/、agents/ 等）不會自動載入，必須由代理人主動 Read。
>
> **設計原則**：自動載入 = always-built-in。語言專屬、流程調度、工具規範不屬於這裡。

---

## 核心行為約束

> 以下規則**不可協商**，適用於所有專案。

### 1. Skill 優先（最高優先級）

收到任何任務時，**先檢查是否有匹配的 Skill**：

| 優先級 | 觸發方式 | 範例 |
|--------|---------|------|
| 1 | 明確指令 `/skill-name` | `/ticket create`, `/pre-fix-eval` |
| 2 | Skill 描述中的關鍵字 | 「確認待辦」→ ticket Skill |
| 3 | Hook `[SKILL 提示]` 輸出 | Hook 建議使用某 Skill 時**必須**採納 |

### 2. 並行化評估（決策第一步）

接收任務後首先問：「可以讓多少人去做？」

- 可拆分且無依賴 → 並行派發 Task subagent
- A 的發現會改變 B → Agent Teams 或 PM 中轉
- 不可拆分 → 單獨派發代理人

> 詳見 `.claude/pm-rules/decision-tree.md`

### 3. 用戶決策必須使用 AskUserQuestion

PM 需要用戶確認決策時，**必須使用 AskUserQuestion 工具**，禁止開放式文字提問。

**原因**：用戶的自然語言回答可能被 Hook 誤判為開發命令。

> 詳見 `.claude/pm-rules/askuserquestion-rules.md`

### 4. Ticket 工作流

- 所有 Ticket 必須透過 `/ticket create` 建立（禁止直接寫 .md）
- 建立後需通過 acceptance-auditor + system-analyst 並行審核
- 錯誤發生時強制執行 `/pre-fix-eval` 並派發 incident-responder，禁止直接修復

> 完整生命週期：`.claude/pm-rules/ticket-lifecycle.md`
> 事件回應：`.claude/pm-rules/incident-response.md`

### 5. Skip-gate 防護機制

| 層級 | 說明 |
|------|------|
| Level 1 | 錯誤發生時強制派發 incident-responder，禁止直接修復 |
| Level 2 | 開發命令執行前驗證 Ticket 存在性（Hook 自動檢查） |
| Level 3 | PM 只能編輯允許列表中的檔案路徑 |

> 詳見 `.claude/pm-rules/skip-gate.md`

### 6. TDD 流程

新功能或架構變更強制完整 TDD（Phase 0-4）。小型修改、遷移任務可豁免部分 Phase。

> 詳見 `.claude/pm-rules/tdd-flow.md`

---

## 快速參考

| 需求 | 工具/指令 |
|------|----------|
| 建立任務 | `/ticket create` |
| 查詢進度 | `/ticket track summary` |
| 錯誤分析 | `/pre-fix-eval`（強制） |
| 用戶決策 | AskUserQuestion |
| 版本發布 | `/version-release` |
| 技術債務 | `/tech-debt-capture` |

---

## 目錄結構

```
.claude/rules/                    # 通用規則（自動載入，7 檔 ~1100 行）
├── README.md                     # 本文件（框架入口 + 核心行為約束）
└── core/
    ├── quality-common.md         # 通用品質基線（含語言規則索引）
    ├── quality-baseline.md       # 流程品質基線（測試率/Phase 4/Hook 失敗）
    ├── bash-tool-usage-rules.md  # Bash 工具使用規則
    ├── cognitive-load.md         # 認知負擔設計原則
    ├── document-format-rules.md  # 文件格式規範
    └── language-constraints.md   # 語言約束（繁中/禁用詞/禁 emoji）

.claude/pm-rules/                 # PM + 流程規則（按需載入）
├── decision-tree.md              # 主線程二元決策樹（核心）
├── tdd-flow.md                   # TDD 流程
├── incident-response.md          # 事件回應流程
├── ticket-lifecycle.md           # Ticket 生命週期
├── tech-debt.md                  # 技術債務流程
├── skip-gate.md                  # Skip-gate 防護
├── askuserquestion-rules.md      # AskUserQuestion 規則
├── parallel-dispatch.md          # 並行派發指南
├── task-splitting.md             # 任務拆分指南
├── verification-framework.md     # 驗證責任分配
├── version-progression.md        # 版本推進決策
├── monorepo-version-strategy.md  # Monorepo 版本管理
├── plan-to-ticket-flow.md        # Plan-to-Ticket 轉換
├── methodology-index.md          # 方法論索引
├── skill-index.md                # Skill 指令索引
└── query-vs-research.md          # 查詢 vs 研究決策

.claude/references/               # 按需讀取（語言規則 + 工具規範）
├── quality-dart.md               # Dart/Flutter 品質（parsley 專用）
├── quality-go.md                 # Go 品質（fennel 專用）
├── quality-python.md             # Python 品質（thyme/basil 專用）
├── quality-language-template.md  # 語言規則模板
├── ticket-id-conventions.md      # Ticket ID 命名規範
├── document-system.md            # 五重文件系統規則
└── ...                           # 其他參考文件
```

---

## 讀取時機

| 目錄 | 載入方式 | 對象 |
|------|---------|------|
| `rules/` | 自動載入（平台行為） | 所有角色 |
| `pm-rules/` | PM 按需讀取 | PM 主線程 |
| `references/quality-*.md` | 代理人按需讀取 | 對應語言代理人 |
| `agents/` | 派發時讀取 | PM 派發決策 |

---

**Last Updated**: 2026-03-26
**Version**: 6.0.0 - 補充核心行為約束（Skill 優先/並行化/AskUserQuestion/Ticket/Skip-gate/TDD），確保框架跨專案可攜（0.2.0-W5-012.2）
