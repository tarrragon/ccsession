# UC-006: JSONL 檔案監控

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-006 |
| **名稱** | JSONL 檔案監控 |
| **Actor** | System (Go Backend) |
| **優先級** | P0 |
| **元件** | Go Backend |
| **依賴** | 無（最底層） |

---

## 目標

Go Backend 啟動後，持續監控 `~/.claude/projects/` 目錄下所有 `.jsonl` 檔案的變更，
偵測到新內容 append 時通知解析層處理。

---

## 前置條件

1. `~/.claude/projects/` 目錄存在
2. 目錄具有讀取權限
3. `fsnotify` 可正常運作於目標作業系統

---

## 主要流程（Happy Path）

1. Backend 啟動時掃描 `~/.claude/projects/` 所有子目錄
2. 為每個 project 目錄下的 `.jsonl` 檔案建立 watcher
3. 記錄每個檔案的初始大小作為 offset
4. 等待 `fsnotify` 事件
5. 收到 Write 事件時：
   - 讀取從 offset 到檔案結尾的新內容
   - 按換行符分割為獨立行
   - 將每行傳送到解析層（UC-007）
   - 更新 offset 為新的檔案大小

---

## 替代流程

### A1: 新 Session 檔案建立

1. Claude Code 啟動新的 agent/session
2. 新的 `.jsonl` 檔案在某個 project 目錄下建立
3. fsnotify 發出 Create 事件
4. Backend 為新檔案建立 watcher 和 reader goroutine
5. 通知 Session Registry（UC-008）新 session 出現

### A2: 新 Project 目錄建立

1. Developer 首次在某專案使用 Claude Code
2. `~/.claude/projects/` 下新增一個編碼後的 project 子目錄
3. Backend 偵測到新子目錄，開始監控其下的檔案

### A3: 既有檔案的初始載入

1. Backend 啟動時發現已存在的 JSONL 檔案
2. 讀取檔案的最後 N 行（可配置，預設 1000 行）
3. 傳送到解析層建立初始狀態
4. 將 offset 設為檔案結尾，後續只讀取新 append 的內容

---

## 例外流程

### E1: 檔案被刪除

1. fsnotify 發出 Remove 事件
2. Backend 移除該檔案的 watcher 和 reader
3. 通知 Session Registry 該 session 已結束

### E2: 權限不足

1. 嘗試讀取檔案時權限被拒
2. 記錄警告日誌
3. 跳過該檔案，不中斷其他檔案的監控

### E3: 目錄不存在

1. `~/.claude/` 或 `~/.claude/projects/` 不存在
2. 記錄錯誤日誌
3. 等待目錄建立（定期檢查）或退出

---

## 效能需求

| 指標 | 目標值 |
|------|--------|
| 檔案變更偵測延遲 | < 100ms |
| 支援同時監控檔案數 | >= 100 |
| CPU 使用率（閒置時） | < 1% |
| 記憶體使用（每個 watcher） | < 1 MB |

---

## 跨平台考量

| 平台 | fsnotify 行為 | 注意事項 |
|------|-------------|---------|
| macOS | kqueue | 正常運作 |
| Linux | inotify | 有 watcher 數量限制（/proc/sys/fs/inotify/max_user_watches） |
| Windows | ReadDirectoryChangesW | 正常運作 |

---

## 驗收條件

- [ ] 啟動時正確掃描所有既有 JSONL 檔案
- [ ] 檔案 append 新內容時 100ms 內偵測到
- [ ] 新建 JSONL 檔案時自動開始監控
- [ ] 檔案刪除時正確清理資源
- [ ] 只讀取新 append 的行，不重複處理
- [ ] 支援同時監控 100+ 個檔案
- [ ] macOS / Linux / Windows 皆可運作

---

*最後更新: 2026-03-03*
