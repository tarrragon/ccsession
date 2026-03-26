# 規則系統

本目錄包含專案的共用規則（所有角色自動載入）。PM 專用規則位於 `.claude/pm-rules/`（按需載入）。

> **核心原則**：decision-tree 是所有決策的起點，其他規則都是它的支撐或延伸。
> **PM 規則位置**：`.claude/pm-rules/`（不自動載入，PM 主線程按需 Read）

---

## 目錄結構

```
.claude/rules/                    # 共用規則（自動載入，所有角色）
├── README.md                     # 本文件
├── core/                         # 品質標準 + 基本約束
│   ├── cognitive-load.md         # 認知負擔設計原則
│   ├── document-format-rules.md  # 文件格式
│   ├── document-system.md        # 五重文件系統規則
│   ├── implementation-quality.md # 實作品質標準（Hub）
│   ├── language-constraints.md   # 語言約束
│   ├── python-execution.md       # Python 執行規則
│   ├── bash-tool-usage-rules.md  # Bash 工具使用規則
│   ├── ticket-id-conventions.md  # Ticket ID 命名規範
│   ├── quality-baseline.md       # 流程品質基線
│   ├── quality-common.md         # 通用品質基線（所有語言）
│   ├── quality-dart.md           # Dart/Flutter 品質規則
│   ├── quality-go.md             # Go 品質規則
│   ├── quality-python.md         # Python 品質規則
│   └── quality-language-template.md # 語言品質規則模板
├── flows/                        # 執行流程
│   ├── tdd-flow.md               # TDD 流程
│   ├── incident-response.md      # 事件回應流程
│   ├── tech-debt.md              # 技術債務流程
│   └── ticket-lifecycle.md       # Ticket 生命週期
└── guides/                       # （已移至 pm-rules）

.claude/pm-rules/                 # PM 專用規則（按需載入）
├── decision-tree.md              # 主線程二元決策樹（核心）
├── askuserquestion-rules.md      # AskUserQuestion 強制使用規則
├── verification-framework.md     # 驗證責任分配框架
├── parallel-dispatch.md          # 並行派發指南
├── task-splitting.md             # 任務拆分指南
├── methodology-index.md          # 方法論索引
├── skill-index.md                # Skill 指令索引
├── query-vs-research.md          # 查詢 vs 研究決策指南
├── skip-gate.md                  # Skip-gate 防護
├── version-progression.md        # 版本推進決策規則
├── monorepo-version-strategy.md  # Monorepo 版本管理策略
└── plan-to-ticket-flow.md        # Plan-to-Ticket 轉換流程

代理人定義位於：.claude/agents/（按需載入，不常駐）
```

---

## 快速導航

| 需求 | 文件 |
|------|------|
| 決策入口 | .claude/pm-rules/decision-tree.md |
| 代理人定義 | .claude/agents/ |
| TDD 流程 | .claude/rules/flows/tdd-flow.md |
| 錯誤處理 | .claude/rules/flows/incident-response.md |
| 任務拆分 | .claude/pm-rules/task-splitting.md |
| 品質要求 | .claude/rules/core/quality-baseline.md |

---

## 讀取時機

| 目錄 | 讀取時機 |
|------|---------|
| `rules/core/` | 自動載入（品質規範） |
| `rules/flows/` | 自動載入（執行流程） |
| `pm-rules/` | PM 主線程按需載入 |
| `.claude/agents/` | 派發決策時（按需載入） |

---

**Last Updated**: 2026-03-26
**Version**: 4.0.0 - PM 規則移至 .claude/pm-rules/（0.2.0-W5-012.1 context 瘦身）
