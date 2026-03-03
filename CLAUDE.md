# CLAUDE.md - 專案開發規範

本文件是 Claude Code 讀取專案資訊的入口，定義專案基本資訊和開發規範。

---

## 專案資訊

| 項目 | 說明 |
|------|------|
| **專案類型** | Flutter 移動應用程式 |
| **開發語言** | Dart |
| **框架版本** | Flutter 3.41 |
| **實作代理人** | parsley-flutter-developer（Phase 3b 程式碼實作） |
| **語言特定規範** | [FLUTTER.md](./.claude/project-templates/FLUTTER.md) |

---

## 開發規範

### 語言特定規範

Flutter/Dart 相關的開發工具鏈、測試指令、程式碼品質標準、專案結構等，
請參考 [FLUTTER.md](./.claude/project-templates/FLUTTER.md)。

### 通用規範

以下規範由 `.claude/rules/` 自動載入，適用於所有語言：

| 規範 | 位置 |
|------|------|
| 主線程決策樹 | `.claude/rules/core/decision-tree.md` |
| 實作品質標準 | `.claude/rules/core/implementation-quality.md` |
| TDD 流程 | `.claude/rules/flows/tdd-flow.md` |
| Ticket 生命週期 | `.claude/rules/flows/ticket-lifecycle.md` |
| 事件回應流程 | `.claude/rules/flows/incident-response.md` |

### 實作代理人說明

本專案的 Phase 3b 實作由 **parsley-flutter-developer** 負責：

- 接收 Phase 3a（pepper-test-implementer）的實作策略
- 將策略轉換為 Flutter/Dart 程式碼
- 遵循 FLUTTER.md 的語言特定規範
- 執行測試確保 100% 通過率

其餘 TDD 階段代理人（Phase 1/2/3a/4）為語言無關，跨專案通用。

---

## 專案特定設定

### 測試執行

```bash
# 全量測試（使用摘要腳本，避免大輸出耗盡 context）
./.claude/hooks/test-summary.sh

# 單一測試檔案
flutter test test/path/to/specific_test.dart
```

### 程式碼分析

```bash
dart analyze
flutter analyze
```

---

*最後更新: 2026-03-03*
*框架版本: Flutter 3.41*
