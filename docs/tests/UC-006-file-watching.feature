Feature: UC-006 JSONL 檔案監控

  Background:
    Given Go Backend 已啟動
    And ~/.claude/projects/ 目錄結構已準備
    And fsnotify 可正常運作

  Scenario: 啟動時掃描所有既有 JSONL 檔案
    Given ~/.claude/projects/ 目錄下已存在多個 JSONL 檔案
    When Backend 啟動
    Then Backend 掃描 ~/.claude/projects/ 所有子目錄
    And 為每個 .jsonl 檔案建立 watcher
    And 記錄每個檔案的初始大小作為 offset
    And 對既存檔案執行初始載入（讀取最後 N 行，預設 1000 行）

  Scenario: 檔案 append 新內容的偵測
    Given Backend 正在監控某個 JSONL 檔案
    When 新的 JSON 行 append 到檔案
    Then fsnotify 發出 Write 事件（< 100ms 延遲）
    And Backend 讀取從 offset 到檔案結尾的新內容
    And 按換行符分割為獨立行
    And 將每行傳送到解析層（UC-007）
    And 更新 offset 為新的檔案大小

  Scenario: 新 Session 檔案建立
    Given Claude Code 啟動新的 agent/session
    When 新的 .jsonl 檔案在 project 目錄下建立
    Then fsnotify 發出 Create 事件
    And Backend 為新檔案建立 watcher 和 reader goroutine
    And Backend 通知 Session Registry 新 session 出現

  Scenario: 新 Project 目錄偵測與既存檔案掃描
    Given Developer 首次在某專案使用 Claude Code
    When ~/.claude/projects/ 下新增一個編碼後的 project 子目錄
    Then Backend 偵測到新子目錄
    And Backend 掃描該目錄下所有既存 .jsonl 檔案
    And 依修改時間（mtime）由舊到新排序載入
    And 為該目錄建立 watcher，開始監控後續檔案變更

  Scenario: 既存 JSONL 檔案掃描規則
    Given Project 目錄內已包含多個 JSONL 檔案
    When Backend 掃描該目錄
    Then 僅處理副檔名為 .jsonl 的檔案
    And 忽略 .json 等其他檔案（如 sessions-index.json）
    And 依 mtime 由舊到新載入
    And 同一 project 目錄的多個檔案以序列方式逐一載入（避免 I/O 暴增）

  Scenario: 多 JSONL 檔案獨立處理
    Given Project 目錄下存在多個 JSONL 檔案
    When Backend 監控它們
    Then 每個檔案對應一個獨立的 session（檔案名即 session UUID）
    And 每個檔案由獨立的 reader goroutine 負責
    And 每個檔案維護各自的讀取 offset，互不影響

  Scenario: 單 Project 目錄同時監控檔案數上限
    Given Project 目錄下存在超過 50 個 JSONL 檔案
    When Backend 初始化
    Then Backend 最多同時監控 50 個檔案（可配置預設值）
    And 超過上限時，按 mtime 保留最新的檔案進行持續監控
    And 舊檔案僅建立 session 元資料但不持續監控增量更新

  Scenario: 檔案被刪除時清理資源
    Given Backend 正在監控某個 JSONL 檔案
    When 該檔案被刪除
    Then fsnotify 發出 Remove 事件
    And Backend 移除該檔案的 watcher 和 reader goroutine
    And Backend 通知 Session Registry 該 session 已結束
    And 資源被正確釋放

  Scenario: 只讀取新 append 的行無重複
    Given Backend 已讀取 JSONL 檔案 offset=1000
    When 新增 5 行到檔案末尾
    Then Backend 讀取從 offset 1000 到檔案結尾（5 行）
    And 不重複讀取之前的 1000 行
    And offset 更新為新值

  Scenario: 支援同時監控 100+ 個檔案
    Given Backend 配置為監控大量檔案
    When 同時監控 100 個以上的 JSONL 檔案
    Then 所有檔案變更能被即時偵測
    And 資源使用（CPU、記憶體）保持在可控範圍內

  Scenario: 權限不足時優雅降級
    Given 某個 JSONL 檔案的讀取權限被拒
    When Backend 嘗試讀取該檔案
    Then 記錄警告日誌（含檔案路徑和錯誤原因）
    And Backend 跳過該檔案，不中斷其他檔案監控
    And 應用繼續運行

  Scenario: 目錄不存在時的處理
    Given ~/.claude/projects/ 目錄不存在
    When Backend 啟動
    Then 記錄錯誤日誌
    And Backend 等待目錄建立或正常退出（取決於配置）

  Scenario: macOS/Linux/Windows 跨平台運作
    Given Backend 運行在不同作業系統
    When 對應平台的 fsnotify 實作執行
    Then macOS（kqueue）能正確偵測檔案變更
    And Linux（inotify）能正確偵測，注意 watcher 數量限制
    And Windows（ReadDirectoryChangesW）能正確偵測

  Scenario: 效能指標達成
    Given Backend 持續監控檔案
    When 檔案變更發生
    Then 偵測延遲 < 100ms
    And CPU 使用率（閒置時）< 1%
    And 每個 watcher 記憶體使用 < 1 MB
    And 支援同時監控 >= 100 檔案
