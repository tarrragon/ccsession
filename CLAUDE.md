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

以下規範由 `.claude/rules/` 自動載入，適用於所有語言。核心入口：決策樹（`core/decision-tree.md`）、品質標準（`core/implementation-quality.md`）、TDD 流程（`flows/tdd-flow.md`）、Ticket 生命週期（`flows/ticket-lifecycle.md`）、事件回應（`flows/incident-response.md`）。

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

**強制規則**：所有 Ticket 必須透過 `/ticket create` 建立（禁止直接寫 .md）。

Ticket 建立後需通過 acceptance-auditor + system-analyst 並行審核（`creation_accepted: true`），方可認領執行。

錯誤發生時強制執行 `/pre-fix-eval` 並派發 incident-responder，禁止直接修復程式碼。

> 完整生命週期、驗收流程、錯誤處理：`.claude/rules/flows/ticket-lifecycle.md`
> 事件回應流程：`.claude/rules/flows/incident-response.md`

---

## 品質基線

專案品質標準（測試通過率 100%、Phase 4 不可跳過、設計問題發現即修正、Hook 失敗必須可見）詳見 `.claude/rules/core/quality-baseline.md`。

**Hook 失敗可見性**：Hook 異常時必須同時寫入 stderr 和日誌檔，禁止靜默失敗（僅記錄到檔案而不通知用戶）。

**Phase 4 豁免**：小型修改（<= 2 檔案）、DOC 類型、任務範圍單純時可簡化為單步驟（Phase 4b），詳見 `.claude/rules/flows/tdd-flow.md`。

### Skip-gate 防護機制

| 層級 | 說明 |
|------|------|
| Level 1 | 錯誤發生時強制派發 incident-responder，禁止直接修復 |
| Level 2 | 開發命令執行前驗證 Ticket 存在性（Hook 自動檢查） |
| Level 3 | PM 只能編輯允許列表中的檔案路徑 |

> 詳細規則、違規判定、Hook 實作：`.claude/rules/forbidden/skip-gate.md`

---

## TDD 流程摘要

新功能或架構變更時強制執行完整 TDD（Phase 0 SA 審查 → Phase 1 設計 → Phase 2 測試設計 → Phase 3a/3b 實作 → Phase 4a/4b/4c 重構）。Phase 3b 依語言派發不同代理人。

小型修改、遷移任務等可豁免部分 Phase，詳見 `.claude/rules/flows/tdd-flow.md`。

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

*最後更新: 2026-03-11*
*版本: 1.3.0 - 去重精簡：重複段落改為摘要+連結，保留高風險規則補償（W35-001.5）*
