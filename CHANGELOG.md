# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.2.1] - 2026-03-29

**✅ UC-XX 功能名稱 - TDD 四階段完成**

### Added
- 新增功能項目

### Changed
- 變更項目

### Fixed
- 修復項目

---

## [0.1.2] - 2026-03-25

### Added

- Phase Contract YAML schema 和四層驗證 Hook（存在性 -> 格式 -> 結構 -> 內容）
- Ticket frontmatter protocol_version 欄位，支援 schema 演進和向後相容遷移
- Agent Registry YAML（能力資料層），支援三種衝突檢查和派發驗證
- 檔案所有權隔離自動檢查 Hook（where.files 衝突偵測）
- ticket create 建立前 SRP 自動偵測和重複偵測查詢機制
- 錯誤學習雙通道記錄保護機制（error-pattern + memory 同步）
- 派發計數驗證 Hook（PC-020 防護）
- 代理人可編輯路徑對照表和 subagent bypass 檢查清單
- normalize_path() 路徑遍歷 stack 防護策略

### Changed

- ticket create execute() 重構為三段式結構（resolve -> parse -> persist）
- Phase Contract Validator 重構消除 DRY 違反，統一 source of truth
- file-ownership-guard-hook 品質改善（6 項 MEDIUM 修正，函式 <= 30 行）
- skip-gate Level 3 明確區分主線程和 subagent 適用規則
- parallel-dispatch.md 新增派發前路徑權限確認和派發後計數自檢
- get_uncommitted_files() 高階 API 隱藏 porcelain 格式

### Fixed

- handoff-auto-resume-stop-hook 在背景代理人執行中時誤觸發
- branch-verify-hook 誤攔 auto-memory 路徑
- main-thread-edit-restriction-hook subagent 誤攔截 + plans 路徑白名單
- phase_complete.py 引用不存在的 result.infos 欄位（AttributeError）
- detect_srp_violations 和 detect_vague_acceptance 回傳語義相反
- Phase Contract Validator legacy 判定 bug（mtime 比較和降級策略）
- 500+ 現有 Ticket 事後驗證發現的 blockedBy 引用不存在問題

## [0.2.0] - 2026-03-04

### Added

- `project-init onboard` 子指令：統一的新專案框架定制引導入口
  - 專案語言自動偵測（Flutter/Go/Node.js/Python）
  - Hook 語言分類讀取（hook-language-classification.yaml）
  - CLAUDE.md、語言模板、settings.local.json 存在性檢查
  - 完整待辦清單輸出
- `.claude/config/hook-language-classification.yaml`：Hook 語言屬性定義
- `.claude/templates/settings-local-template.json`：settings.local.json 骨架模板

### Changed

- `.claude/README.md`：移除專案特定引用，泛化為通用框架文件
- `.claude/project-templates/FLUTTER.md`：改用 `{app_name}` 佔位符
- `.claude/README-subtree-sync.md`：定位為同步機制技術文件
- `.claude/commands/sync-pull.md`：新增 post-pull 引導步驟

### Fixed

- `paths.py` `get_project_root()`：搜尋標記由單一 `pubspec.yaml` 改為依序搜尋 `CLAUDE.md` -> `go.mod` -> `pubspec.yaml`，修正在 Go/混合型專案中靜默回傳錯誤目錄的問題（PC-002）
- `version.py`：新增 `current_version` 頂層欄位格式支援，修正非標準 todolist.yaml 格式下版本號偵測污染（PC-001）；fallback 時輸出 WARNING log
- `sync-claude-push.sh`：rsync 新增排除 `__pycache__`、`*.pyc`、`.pytest_cache`
- `docs/error-patterns/`：建立錯誤模式知識庫，記錄 PC-001、PC-002

## [0.1.0] - 2026-03-03

### Added

- Ticket CLI：handoff/resume 交接功能
- Ticket CLI：set-blocked-by/set-related-to 關係管理命令
- 專案規格文件、Use Case 定義
- 框架行為約束和 Hook 安全策略
