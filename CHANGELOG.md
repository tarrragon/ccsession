# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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

## [0.1.0] - 2026-03-03

### Added

- Ticket CLI：handoff/resume 交接功能
- Ticket CLI：set-blocked-by/set-related-to 關係管理命令
- 專案規格文件、Use Case 定義
- 框架行為約束和 Hook 安全策略
