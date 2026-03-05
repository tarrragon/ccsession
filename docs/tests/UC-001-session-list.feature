Feature: UC-001 Session 列表瀏覽

  Background:
    Given Go Backend 已啟動
    And Flutter Frontend 已啟動
    And WebSocket 連線正常
    And ~/.claude/projects/ 目錄結構已準備

  Scenario: 顯示所有按狀態分組的 sessions
    Given 存在 3 個 active session：session-A（30秒前）、session-B（45秒前）
    And 存在 1 個 idle session：session-C（12分鐘前）
    And 存在 2 個 completed session：session-D、session-E
    When Frontend 連線到 Backend
    Then Frontend 在 3 秒內接收 session_list 訊息
    And Active 群組顯示 2 個 session
    And Idle 群組顯示 1 個 session
    And Completed 群組顯示 2 個 session
    And 每個 session 項目顯示：摘要文字、專案名稱、Git branch、最後活動時間、狀態指示燈

  Scenario: 新 Session 動態加入
    Given 目前列表有 2 個 active session
    When 新的 Claude Code session 開始產生事件
    And Backend 偵測到新 JSONL 檔案
    Then Backend 推送 session_status_change 訊息
    And Frontend 在 Active 群組頂部以動畫（fade-in + slide-down, 300ms）加入新 session
    And 列表即時更新，用戶可看到新 session

  Scenario: Session 狀態降級（active → idle）
    Given 某 session 處於 active 狀態
    When 該 session 超過 2 分鐘無新事件
    Then Backend 定期狀態掃描檢測到超時
    And Backend 推送 session_status_change 訊息（active → idle）
    And Frontend 將 session 從 Active 群組移除
    And Frontend 以動畫（slide + fade, 300ms）插入到 Idle 群組
    And 視覺過渡保持流暢，用戶能追蹤 session 位置變化

  Scenario: Session 狀態降級（idle → completed）
    Given 某 session 處於 idle 狀態（已超過 2 分鐘無事件）
    When 該 session 超過 30 分鐘無新事件
    Then Backend 推送 session_status_change 訊息（idle → completed）
    And Frontend 將 session 從 Idle 群組移除
    And Frontend 以動畫（slide + fade, 300ms）插入到 Completed 群組

  Scenario: Session 狀態回升（completed → active）
    Given 某 session 處於 completed 狀態
    When 該 session 出現新事件（使用者重新開啟對話）
    Then Backend 推送 session_status_change 訊息（completed → active）
    And Frontend 將 session 從 Completed 群組移除
    And Frontend 以動畫（slide + fade 過渡 + 短暫高亮）加入到 Active 群組頂部
    And 高亮持續 1 秒，幫助使用者注意到狀態變化

  Scenario: Session 狀態回升（idle → active）
    Given 某 session 處於 idle 狀態
    When 該 session 出現新事件
    Then Backend 推送 session_status_change 訊息（idle → active）
    And Frontend 將 session 從 Idle 群組移除
    And Frontend 以動畫加入到 Active 群組頂部
    And 短暫高亮提示用戶該 session 已回到活躍狀態

  Scenario: 無 Session 時顯示空狀態
    Given Backend 已啟動但無任何 session
    When Frontend 連線到 Backend
    Then Backend 推送空的 session_list
    And Frontend 顯示友善的空狀態提示：「目前沒有 Claude Code session」

  Scenario: Session 摘要顯示邏輯
    Given 存在一個 session
    When 該 session 的 sessions-index.json 包含 summary 欄位
    Then Frontend 優先顯示 sessions-index.json 的 summary
    When 該 session 的 sessions-index.json 不包含 summary 欄位
    Then Frontend 讀取該 session JSONL 檔案中第一個 user prompt
    And 截取前 100 字元作為摘要顯示
    When 該 session JSONL 檔案為空或不存在
    Then Frontend 顯示預設值：「(unnamed session)」

  Scenario: WebSocket 連線失敗時的優雅降級
    Given Go Backend 未啟動
    When Flutter Frontend 嘗試連線
    Then Frontend 顯示連線狀態為「已斷線」
    And 啟動重連機制（指數退避：1s, 2s, 4s, 8s, 16s, 最大 30s）
    And Frontend 在重連前顯示最後已知狀態或空狀態提示

  Scenario: 動畫不阻擋使用者互動
    Given Frontend 正在執行 session 狀態變更動畫
    When 用戶點擊其他 session
    Then 用戶點擊立即響應，不被動畫阻擋
    And 動畫繼續執行但不影響新點擊的效果

  Scenario: 批量狀態變更時合併動畫
    Given 多個 session 在短時間內同時狀態變更
    When Backend 短時間內推送多個 session_status_change 訊息
    Then Frontend 合併動畫效果
    And 避免列表頻繁跳動造成視覺干擾
