Feature: UC-008 Session 狀態管理

  Background:
    Given Go Backend 已啟動
    And ~/.claude/projects/ 目錄結構已準備

  Scenario: Backend 啟動時初始化 Session Registry
    Given Backend 首次啟動
    When Backend 掃描所有 project 目錄
    Then Backend 讀取每個 project 的 sessions-index.json
    And 為每個 session 建立 SessionInfo 記錄
    And 讀取 history.jsonl 建立 session → project 映射
    And 根據最後事件時間設定初始狀態

  Scenario: 新事件觸發狀態更新
    Given Backend 正在監控某個 session
    When 接收新的 SessionEvent
    Then Backend 更新該 session 的 lastEventAt 時間戳
    And Backend 更新 eventCount（成功解析的事件數）
    And Backend 重新評估狀態

  Scenario: Active 狀態判定
    Given Session 最近有新事件
    When Backend 狀態評估
    Then 該 session 狀態為 active

  Scenario: Idle 狀態判定
    Given Session 在 2-30 分鐘內無新事件
    When Backend 狀態評估
    Then 該 session 狀態為 idle
    And Backend 推送 session_status_change 訊息（active → idle）給 WebSocket 層

  Scenario: Completed 狀態判定
    Given Session 超過 30 分鐘無新事件
    When Backend 狀態評估
    Then 該 session 狀態為 completed
    And Backend 推送 session_status_change 訊息（idle → completed）給 WebSocket 層

  Scenario: 新事件讓 completed session 回到 active
    Given 某 session 處於 completed 狀態
    When 該 session 出現新事件
    Then Backend 更新 lastEventAt
    And Backend 重新評估狀態為 active
    And Backend 推送 session_status_change 訊息（completed → active）

  Scenario: 定期狀態掃描
    Given Backend 正在運行
    When 每 30 秒執行全量狀態檢查
    Then Backend 檢查所有 session 的 lastEventAt
    And 將超過 idle_timeout（2 分鐘）的 active session 降級為 idle
    And 將超過 completed_timeout（30 分鐘）的 idle session 降級為 completed

  Scenario: sessions-index.json 缺失時的備用來源
    Given 某 project 目錄沒有 sessions-index.json
    When Backend 初始化該 session
    Then Backend 從 JSONL 檔名推斷 session ID
    And Backend 讀取 session JSONL 檔案中第一個 type='user' 的 message
    And 截取前 100 字元作為 summary
    And Git branch 標記為「(unknown)」

  Scenario: Session Metadata 優先級 - Summary
    Given 某 session 存在 sessions-index.json
    When sessions-index.json 包含 summary 欄位
    Then Backend 優先使用該 summary
    When sessions-index.json 不包含 summary
    Then Backend 改用第一個 user prompt（前 100 字元）
    When 檔案為空或不存在
    Then Backend 顯示「(unnamed session)」

  Scenario: Session Metadata 優先級 - Git Branch
    Given Backend 初始化 session 元資料
    When sessions-index.json 包含 gitBranch 欄位
    Then Backend 使用該值
    When sessions-index.json 不包含該欄位
    Then Backend 顯示「(unknown)」（而非空值）

  Scenario: Session Metadata 優先級 - Project Path
    Given Backend 需要反推 project path
    When 目錄編碼有效
    Then Backend 從編碼反推原始 path
    When 編碼破損或無效
    Then Backend 嘗試從 sessions-index.json 補救

  Scenario: Session Metadata 優先級 - Last Active 時間
    Given Backend 初始化 session
    When JSONL 檔案中有最後事件的 timestamp
    Then Backend 使用該 timestamp（最精確）
    When JSONL 檔案為空
    Then Backend 使用檔案修改時間（mtime）

  Scenario: Session EventCount 動態計算
    Given Backend 掃描某個 session 的 JSONL 檔案
    When 計算 eventCount
    Then Backend 計算**成功解析為合法 JSON 物件的事件行數**
    And 空行、格式錯誤行不計入
    And 此值動態計算，不依賴 sessions-index.json（可能過時）

  Scenario: 新 Session 自動註冊
    Given Backend 監控著某個 project 目錄
    When UC-006 偵測到新 JSONL 檔案建立
    Then Backend 從檔名提取 session UUID
    And 從所在目錄反推 project path
    And 建立新的 SessionInfo（初始狀態為 active）
    And Backend 通知 WebSocket 層推送列表更新

  Scenario: Concurrent access - 並發安全
    Given Backend 正在處理多個 goroutine 的事件
    When 多個 goroutine 同時存取 Session Registry
    Then Registry 使用 sync.RWMutex 保證並發安全
    And 讀操作可並行，寫操作互斥

  Scenario: Session Registry 狀態機
    Given Session 初始化為 active
    When 2 分鐘無新事件
    Then 轉為 idle
    When 30 分鐘無新事件
    Then 轉為 completed
    When 新事件到達
    Then 轉回 active

  Scenario: 狀態變更通知 WebSocket 層
    Given Backend 偵測到 session 狀態變更
    When 狀態由 active 轉為 idle
    Then Backend 推送 session_status_change 訊息給 WebSocket 層
    And WebSocket 層廣播此訊息給所有已連線的 Client

  Scenario: SessionInfo 資料結構完整性
    Given Backend 維護某個 SessionInfo
    Then 該記錄包含：
      | 欄位 | 說明 |
      | ID | Session UUID |
      | ProjectPath | 專案完整路徑 |
      | Summary | Session 摘要 |
      | GitBranch | Git 分支 |
      | Status | active / idle / completed |
      | LastEventAt | 最後事件時間戳 |
      | EventCount | 成功解析事件數 |
    And 所有欄位都有有效值（無 nil，無空字串）
