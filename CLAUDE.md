# CLAUDE.md - 專案開發規範

本文件是 Claude Code 讀取專案資訊的入口，定義專案基本資訊和開發規範。

---

## 專案資訊

| 項目 | 說明 |
|------|------|
| **專案名稱** | Claude Code Multi-Agent Session Monitor |
| **專案類型** | 跨平台即時監控系統（Go Backend + Flutter Frontend） |
| **開發語言** | Go（後端）、Dart（前端） |
| **框架版本** | Flutter 3.41 |
| **專案目標** | 解決 CLI 環境下同時運行多個 Claude Code agent/subagent 時，難以同時監控所有 session 進度與內容的 UX 問題 |

### 架構概述

- **Go Backend**：監控本地 JSONL 檔案變更、解析對話內容、提供 WebSocket server
- **Flutter Frontend**：即時 UI 呈現，支援 macOS / Windows / Linux / 行動裝置

### 資料夾結構

```
ccsession/
├── server/                  # Go 後端
│   ├── go.mod               # Go module 定義
│   └── main.go              # 入口點
├── ui/                      # Flutter 前端
│   ├── lib/                 # Dart 應用程式碼
│   ├── test/                # 測試檔案
│   ├── pubspec.yaml         # Flutter 依賴定義
│   └── ...                  # 各平台目錄（android/ios/macos/web/...）
├── docs/                    # 專案文件、工作日誌、Ticket
├── .claude/                 # Claude Code 配置（規則、hooks、skills）
├── CLAUDE.md                # 本文件（Claude Code 入口）
└── README.md                # 專案說明
```

> 工作時需明確區分語言環境：Go 指令在 `server/` 執行，Flutter 指令在 `ui/` 執行。

### 核心原理

Claude Code 的所有對話紀錄以 JSONL 格式即時寫入 `~/.claude/` 目錄。
每個 message 產生後立即 append 到磁碟，透過 file watching 實現接近即時的監控。

> 詳細技術規格：[docs/spec.md](./docs/spec.md)

---

## 開發規範

### 語言特定規範

| 語言 | 規範位置 |
|------|---------|
| Flutter/Dart（前端） | [FLUTTER.md](./.claude/project-templates/FLUTTER.md) |
| Go（後端） | 待建立 |

### 通用規範

以下規範由 `.claude/rules/` 自動載入，適用於所有語言：

| 規範 | 位置 |
|------|------|
| 主線程決策樹 | `.claude/rules/core/decision-tree.md` |
| 實作品質標準 | `.claude/rules/core/implementation-quality.md` |
| TDD 流程 | `.claude/rules/flows/tdd-flow.md` |
| Ticket 生命週期 | `.claude/rules/flows/ticket-lifecycle.md` |
| 事件回應流程 | `.claude/rules/flows/incident-response.md` |

---

## 核心行為約束

> 以下規則**不可協商**，每次工作都必須遵循。完整細節在 `.claude/rules/` 中。

### Skill 優先（最高優先級）

收到任何任務時，**先檢查是否有匹配的 Skill**：

| 優先級 | 觸發方式 | 範例 |
|--------|---------|------|
| 1 | 明確指令 `/skill-name` | `/ticket create`, `/pre-fix-eval` |
| 2 | Skill 描述中的關鍵字 | 「確認待辦」→ ticket Skill |
| 3 | Hook `[SKILL 提示]` 輸出 | Hook 建議使用某 Skill 時**必須**採納 |

**常用 Skill**：`/ticket create`（建立任務）、`/ticket track`（追蹤）、`/pre-fix-eval`（錯誤分析，強制）、`/version-release`（版本發布）

### 並行化評估（決策第一步）

接收任務後首先問：「可以讓多少人去做？」

- 可拆分且無依賴 → 並行派發 Task subagent
- A 的發現會改變 B → Agent Teams 或 PM 中轉
- 不可拆分 → 單獨派發代理人

> 詳見 `.claude/rules/core/decision-tree.md`

### 用戶決策必須使用 AskUserQuestion

PM 需要用戶確認決策時，**必須使用 AskUserQuestion 工具**，禁止開放式文字提問。

**原因**：用戶的自然語言回答可能被 Hook 誤判為開發命令。

**關鍵場景**：驗收確認、後續步驟、Wave 收尾、派發方式、Commit 後路由。

> 詳見 `.claude/rules/core/askuserquestion-rules.md`

---

## Ticket 工作流

### 強制規則：Ticket 必須用指令建立

**禁止**直接用 Write 工具建立 `.md` 檔案。所有 Ticket 必須透過 `/ticket create` 建立。

```bash
# 正確
ticket create --version 0.1.0 --wave 1 --action "實作" --target "XXX"

# 禁止
直接 Write docs/work-logs/v0.1.0/tickets/XXX.md
```

### Ticket 生命週期

```
pending → claim → in_progress → complete → completed
```

| 階段 | 強制動作 | 禁止行為 |
|------|---------|---------|
| 建立 | `/ticket create` | 直接寫 .md |
| 認領 | 檢查依賴是否完成 | 忽視阻塞 |
| 執行中 | 錯誤 → `/pre-fix-eval` → incident-responder | 直接修復程式碼 |
| 完成前 | AskUserQuestion 確認驗收方式 | 跳過驗收 |

### 錯誤發生時的強制流程

觸發關鍵字：「test failed」「編譯錯誤」「runtime error」「bug」「問題」

```
錯誤發生 → [強制] /pre-fix-eval → [強制] 派發 incident-responder
→ 分析分類 → 建立 Bug Ticket → PM 派發對應代理人修復
```

**禁止**：直接修改程式碼、跳過分析、省略 Ticket

> 詳見 `.claude/rules/flows/incident-response.md`

---

## 品質基線

### 不可協商的規則

| 規則 | 要求 |
|------|------|
| 測試通過率 | 100%，不通過禁止提交 |
| Phase 4 評估 | 所有功能都需執行，不可跳過 |
| 設計問題 | 發現即修正，不延後 |
| Hook 失敗 | 必須可見，禁止靜默失敗 |

### Skip-gate 禁止行為

| 層級 | 禁止 |
|------|------|
| Level 1 | 直接修復測試失敗（必須派發 incident-responder） |
| Level 2 | 無 Ticket 執行開發命令 |
| Level 3 | PM 編輯程式碼（`lib/*`, `test/*`, `*.dart`, `*.go`） |

> 詳見 `.claude/rules/forbidden/skip-gate.md`

---

## TDD 流程摘要

新功能或架構變更時**強制執行**：

```
Phase 0: SA 前置審查 (system-analyst)
Phase 1: 功能設計 (lavender-interface-designer)
Phase 2: 測試設計 (sage-test-architect)
Phase 3a: 策略規劃 (pepper-test-implementer)
Phase 3b: 實作 (parsley-flutter-developer / Go developer)
Phase 4: 重構評估 (cinnamon-refactor-owl) → /tech-debt-capture
```

**語言自適應**：Phase 3b 依語言派發不同代理人。

> 詳見 `.claude/rules/flows/tdd-flow.md`

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

## 專案特定設定

### 測試執行

```bash
# Flutter 全量測試（在 ui/ 目錄執行）
(cd ui && flutter test)

# Flutter 單一測試檔案
(cd ui && flutter test test/path/to/specific_test.dart)

# Go 測試
(cd server && go test ./...)
```

### 程式碼分析

```bash
# Flutter/Dart（在 ui/ 目錄執行）
(cd ui && dart analyze)

# Go
(cd server && go vet ./...)
```

---

*最後更新: 2026-03-05*
*版本: 1.2.0 - 新增資料夾結構說明、修正測試指令路徑（server/ ui/ monorepo）*
