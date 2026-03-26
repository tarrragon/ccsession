# CLAUDE.md - 專案開發規範

本文件定義**專案特定**資訊。通用框架規則由 `.claude/rules/README.md` 自動載入。

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
├── CLAUDE.md                # 本文件（專案特定設定）
└── README.md                # 專案說明
```

> 工作時需明確區分語言環境：Go 指令在 `server/` 執行，Flutter 指令在 `ui/` 執行。

### 核心原理

Claude Code 的所有對話紀錄以 JSONL 格式即時寫入 `~/.claude/` 目錄。
每個 message 產生後立即 append 到磁碟，透過 file watching 實現接近即時的監控。

> 詳細技術規格：[docs/spec.md](./docs/spec.md)

---

## 語言特定規範

| 語言 | 規範位置 |
|------|---------|
| Flutter/Dart（前端） | `.claude/references/quality-dart.md` |
| Go（後端） | `.claude/references/quality-go.md` |
| Python（Hook/Skill） | `.claude/references/quality-python.md` |

---

## 專案特定設定

### 啟動應用

```bash
# 1. 啟動 Go Backend（監聽 localhost:8765）
(cd server && go run .)

# 2. 啟動 Flutter Frontend（另開終端）
(cd ui && flutter run -d macos)    # macOS
(cd ui && flutter run -d linux)    # Linux
(cd ui && flutter run -d windows)  # Windows
(cd ui && flutter run -d chrome)   # Web
```

> Backend 必須先啟動，Frontend 會自動連線 `ws://localhost:8765/ws`。

### Smoke Test（版本發布前驗收）

```bash
./scripts/smoke-test.sh            # 完整驗收（編譯+測試+啟動）
./scripts/smoke-test.sh --quick    # 快速檢查（編譯+啟動）
./scripts/smoke-test.sh --skip-tests  # 跳過測試
```

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

*最後更新: 2026-03-27*
*版本: 2.1.0 - 新增啟動應用和 Smoke Test 章節*
