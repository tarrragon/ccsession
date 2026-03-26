# 規則系統

本目錄包含專案的**通用規則**（所有角色自動載入）。只放「不管你是誰都必須知道」的規則。

> **平台機制**：Claude Code 啟動時自動載入 `CLAUDE.md` + `.claude/rules/**/*.md`，這是平台硬編碼行為。其他 `.claude/` 子目錄（pm-rules/、references/、agents/ 等）不會自動載入，必須由代理人主動 Read。
>
> **設計原則**：自動載入 = always-built-in。語言專屬、流程調度、工具規範不屬於這裡。
> **PM 規則**：`.claude/pm-rules/`（PM 按需讀取）
> **語言規則**：`.claude/references/quality-{lang}.md`（代理人按需讀取）

---

## 目錄結構

```
.claude/rules/                    # 通用規則（自動載入，7 檔 ~1100 行）
├── README.md                     # 本文件
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

## 快速導航

| 需求 | 文件 |
|------|------|
| 決策入口 | .claude/pm-rules/decision-tree.md |
| TDD 流程 | .claude/pm-rules/tdd-flow.md |
| 錯誤處理 | .claude/pm-rules/incident-response.md |
| 品質要求 | .claude/rules/core/quality-baseline.md |
| 語言品質 | .claude/rules/core/quality-common.md（索引表） |

---

## 讀取時機

| 目錄 | 讀取時機 |
|------|---------|
| `rules/core/` | 自動載入（所有角色通用） |
| `pm-rules/` | PM 主線程按需載入 |
| `references/quality-*.md` | 語言代理人按需讀取 |
| `.claude/agents/` | 派發決策時（按需載入） |

---

**Last Updated**: 2026-03-26
**Version**: 5.0.0 - 第二輪瘦身：流程規則移至 pm-rules/，語言/工具規則移至 references/（0.2.0-W5-012.2）
