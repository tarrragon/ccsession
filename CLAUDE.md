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

## 專案特定設定

### 測試執行

```bash
# Flutter 全量測試（使用摘要腳本，避免大輸出耗盡 context）
./.claude/hooks/test-summary.sh

# Flutter 單一測試檔案
flutter test test/path/to/specific_test.dart

# Go 測試（待建立後端後啟用）
# cd backend && go test ./...
```

### 程式碼分析

```bash
# Flutter/Dart
dart analyze
flutter analyze

# Go（待建立後端後啟用）
# cd backend && go vet ./...
```

---

*最後更新: 2026-03-03*
