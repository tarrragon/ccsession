Feature: UC-003 即時事件串流

  Background:
    Given Go Backend 已啟動
    And Flutter Frontend 已連線到 Backend
    And Developer 正在檢視某個 active session（UC-002）
    And 該 session 對應的 Claude Code agent 正在運行

  Scenario: 新事件從寫入到 UI 顯示延遲目標
    Given Agent 產生新的對話事件
    When Claude Code 事件以 JSON 行 append 到 JSONL 檔案
    Then Go Backend 的 file watcher 偵測到檔案變更（UC-006）
    And Backend 讀取新 append 的行，解析為 SessionEvent（UC-007）
    And Backend 透過 WebSocket 推送 session_event 訊息給已訂閱的 Frontend
    And Frontend 接收事件，立即在對話檢視底部渲染
    And 端到端延遲目標 < 500ms（上限 < 1 秒）

  Scenario: 連續快速事件不遺漏
    Given Agent 快速連續產生多個事件
    When 多個事件快速 append 到 JSONL
    Then Backend 逐一推送 session_event 訊息
    And Frontend 依序渲染所有事件，無遺漏
    And 吞吐量達到 >= 100 events/sec

  Scenario: 事件短時間內大量到達（Burst 情況）
    Given 某個 Agent 在短時間內產生大量事件（如連續 tool calls）
    When 多個 SessionEvent 短時間內推送到 Frontend
    Then Frontend 正常處理，逐一渲染每個事件
    And 不因事件堆積而丟棄或延遲事件

  Scenario: 不完整 JSON 行不導致錯誤
    Given JSONL 檔案寫入中途被讀取（行未完整）
    When file watcher 觸發，Backend 讀取不完整行
    Then JSON parse 失敗
    And Backend 忽略該不完整行，不拋出異常
    And Backend 下次檔案變更時重試，後續行正常處理

  Scenario: 未訂閱的 session 事件不推送
    Given Frontend 未訂閱某個 session
    When 該 session 有新事件產生
    Then Backend 不推送該事件給此 Frontend
    And 事件仍由 Backend 處理和儲存
    When Frontend 之後訂閱該 session
    Then Frontend 可透過 get_session_history 取得完整歷史

  Scenario: 長時間運行無記憶體洩漏
    Given Backend 運行 1 小時以上，持續接收新事件
    When 定期檢查 Backend 記憶體使用
    Then 記憶體使用穩定，無持續上升趨勢
    And 單一 session 記憶體使用 < 10 MB

  Scenario: 効能預算分配達成
    Given 新事件產生
    Then File Watcher 層 <= 100ms
    And JSONL Parser 層 <= 50ms
    And Session Manager 層 <= 20ms
    And WebSocket 推送層 <= 30ms
    And Flutter 事件處理 + 渲染 <= 200ms
    And 合計端到端延遲 <= 400ms（上限 500ms 含 buffer）

  Scenario: 觸發自動捲動邏輯
    Given Frontend 正在底部檢視對話
    When 新事件到達
    Then Frontend 自動捲動到最新事件
    And Scrolling 動畫流暢（不卡頓）

  Scenario: 多個 Client 訂閱同一 session
    Given 多個 Flutter 實例同時連線
    And 多個 Client 都訂閱了同一個 session
    When 該 session 有新事件
    Then Backend 廣播 session_event 訊息給所有已訂閱的 Client
    And 所有 Client 近乎同時收到該事件（廣播延遲 < 10ms）

  Scenario: 廣播失敗不影響其他 Client
    Given 3 個 Client 訂閱同一 session
    When 某個 Client 的發送佇列滿
    Then Backend 丟棄該 Client 的最舊訊息
    And 事件仍推送給其他 Client
    And 不中斷其他 Client 的接收

  Scenario: 新事件觸發 session 狀態轉換
    Given 某個 session 狀態為 idle 或 completed
    When 該 session 出現新事件
    Then Backend 更新 lastEventAt 時間
    And Backend 重新評估狀態，轉為 active
    And Backend 推送 session_status_change 訊息
    And Frontend 更新 session 列表狀態（參考 UC-001）
