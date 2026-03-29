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

### 重要：本專案與 Claude Code CLI 的區分

> **本專案是一個獨立的 GUI 應用程式**，不是 Claude Code CLI 本身。
>
> - **Claude Code CLI**：Anthropic 官方的命令列工具，用戶在終端中與 Claude 互動
> - **本專案（ccsession）**：我們自己開發的**獨立桌面/行動應用**，用於即時監控 Claude Code 的所有 session
>
> 當用戶提到 UI 問題、畫面顯示異常、排版錯誤時，指的是**本專案的 Flutter 前端 UI**，不是 Claude Code CLI 的終端顯示。本專案的 UI 程式碼在 `ui/` 目錄下，我們有完全的控制權。

### 架構概述

- **Go Backend**：監控本地 JSONL 檔案變更、解析對話內容、提供 WebSocket server
- **Flutter Frontend**：本專案自己的 GUI，即時呈現 Claude Code session 的對話內容，支援 macOS / Windows / Linux / 行動裝置

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
> Riverpod `.g.dart` 已納入 git，無需額外執行 build_runner。僅在修改 `@riverpod` 標注的類別時需重跑：`(cd ui && dart run build_runner build --delete-conflicting-outputs)`

### 記憶體診斷（pprof）

```bash
# 啟用 pprof（開發環境）
CCSESSION_PPROF=1 (cd server && go run .)

# 查看記憶體 profile
go tool pprof http://localhost:8765/debug/pprof/heap

# 查看 goroutine
go tool pprof http://localhost:8765/debug/pprof/goroutine
```

> pprof 預設關閉，僅在設定 `CCSESSION_PPROF=1` 環境變數時啟用。生產環境請勿啟用。

### Zellij 開發佈局

在 zellij 環境下開發時，使用以下三欄佈局：

```
┌──────────────┬──────────────┐
│              │   後端 (上)   │
│   claude     ├──────────────┤
│   (左 50%)   │   前端 (下)   │
└──────────────┴──────────────┘
```

```bash
# 從 claude pane 建立佈局
zellij action new-pane --direction right --name "後端"
zellij action new-pane --direction down --name "前端"
zellij action focus-previous-pane && zellij action focus-previous-pane

# 啟動後端（右上）
zellij action focus-next-pane && \
zellij action write-chars "cd /Users/mac-eric/project/ccsession/server && go run ." && \
zellij action write 10

# 啟動前端（右下）
zellij action focus-next-pane && \
zellij action write-chars "cd /Users/mac-eric/project/ccsession/ui && flutter run -d macos" && \
zellij action write 10

# 切回 claude pane
zellij action focus-previous-pane && zellij action focus-previous-pane
```

> Pane 順序（focus-next-pane）：claude → 後端 → 前端 → claude

### 重啟伺服器注意事項

重啟 Go Backend 時，必須確認舊 process 已完全停止，否則新 process 會因 port 被佔用而靜默失敗：

```bash
# 1. 先在後端 pane 送 Ctrl+C 停止
zellij action focus-next-pane && zellij action write 3

# 2. 確認 port 空了（應無輸出）
lsof -i :8765

# 3. 若仍有殘留 process，強制 kill
kill -9 $(lsof -ti :8765) 2>/dev/null

# 4. 確認後再啟動
zellij action focus-next-pane && \
zellij action write-chars "cd /Users/mac-eric/project/ccsession/server && go run ." && \
zellij action write 10

# 5. 等待編譯完成後，讀取後端 log 確認啟動成功
#    必須看到 "scanning existing JSONL files" 和 "ccsession-monitor starting"
sleep 10 && zellij action focus-next-pane && \
zellij action dump-screen /tmp/zellij-backend-check.txt && \
zellij action focus-previous-pane
```

> 重點：不要假設伺服器能正常啟動。每次重啟後必須讀取 log 確認 `scanning existing JSONL files` 出現，才能進行後續驗證。

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
*版本: 2.2.0 - 新增 Zellij 開發佈局章節*
